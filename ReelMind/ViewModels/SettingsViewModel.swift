import Foundation
import Observation

@Observable
@MainActor
public final class SettingsViewModel {
    // Local / App Store AI Engine
    public var geminiApiKey: String = ""
    public var geminiModel: String = "gemini-3.5-flash-lite"

    // Optional Homelab / Server Mode
    public var useServerMode: Bool = true
    public var serverURL: String = "https://reels.wacko87.es"
    public var apiToken: String = "3004"

    public var isTesting: Bool = false
    public var connectionSuccess: Bool? = nil
    public var statusMessage: String? = nil

    public var isTestingServer: Bool = false
    public var serverConnectionSuccess: Bool? = nil
    public var serverStatusMessage: String? = nil

    // Vault Management
    public var exportedMarkdown: String = ""
    public var showExportSheet: Bool = false
    public var showRestoreConfirmation: Bool = false

    public init() {
        loadSettings()
    }

    public func loadSettings() {
        KeychainService.shared.migrateFromUserDefaultsIfNeeded(key: "gemini_api_key")
        KeychainService.shared.migrateFromUserDefaultsIfNeeded(key: "reelmind_api_token")

        self.geminiApiKey = KeychainService.shared.get(key: "gemini_api_key") ?? ""
        var savedModel = UserDefaults.standard.string(forKey: "gemini_model") ?? "gemini-3.5-flash-lite"
        if savedModel.contains("2.5") {
            savedModel = "gemini-3.5-flash-lite"
            UserDefaults.standard.set(savedModel, forKey: "gemini_model")
        }
        self.geminiModel = savedModel

        if UserDefaults.standard.object(forKey: "reelmind_use_server_mode") != nil {
            self.useServerMode = UserDefaults.standard.bool(forKey: "reelmind_use_server_mode")
        } else {
            self.useServerMode = true
            UserDefaults.standard.set(true, forKey: "reelmind_use_server_mode")
        }

        let savedURL = UserDefaults.standard.string(forKey: "reelmind_server_url") ?? ""
        self.serverURL = savedURL.isEmpty ? "https://reels.wacko87.es" : savedURL

        let savedToken = KeychainService.shared.get(key: "reelmind_api_token") ?? ""
        self.apiToken = savedToken.isEmpty ? "3004" : savedToken
    }

    public func saveSettings() {
        let trimmedKey = geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        KeychainService.shared.save(key: "gemini_api_key", value: trimmedKey)
        UserDefaults.standard.removeObject(forKey: "gemini_api_key")

        UserDefaults.standard.set(geminiModel, forKey: "gemini_model")
        UserDefaults.standard.set(useServerMode, forKey: "reelmind_use_server_mode")

        let trimmedURL = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedToken = apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(trimmedURL, forKey: "reelmind_server_url")
        KeychainService.shared.save(key: "reelmind_api_token", value: trimmedToken)
        UserDefaults.standard.removeObject(forKey: "reelmind_api_token")

        statusMessage = "Settings saved securely."
    }

    public func testServerConnection() async {
        isTestingServer = true
        serverConnectionSuccess = nil
        serverStatusMessage = nil

        defer { isTestingServer = false }

        saveSettings()

        do {
            let trimmedPin = apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedPin.isEmpty {
                _ = try await APIClient.shared.loginWithPIN(pin: trimmedPin)
            }
            let status = try await APIClient.shared.checkAuthStatus()
            if status.authRequired && !status.isAuthenticated {
                serverConnectionSuccess = false
                serverStatusMessage = Locale.current.language.languageCode?.identifier == "es"
                    ? "PIN incorrecto o sesión no autorizada."
                    : "Incorrect PIN or unauthorized session."
            } else {
                serverConnectionSuccess = true
                serverStatusMessage = Locale.current.language.languageCode?.identifier == "es"
                    ? "¡Conectado al servidor ReelMind (reels.wacko87.es) con éxito!"
                    : "Connected to ReelMind server successfully!"
            }
        } catch {
            serverConnectionSuccess = false
            serverStatusMessage = "Error del servidor: \(error.localizedDescription)"
        }
    }

    public func testConnection() async {
        if useServerMode {
            isTesting = true
            connectionSuccess = nil
            statusMessage = nil
            defer { isTesting = false }

            await testServerConnection()
            self.connectionSuccess = self.serverConnectionSuccess
            self.statusMessage = self.serverStatusMessage
        } else {
            saveSettings()
            isTesting = true
            connectionSuccess = nil
            statusMessage = nil

            defer {
                isTesting = false
            }

            // Test local Gemini API Key
            guard !geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                connectionSuccess = false
                statusMessage = "Please enter your Gemini API Key first."
                return
            }

            do {
                try await GeminiService.shared.testApiKey()
                connectionSuccess = true
                statusMessage = Locale.current.language.languageCode?.identifier == "es"
                    ? "¡Motor Gemini verificado y listo!"
                    : "Gemini AI Engine verified and ready!"
            } catch {
                connectionSuccess = false
                statusMessage = "Gemini Error: \(error.localizedDescription)"
            }
        }
    }

    public func prepareExport() async {
        self.exportedMarkdown = await LocalVaultService.shared.exportVaultAsMarkdown()
        self.showExportSheet = true
    }

    public func restoreSampleVault() async {
        await LocalVaultService.shared.restoreSampleReels()
        statusMessage = "Sample reels restored to vault."
    }
}
