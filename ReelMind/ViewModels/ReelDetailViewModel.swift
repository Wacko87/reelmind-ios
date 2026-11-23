import Foundation
import Observation
import UIKit

@Observable
@MainActor
public final class ReelDetailViewModel {
    public var reel: Reel
    public var userNotes: String
    public var isSaving: Bool = false
    public var errorMessage: String? = nil
    public var showCopiedAlert: Bool = false

    private let apiClient: APIClient

    public init(reel: Reel, apiClient: APIClient = .shared) {
        self.reel = reel
        self.userNotes = reel.userNotes
        self.apiClient = apiClient
    }

    public func saveNotes() async {
        guard userNotes != reel.userNotes else { return }
        isSaving = true
        errorMessage = nil
        let update = ReelUpdateRequest(userNotes: userNotes)
        do {
            let updated = try await apiClient.updateReel(id: reel.id, update: update)
            self.reel = updated
        } catch {
            self.errorMessage = "Could not save notes: \(error.localizedDescription)"
        }
        isSaving = false
    }

    public func updateStatus(to newStatus: String) async {
        isSaving = true
        errorMessage = nil
        let update = ReelUpdateRequest(status: newStatus)
        do {
            let updated = try await apiClient.updateReel(id: reel.id, update: update)
            self.reel = updated
        } catch {
            self.errorMessage = "Could not update status: \(error.localizedDescription)"
        }
        isSaving = false
    }

    public func copyToClipboard(text: String) {
        UIPasteboard.general.string = text
        showCopiedAlert = true
    }
}
