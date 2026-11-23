import Foundation

public struct VaultCitation: Codable, Identifiable, Sendable, Hashable {
    public var id: String { reelId }
    public let reelId: String
    public let title: String
    public let platform: String
    public let tools: [String]

    enum CodingKeys: String, CodingKey {
        case reelId = "reel_id"
        case title
        case platform
        case tools
    }

    public init(reelId: String, title: String, platform: String, tools: [String] = []) {
        self.reelId = reelId
        self.title = title
        self.platform = platform
        self.tools = tools
    }
}

public struct VaultAskRequest: Codable, Sendable {
    public let question: String

    public init(question: String) {
        self.question = question
    }
}

public struct VaultAskResponse: Codable, Sendable {
    public let answer: String
    public let citations: [VaultCitation]

    public init(answer: String, citations: [VaultCitation] = []) {
        self.answer = answer
        self.citations = citations
    }
}
