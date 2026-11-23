import Foundation

public struct PromptVariation: Codable, Identifiable, Sendable, Hashable {
    public var id: String { label }
    public let label: String
    public let prompt: String
    public let explanation: String?

    public init(label: String, prompt: String, explanation: String? = nil) {
        self.label = label
        self.prompt = prompt
        self.explanation = explanation
    }
}

public struct PromptOptimizeRequest: Codable, Sendable {
    public let prompt: String
    public let mode: String
    public let targetModel: String?

    enum CodingKeys: String, CodingKey {
        case prompt
        case mode
        case targetModel = "target_model"
    }

    public init(prompt: String, mode: String = "variations", targetModel: String? = nil) {
        self.prompt = prompt
        self.mode = mode
        self.targetModel = targetModel
    }
}

public struct PromptOptimizeResponse: Codable, Sendable {
    public let originalPrompt: String
    public let mode: String
    public let targetModel: String?
    public let variations: [PromptVariation]

    enum CodingKeys: String, CodingKey {
        case originalPrompt = "original_prompt"
        case mode
        case targetModel = "target_model"
        case variations
    }
}
