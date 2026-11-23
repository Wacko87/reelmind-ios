import Foundation
import Observation

@Observable
@MainActor
public final class ReelListViewModel {
    public var reels: [Reel] = [] {
        didSet {
            recalculateAvailableTools()
        }
    }
    public var folders: [Folder] = []
    public var selectedFolderId: String? = nil
    public var selectedTool: String? = nil
    public var searchQuery: String = ""
    public var isLoading: Bool = false
    public var errorMessage: String? = nil
    public private(set) var availableTools: [String] = []

    private let repository: VaultRepository

    public init(repository: VaultRepository = .shared) {
        self.repository = repository
    }

    private func recalculateAvailableTools() {
        var toolsSet = Set<String>()
        for reel in reels {
            for tool in reel.aiTools {
                let trimmed = tool.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    toolsSet.insert(trimmed)
                }
            }
        }
        self.availableTools = toolsSet.sorted()
    }

    public var filteredReels: [Reel] {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return reels.filter { reel in
            if let folderId = selectedFolderId, reel.folderId != folderId {
                return false
            }
            if let tool = selectedTool, !reel.aiTools.contains(where: { $0.localizedCaseInsensitiveContains(tool) }) {
                return false
            }
            if !trimmedQuery.isEmpty {
                return reel.title.localizedCaseInsensitiveContains(trimmedQuery)
                    || reel.summary.localizedCaseInsensitiveContains(trimmedQuery)
                    || reel.tags.contains { $0.localizedCaseInsensitiveContains(trimmedQuery) }
                    || reel.prompts.contains { $0.localizedCaseInsensitiveContains(trimmedQuery) }
            }
            return true
        }
    }

    public func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchedReels = repository.fetchReels(folderId: selectedFolderId)
            async let fetchedFolders = repository.fetchFolders()
            self.reels = try await fetchedReels
            self.folders = try await fetchedFolders
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    public func deleteReel(id: String) async {
        do {
            try await repository.deleteReel(id: id)
            reels.removeAll { $0.id == id }
        } catch {
            self.errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
    }

    public func toggleFavorite(for reel: Reel) async {
        let newStatus = reel.status == "favorite" ? "tested" : "favorite"
        let updateReq = ReelUpdateRequest(status: newStatus)
        do {
            let updated = try await repository.updateReel(id: reel.id, update: updateReq)
            if let index = reels.firstIndex(where: { $0.id == reel.id }) {
                reels[index] = updated
            }
        } catch {
            self.errorMessage = "Failed to update favorite status: \(error.localizedDescription)"
        }
    }
}
