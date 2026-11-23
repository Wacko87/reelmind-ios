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

    private let apiClient: APIClient

    public init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    public func analyze() async -> Bool {
        let trimmed = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter a valid Instagram, TikTok, YouTube or X URL."
            return false
        }

        isAnalyzing = true
        errorMessage = nil
        analyzedReel = nil

        do {
            let result = try await apiClient.analyzeReel(url: trimmed, folderId: selectedFolderId)
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
