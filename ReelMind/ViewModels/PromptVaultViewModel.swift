import Foundation
import Observation
import UIKit

@Observable
@MainActor
public final class PromptVaultViewModel {
    // Prompt Studio
    public var promptInput: String = ""
    public var targetModel: String = "Midjourney v6.1"
    public var isOptimizing: Bool = false
    public var variations: [PromptVariation] = []

    // Ask Vault
    public var questionInput: String = ""
    public var isAsking: Bool = false
    public var vaultAnswer: String? = nil
    public var citations: [VaultCitation] = []

    public var errorMessage: String? = nil
    public var copyAlert: Bool = false

    private let apiClient: APIClient

    public init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    public func optimize() async {
        let trimmed = promptInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isOptimizing = true
        errorMessage = nil
        let request = PromptOptimizeRequest(prompt: trimmed, mode: "variations", targetModel: targetModel)
        do {
            let response = try await apiClient.optimizePrompt(request: request)
            self.variations = response.variations
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isOptimizing = false
    }

    public func askVault() async {
        let trimmed = questionInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isAsking = true
        errorMessage = nil
        do {
            let response = try await apiClient.askVault(question: trimmed)
            self.vaultAnswer = response.answer
            self.citations = response.citations
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isAsking = false
    }

    public func copyPrompt(_ text: String) {
        UIPasteboard.general.string = text
        copyAlert = true
    }
}
