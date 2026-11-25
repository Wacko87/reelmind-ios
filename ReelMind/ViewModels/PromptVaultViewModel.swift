import Foundation
import Observation
import UIKit

@Observable
@MainActor
public final class PromptVaultViewModel {
    // Prompt Studio
    public var promptInput: String = ""
    public var targetModel: String = "Flux 1.1 Pro"
    public var isOptimizing: Bool = false
    public var variations: [PromptVariation] = []

    // Ask Vault
    public var questionInput: String = ""
    public var isAsking: Bool = false
    public var vaultAnswer: String? = nil
    public var citations: [VaultCitation] = []
    public var organizations: [Organization] = []
    public var selectedOrganization: Organization? = nil

    public var errorMessage: String? = nil
    public var copyAlert: Bool = false

    private let repository: VaultRepository

    public init(repository: VaultRepository = .shared) {
        self.repository = repository
    }

    public func loadOrganizations() async {
        if let orgs = try? await repository.fetchOrganizations() {
            self.organizations = orgs
        }
    }

    public func loadSamplePrompt() {
        self.promptInput = "Cinematic aerial shot of an ancient neon pagoda shrouded in misty mountains, cyberpunk fantasy, 8k --ar 16:9"
        self.targetModel = "Flux 1.1 Pro"
    }

    public func loadSampleQuestion() {
        self.questionInput = Locale.current.language.languageCode?.identifier == "es"
            ? "¿Qué herramientas sirven para crear avatares realistas con clonación de voz?"
            : "Which tools create realistic cinematic avatars with voice cloning?"
    }

    public func optimize() async {
        let trimmed = promptInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard trimmed.count <= 4000 else {
            errorMessage = "Prompt is too long (maximum 4000 characters)."
            return
        }

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
        guard trimmed.count <= 1000 else {
            errorMessage = "Question is too long (maximum 1000 characters)."
            return
        }

        isAsking = true
        errorMessage = nil
        do {
            let (answer, citations) = try await repository.askVault(question: trimmed, orgId: selectedOrganization?.id)
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
