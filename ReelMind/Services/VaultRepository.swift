import Foundation

public final class VaultRepository: Sendable {
    public static let shared = VaultRepository()

    private init() {}

    public var isServerModeEnabled: Bool {
        UserDefaults.standard.bool(forKey: "reelmind_use_server_mode")
    }

    public func fetchReels(folderId: String? = nil) async throws -> [Reel] {
        if isServerModeEnabled {
            return try await APIClient.shared.fetchReels(folderId: folderId)
        } else {
            let all = await LocalVaultService.shared.loadReels()
            if let folderId = folderId, !folderId.isEmpty {
                return all.filter { $0.folderId == folderId }
            }
            return all
        }
    }

    public func fetchFolders() async throws -> [Folder] {
        if isServerModeEnabled {
            return try await APIClient.shared.fetchFolders()
        } else {
            return await LocalVaultService.shared.loadFolders()
        }
    }

    public func analyzeReel(url: String, folderId: String? = nil) async throws -> Reel {
        if isServerModeEnabled {
            return try await APIClient.shared.analyzeReel(url: url, folderId: folderId)
        } else {
            var reel = try await GeminiService.shared.analyzeContent(urlOrText: url)
            reel.folderId = folderId
            await LocalVaultService.shared.addOrUpdateReel(reel)
            return reel
        }
    }

    public func updateReel(id: String, update: ReelUpdateRequest) async throws -> Reel {
        if isServerModeEnabled {
            return try await APIClient.shared.updateReel(id: id, update: update)
        } else {
            var existing = await LocalVaultService.shared.loadReels()
            guard let index = existing.firstIndex(where: { $0.id == id }) else {
                throw ReelMindError.serverError(message: "Reel not found in local vault.")
            }
            var reel = existing[index]
            if let status = update.status { reel.status = status }
            if let notes = update.userNotes { reel.userNotes = notes }
            if let title = update.title { reel.title = title }
            if let tags = update.tags { reel.tags = tags }
            if let folderId = update.folderId { reel.folderId = folderId }
            existing[index] = reel
            await LocalVaultService.shared.saveReels(existing)
            return reel
        }
    }

    public func deleteReel(id: String) async throws {
        if isServerModeEnabled {
            try await APIClient.shared.deleteReel(id: id)
        } else {
            await LocalVaultService.shared.deleteReel(id: id)
        }
    }

    public func optimizePrompt(prompt: String, targetModel: String) async throws -> [PromptVariation] {
        if isServerModeEnabled {
            let req = PromptOptimizeRequest(prompt: prompt, targetModel: targetModel)
            let res = try await APIClient.shared.optimizePrompt(request: req)
            return res.variations
        } else {
            return try await GeminiService.shared.optimizePrompt(prompt: prompt, targetModel: targetModel)
        }
    }

    public func askVault(question: String) async throws -> (answer: String, citations: [VaultCitation]) {
        if isServerModeEnabled {
            let res = try await APIClient.shared.askVault(question: question)
            return (res.answer, res.citations)
        } else {
            let reels = await LocalVaultService.shared.loadReels()
            var context = ""
            var citations: [VaultCitation] = []
            for reel in reels {
                context += "Reel Title: \(reel.title)\nTools: \(reel.aiTools.joined(separator: ", "))\nSummary: \(reel.summary)\nPrompts: \(reel.prompts.joined(separator: " | "))\nSteps: \(reel.keySteps.joined(separator: "; "))\n\n"
                citations.append(VaultCitation(reelId: reel.id, title: reel.title, platform: reel.platform, tools: reel.aiTools))
            }
            let answer = try await GeminiService.shared.askVault(question: question, vaultContext: context)
            return (answer, citations)
        }
    }
}
