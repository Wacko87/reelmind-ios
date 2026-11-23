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

    private let repository: VaultRepository

    public init(repository: VaultRepository = .shared) {
        self.repository = repository
    }

    public func optimize() async {
        let trimmed = promptInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isOptimizing = true
        errorMessage = nil
        do {
            let res = try await repository.optimizePrompt(prompt: trimmed, targetModel: targetModel)
            self.variations = res
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
            let (answer, citations) = try await repository.askVault(question: trimmed)
            self.vaultAnswer = answer
            self.citations = citations
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
