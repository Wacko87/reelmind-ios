import Foundation

public actor LocalVaultService {
    public static let shared = LocalVaultService()

    private var fileManager: FileManager {
        FileManager.default
    }

    private init() {
        Self.createStorageIfNeeded()
    }

    private static let appGroupIdentifier = "group.com.reelmind.app"

    private static var storageDirectory: URL {
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return containerURL.appendingPathComponent("ReelMind", isDirectory: true)
        }
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("ReelMind", isDirectory: true)
    }

    private static var legacyStorageDirectory: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("ReelMind", isDirectory: true)
    }

    private var storageDirectory: URL {
        Self.storageDirectory
    }

    private var reelsFileURL: URL {
        storageDirectory.appendingPathComponent("reels_vault.json")
    }

    private var foldersFileURL: URL {
        storageDirectory.appendingPathComponent("folders_vault.json")
    }

    private static func createStorageIfNeeded() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: storageDirectory.path) {
            try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        }

        // Migrate from legacy app support directory if moving to App Group container
        if storageDirectory.path != legacyStorageDirectory.path {
            let legacyReels = legacyStorageDirectory.appendingPathComponent("reels_vault.json")
            let targetReels = storageDirectory.appendingPathComponent("reels_vault.json")
            if fileManager.fileExists(atPath: legacyReels.path) && !fileManager.fileExists(atPath: targetReels.path) {
                try? fileManager.copyItem(at: legacyReels, to: targetReels)
            }

            let legacyFolders = legacyStorageDirectory.appendingPathComponent("folders_vault.json")
            let targetFolders = storageDirectory.appendingPathComponent("folders_vault.json")
            if fileManager.fileExists(atPath: legacyFolders.path) && !fileManager.fileExists(atPath: targetFolders.path) {
                try? fileManager.copyItem(at: legacyFolders, to: targetFolders)
            }
        }
    }

    // MARK: - Reels Operations

    public func loadReels() -> [Reel] {
        Self.createStorageIfNeeded()
        guard fileManager.fileExists(atPath: reelsFileURL.path) else {
            let samples = SampleData.initialReels
            saveReels(samples)
            return samples
        }

        do {
            let data = try Data(contentsOf: reelsFileURL)
            return try JSONDecoder().decode([Reel].self, from: data)
        } catch {
            return []
        }
    }

    public func saveReels(_ reels: [Reel]) {
        Self.createStorageIfNeeded()
        do {
            let data = try JSONEncoder().encode(reels)
            try data.write(to: reelsFileURL, options: .atomic)
        } catch {
            print("Error saving local reels: \(error)")
        }
    }

    public func addOrUpdateReel(_ reel: Reel) {
        var existing = loadReels()
        if let index = existing.firstIndex(where: { $0.id == reel.id }) {
            existing[index] = reel
        } else {
            existing.insert(reel, at: 0)
        }
        saveReels(existing)
    }

    public func deleteReel(id: String) {
        var existing = loadReels()
        existing.removeAll { $0.id == id }
        saveReels(existing)
    }

    // MARK: - Export and Restore

    public func exportVaultAsMarkdown() -> String {
        let reels = loadReels()
        var markdown = "# ReelMind AI Vault Export\n\n"
        markdown += "Exported on: \(ISO8601DateFormatter().string(from: Date()))\n"
        markdown += "Total Saved Reels: \(reels.count)\n\n---\n\n"

        for reel in reels {
            markdown += "## \(reel.title)\n"
            markdown += "- **Platform:** \(reel.platform.capitalized)\n"
            if !reel.difficulty.isEmpty {
                markdown += "- **Difficulty:** \(reel.difficulty)\n"
            }
            if let time = reel.estimatedTime, !time.isEmpty {
                markdown += "- **Estimated Time:** \(time)\n"
            }
            markdown += "- **URL:** \(reel.url)\n\n"
            markdown += "### Summary\n\(reel.summary)\n\n"

            if !reel.aiTools.isEmpty {
                markdown += "### Mentioned AI Tools\n" + reel.aiTools.map { "- \($0)" }.joined(separator: "\n") + "\n\n"
            }

            if !reel.keySteps.isEmpty {
                markdown += "### Step-by-Step Guide\n" + reel.keySteps.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n") + "\n\n"
            }

            if !reel.prompts.isEmpty {
                markdown += "### Prompts & Formulas\n" + reel.prompts.map { "```\n\($0)\n```" }.joined(separator: "\n\n") + "\n\n"
            }

            if !reel.userNotes.isEmpty {
                markdown += "### Personal Notes\n\(reel.userNotes)\n\n"
            }

            markdown += "---\n\n"
        }
        return markdown
    }

    public func restoreSampleReels() {
        let samples = SampleData.initialReels
        saveReels(samples)
    }

    // MARK: - Folders Operations

    public func loadFolders() -> [Folder] {
        Self.createStorageIfNeeded()
        guard fileManager.fileExists(atPath: foldersFileURL.path) else {
            let samples = SampleData.initialFolders
            saveFolders(samples)
            return samples
        }

        do {
            let data = try Data(contentsOf: foldersFileURL)
            return try JSONDecoder().decode([Folder].self, from: data)
        } catch {
            return []
        }
    }

    public func saveFolders(_ folders: [Folder]) {
        Self.createStorageIfNeeded()
        do {
            let data = try JSONEncoder().encode(folders)
            try data.write(to: foldersFileURL, options: .atomic)
        } catch {
            print("Error saving local folders: \(error)")
        }
    }
}

// MARK: - App Store Quality Sample Data

public enum SampleData {
    public static var initialFolders: [Folder] {
        [
            Folder(id: "ai-video", name: "AI Video & 3D", icon: "🎬", color: "#8b5cf6", totalReelCount: 1),
            Folder(id: "prompt-eng", name: "Prompt Vault", icon: "⚡", color: "#ec4899", totalReelCount: 1),
            Folder(id: "dev-tools", name: "Dev & Agents", icon: "💻", color: "#3b82f6", totalReelCount: 1)
        ]
    }

    public static var initialReels: [Reel] {
        [
            Reel(
                id: "sample-1",
                url: "https://www.instagram.com/reel/sample1/",
                platform: "Instagram",
                author: "ai_creator",
                title: "Midjourney v6.1 Ultra-Realistic Lighting Formula",
                summary: "Master cinematic lighting and photorealism in Midjourney with precise focal length and dynamic ISO modifiers.",
                aiTools: ["Midjourney v6.1", "Magnific AI"],
                keySteps: [
                    "Specify lens aperture (e.g. 85mm f/1.4 lens) for depth of field.",
                    "Add volumetric cinematic rim lighting in the background.",
                    "Apply --stylize 250 --v 6.1 parameter flags."
                ],
                prompts: [
                    "/imagine prompt: extreme close-up portrait of an astronaut with reflective gold visor, mars desert reflection, 85mm f/1.4 lens, natural sunlight, cinematic rim lighting, 8k resolution, raw photo --ar 16:9 --v 6.1 --style raw"
                ],
                tags: ["midjourney", "prompt", "lighting", "photography"],
                difficulty: "Principiante",
                estimatedTime: "< 5 min",
                status: "favorite",
                userNotes: "Probar este fin de semana para miniaturas de YouTube.",
                folderId: "prompt-eng",
                folderName: "Prompt Vault",
                mediaType: "reel",
                createdAt: "2026-11-23T12:00:00Z",
                updatedAt: "2026-11-23T12:00:00Z"
            ),
            Reel(
                id: "sample-2",
                url: "https://www.tiktok.com/@techguru/sample2",
                platform: "TikTok",
                author: "techguru",
                title: "Claude Code CLI: Full Agentic Coding Setup",
                summary: "Automate terminal tasks, code migrations, and debugging using Anthropic Claude Code command-line agent.",
                aiTools: ["Claude Code", "Cursor", "Terminal"],
                keySteps: [
                    "Install Claude Code via npm global package.",
                    "Initialize project context with claude config.",
                    "Use prompt chaining to generate modular Swift/Node code."
                ],
                prompts: [
                    "claude --prompt 'Refactor this module into clean MVVM architecture with Swift Concurrency'"
                ],
                tags: ["claude", "agents", "coding", "cli"],
                difficulty: "Intermedio",
                estimatedTime: "15-30 min",
                status: "tested",
                userNotes: "Totalmente compatible con nuestro workflow en Mac.",
                folderId: "dev-tools",
                folderName: "Dev & Agents",
                mediaType: "reel",
                createdAt: "2026-11-23T12:15:00Z",
                updatedAt: "2026-11-23T12:15:00Z"
            )
        ]
    }
}
