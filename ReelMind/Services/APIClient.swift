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

    public func fetchReels(folderId: String? = nil, status: String? = nil) async throws -> [Reel] {
        var queryItems: [URLQueryItem] = []
        if let folderId = folderId, !folderId.isEmpty {
            queryItems.append(URLQueryItem(name: "folder_id", value: folderId))
        }
        if let status = status, !status.isEmpty {
            queryItems.append(URLQueryItem(name: "status", value: status))
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

    public func analyzeReel(url rawUrl: String, folderId: String? = nil) async throws -> Reel {
        let endpoint = try makeURL(path: "/api/reels/analyze")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        applyHeaders(to: &request)

        let body = ReelAnalyzeRequest(url: rawUrl, folderId: folderId)
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

    public func fetchFolders() async throws -> [Folder] {
        let url = try makeURL(path: "/api/folders")
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

    public func askVault(question: String) async throws -> VaultAskResponse {
        let url = try makeURL(path: "/api/vault/ask")
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
