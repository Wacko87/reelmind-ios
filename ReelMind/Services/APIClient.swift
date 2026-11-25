import Foundation

public final class APIClient: Sendable {
    public static let shared = APIClient()

    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)
    }

    private var currentBaseURL: String {
        UserDefaults.standard.string(forKey: "reelmind_server_url") ?? ""
    }

    private var currentToken: String {
        KeychainService.shared.migrateFromUserDefaultsIfNeeded(key: "reelmind_api_token")
        return KeychainService.shared.get(key: "reelmind_api_token") ?? ""
    }

    private func makeURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        let trimmedBase = currentBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmedBase.isEmpty else {
            throw ReelMindError.serverNotConfigured
        }
        guard var components = URLComponents(string: "\(trimmedBase)\(path)") else {
            throw ReelMindError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw ReelMindError.invalidURL
        }
        return url
    }

    private func applyHeaders(to request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let token = currentToken.trimmingCharacters(in: .whitespacesAndNewlines)
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    // MARK: - Reels Endpoints

    public func fetchReels(folderId: String? = nil, status: String? = nil, orgId: String? = nil) async throws -> [Reel] {
        var queryItems: [URLQueryItem] = []
        if let folderId = folderId, !folderId.isEmpty {
            queryItems.append(URLQueryItem(name: "folder_id", value: folderId))
        }
        if let status = status, !status.isEmpty {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        if let orgId = orgId, !orgId.isEmpty {
            queryItems.append(URLQueryItem(name: "org_id", value: orgId))
        }

        let url = try makeURL(path: "/api/reels", queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(to: &request)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReelMindError.invalidResponse(statusCode: -1)
        }

        if httpResponse.statusCode == 401 {
            throw ReelMindError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw ReelMindError.invalidResponse(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Reel].self, from: data)
        } catch {
            throw ReelMindError.decodingError(message: error.localizedDescription)
        }
    }

    public func analyzeReel(url rawUrl: String, folderId: String? = nil, orgId: String? = nil) async throws -> Reel {
        let endpoint = try makeURL(path: "/api/reels/analyze")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        applyHeaders(to: &request)

        let body = ReelAnalyzeRequest(url: rawUrl, folderId: folderId, orgId: orgId)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReelMindError.invalidResponse(statusCode: -1)
        }

        if httpResponse.statusCode == 401 {
            throw ReelMindError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = errorObj["detail"] as? String {
                throw ReelMindError.serverError(message: detail)
            }
            throw ReelMindError.invalidResponse(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(Reel.self, from: data)
        } catch {
            throw ReelMindError.decodingError(message: error.localizedDescription)
        }
    }

    public func updateReel(id: String, update: ReelUpdateRequest) async throws -> Reel {
        let endpoint = try makeURL(path: "/api/reels/\(id)")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "PATCH"
        applyHeaders(to: &request)
        request.httpBody = try JSONEncoder().encode(update)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ReelMindError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        return try JSONDecoder().decode(Reel.self, from: data)
    }

    public func deleteReel(id: String) async throws {
        let endpoint = try makeURL(path: "/api/reels/\(id)")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "DELETE"
        applyHeaders(to: &request)

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ReelMindError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }
    }

    // MARK: - Folders Endpoints

    public func fetchFolders(mediaType: String? = nil, orgId: String? = nil) async throws -> [Folder] {
        var queryItems: [URLQueryItem] = []
        if let mediaType = mediaType, !mediaType.isEmpty {
            queryItems.append(URLQueryItem(name: "media_type", value: mediaType))
        }
        if let orgId = orgId, !orgId.isEmpty {
            queryItems.append(URLQueryItem(name: "org_id", value: orgId))
        }

        let url = try makeURL(path: "/api/folders", queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(to: &request)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ReelMindError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        return try JSONDecoder().decode([Folder].self, from: data)
    }

    public func createFolder(request folderReq: FolderCreateRequest) async throws -> Folder {
        let url = try makeURL(path: "/api/folders")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(to: &request)
        request.httpBody = try JSONEncoder().encode(folderReq)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ReelMindError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        return try JSONDecoder().decode(Folder.self, from: data)
    }

    // MARK: - Organizations Endpoints (GitHub-style shared workspaces)

    public func fetchOrganizations() async throws -> [Organization] {
        let url = try makeURL(path: "/api/orgs")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(to: &request)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ReelMindError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        return try JSONDecoder().decode([Organization].self, from: data)
    }

    public func createOrganization(name: String, description: String = "") async throws -> Organization {
        let url = try makeURL(path: "/api/orgs")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(to: &request)

        let payload: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "description": description.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ReelMindError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        return try JSONDecoder().decode(Organization.self, from: data)
    }

    public func fetchOrganizationDetail(orgId: String) async throws -> OrganizationDetail {
        let url = try makeURL(path: "/api/orgs/\(orgId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(to: &request)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ReelMindError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        return try JSONDecoder().decode(OrganizationDetail.self, from: data)
    }

    public func addOrganizationMember(orgId: String, username: String, role: String = "member") async throws -> OrganizationMember {
        let url = try makeURL(path: "/api/orgs/\(orgId)/members")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(to: &request)

        let payload = ["username": username.trimmingCharacters(in: .whitespacesAndNewlines), "role": role]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            if let errorObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = errorObj["detail"] as? String {
                throw ReelMindError.serverError(message: detail)
            }
            throw ReelMindError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        return try JSONDecoder().decode(OrganizationMember.self, from: data)
    }

    public func removeOrganizationMember(orgId: String, userId: String) async throws -> Bool {
        let url = try makeURL(path: "/api/orgs/\(orgId)/members/\(userId)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        applyHeaders(to: &request)

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ReelMindError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        return true
    }

    // MARK: - Prompt Studio & Ask Vault

    public func optimizePrompt(request optReq: PromptOptimizeRequest) async throws -> PromptOptimizeResponse {
        let url = try makeURL(path: "/api/prompts/optimize")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(to: &request)
        request.httpBody = try JSONEncoder().encode(optReq)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ReelMindError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        return try JSONDecoder().decode(PromptOptimizeResponse.self, from: data)
    }

    public func askVault(question: String, orgId: String? = nil) async throws -> VaultAskResponse {
        var queryItems: [URLQueryItem] = []
        if let orgId = orgId, !orgId.isEmpty {
            queryItems.append(URLQueryItem(name: "org_id", value: orgId))
        }

        let url = try makeURL(path: "/api/vault/ask", queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(to: &request)
        request.httpBody = try JSONEncoder().encode(VaultAskRequest(question: question))

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ReelMindError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        return try JSONDecoder().decode(VaultAskResponse.self, from: data)
    }

    // MARK: - Authentication & Status

    public func registerUser(username: String, pin: String) async throws -> Bool {
        let url = try makeURL(path: "/api/auth/register")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "username": username.trimmingCharacters(in: .whitespacesAndNewlines),
            "pin": pin.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReelMindError.invalidResponse(statusCode: -1)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = errorObj["detail"] as? String {
                throw ReelMindError.serverError(message: detail)
            }
            throw ReelMindError.invalidResponse(statusCode: httpResponse.statusCode)
        }

        struct LoginRes: Codable {
            let success: Bool
            let token: String?
            let message: String?
        }

        let decoded = try JSONDecoder().decode(LoginRes.self, from: data)
        if let token = decoded.token, !token.isEmpty {
            KeychainService.shared.save(key: "reelmind_api_token", value: token)
            return true
        }
        return decoded.success
    }

    public func loginWithPIN(pin: String, username: String? = nil) async throws -> Bool {
        let url = try makeURL(path: "/api/auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var payload: [String: Any] = ["pin": pin.trimmingCharacters(in: .whitespacesAndNewlines)]
        if let username = username?.trimmingCharacters(in: .whitespacesAndNewlines), !username.isEmpty {
            payload["username"] = username
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReelMindError.invalidResponse(statusCode: -1)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = errorObj["detail"] as? String {
                throw ReelMindError.serverError(message: detail)
            }
            throw ReelMindError.invalidResponse(statusCode: httpResponse.statusCode)
        }

        struct LoginRes: Codable {
            let success: Bool
            let token: String?
            let message: String?
        }

        let decoded = try JSONDecoder().decode(LoginRes.self, from: data)
        if let token = decoded.token, !token.isEmpty {
            KeychainService.shared.save(key: "reelmind_api_token", value: token)
            return true
        }
        return decoded.success
    }

    public func checkAuthStatus() async throws -> AuthStatusResponse {
        let url = try makeURL(path: "/api/auth/status")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(to: &request)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ReelMindError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        return try JSONDecoder().decode(AuthStatusResponse.self, from: data)
    }
}
