import Foundation
import Observation

@Observable
@MainActor
public final class IngestionViewModel {
    public var urlInput: String = ""
    public var selectedFolderId: String? = nil
    public var isAnalyzing: Bool = false
    public var analyzedReel: Reel? = nil
    public var errorMessage: String? = nil

    private let repository: VaultRepository

    public init(repository: VaultRepository = .shared) {
        self.repository = repository
    }

    public func analyze() async -> Bool {
        let trimmed = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter or paste a valid link from Instagram, TikTok, YouTube or X."
            return false
        }

        isAnalyzing = true
        errorMessage = nil
        analyzedReel = nil

        do {
            let result = try await repository.analyzeReel(url: trimmed, folderId: selectedFolderId)
            self.analyzedReel = result
            self.isAnalyzing = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isAnalyzing = false
            return false
        }
    }

    public func reset() {
        urlInput = ""
        analyzedReel = nil
        errorMessage = nil
        isAnalyzing = false
    }
}
