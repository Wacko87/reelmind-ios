import Foundation

public struct AppSettings: Codable, Sendable {
    public var serverURL: String
    public var apiToken: String
    public var geminiModel: String

    public init(
        serverURL: String = "https://reelmind.wacko87.es",
        apiToken: String = "",
        geminiModel: String = "gemini-2.5-flash"
    ) {
        self.serverURL = serverURL
        self.apiToken = apiToken
        self.geminiModel = geminiModel
    }
}

public struct LoginResponse: Codable, Sendable {
    public let success: Bool
    public let token: String?
    public let message: String?
}

public struct AuthStatusResponse: Codable, Sendable {
    public let authRequired: Bool
    public let isAuthenticated: Bool

    enum CodingKeys: String, CodingKey {
        case authRequired = "auth_required"
        case isAuthenticated = "is_authenticated"
    }
}

public struct VaultStats: Codable, Sendable {
    public let totalReels: Int
    public let totalFolders: Int
    public let uniqueTools: [String]

    enum CodingKeys: String, CodingKey {
        case totalReels = "total_reels"
        case totalFolders = "total_folders"
        case uniqueTools = "unique_tools"
    }

    public init(totalReels: Int = 0, totalFolders: Int = 0, uniqueTools: [String] = []) {
        self.totalReels = totalReels
        self.totalFolders = totalFolders
        self.uniqueTools = uniqueTools
    }
}
