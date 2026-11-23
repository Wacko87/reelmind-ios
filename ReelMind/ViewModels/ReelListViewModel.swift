import Foundation
import Observation

@Observable
@MainActor
public final class ReelListViewModel {
    public var reels: [Reel] = []
    public var folders: [Folder] = []
    public var selectedFolderId: String? = nil
    public var selectedTool: String? = nil
    public var searchQuery: String = ""
    public var isLoading: Bool = false
    public var errorMessage: String? = nil

    private let repository: VaultRepository

    public init(repository: VaultRepository = .shared) {
        self.repository = repository
    }

    public var availableTools: [String] {
        var toolsSet = Set<String>()
        for reel in reels {
            for tool in reel.aiTools {
                let trimmed = tool.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    toolsSet.insert(trimmed)
                }
            }
        }
        return Array(toolsSet).sorted()
    }

    public var filteredReels: [Reel] {
        reels.filter { reel in
            if let folderId = selectedFolderId, reel.folderId != folderId {
                return false
            }
            if let tool = selectedTool, !reel.aiTools.contains(where: { $0.localizedCaseInsensitiveContains(tool) }) {
                return false
            }
            if !searchQuery.isEmpty {
                let matchesTitle = reel.title.localizedCaseInsensitiveContains(searchQuery)
                let matchesSummary = reel.summary.localizedCaseInsensitiveContains(searchQuery)
                let matchesTags = reel.tags.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
                let matchesPrompts = reel.prompts.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
                return matchesTitle || matchesSummary || matchesTags || matchesPrompts
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
