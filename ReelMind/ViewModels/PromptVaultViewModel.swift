import Foundation
import Observation
import UIKit

@Observable
@MainActor
public final class PromptVaultViewModel {
    // Prompt Studio
    public var promptInput: String = "Cinematic aerial shot of an ancient neon pagoda shrouded in misty mountains, cyberpunk fantasy, 8k --ar 16:9"
    public var targetModel: String = "Flux 1.1 Pro"
    public var isOptimizing: Bool = false
    public var variations: [PromptVariation] = [
        PromptVariation(
            label: "Photorealistic Hyper-Detail",
            prompt: "Ultra-high definition 8K photograph of an ancient cyber-pagoda glowing with warm amber neon lanterns atop a rain-soaked cliff, volumetric morning mist, shot on Hasselblad H6D-100c, 85mm f/1.4 lens --ar 16:9 --style raw",
            explanation: "Added photographic camera gear specifics, aperture depth-of-field, and raw styling for maximum texture realism."
        ),
        PromptVariation(
            label: "Anime Cinematic (Makoto Shinkai)",
            prompt: "Vibrant anime cinematic concept art of a towering neo-traditional pagoda amidst cherry blossom storms, glowing neon runes, radiant twilight sky with shimmering stars, CoMix Wave style --ar 16:9",
            explanation: "Shifted aesthetic toward high-contrast emotional anime art with saturated sky tones and bloom lighting."
        )
    ]

    // Ask Vault
    public var questionInput: String = "Which tool creates realistic cinematic avatars with lipsync?"
    public var isAsking: Bool = false
    public var vaultAnswer: String? = "Based on your ReelMind vault, the recommended workflow combines **Hedra Character-2** for emotion-driven facial animation with **ElevenLabs Voice Cloning** for multi-language audio, and **Flux 1.1 Pro** for generating the base 4K reference portrait."
    public var citations: [VaultCitation] = [
        VaultCitation(reelId: "1", title: "Photorealistic Lip-Sync Avatar Workflow", platform: "Instagram", tools: ["Hedra", "ElevenLabs"]),
        VaultCitation(reelId: "2", title: "Cyberpunk Cinematic Portrait", platform: "TikTok", tools: ["Flux 1.1 Pro"])
    ]

    public var errorMessage: String? = nil
    public var copyAlert: Bool = false

    private let repository: VaultRepository

    public init(repository: VaultRepository = .shared) {
        self.repository = repository
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
