import Foundation
import Observation

@Observable
@MainActor
public final class SettingsViewModel {
    // Local / App Store AI Engine
    public var geminiApiKey: String = ""
    public var geminiModel: String = "gemini-2.5-flash"

    // Optional Homelab / Server Mode
    public var useServerMode: Bool = false
    public var serverURL: String = ""
    public var apiToken: String = ""

    public var isTesting: Bool = false
    public var connectionSuccess: Bool? = nil
    public var statusMessage: String? = nil

    public init() {
        loadSettings()
    }

    public func loadSettings() {
        self.geminiApiKey = UserDefaults.standard.string(forKey: "gemini_api_key") ?? ""
        self.geminiModel = UserDefaults.standard.string(forKey: "gemini_model") ?? "gemini-2.5-flash"
        self.useServerMode = UserDefaults.standard.bool(forKey: "reelmind_use_server_mode")
        self.serverURL = UserDefaults.standard.string(forKey: "reelmind_server_url") ?? ""
        self.apiToken = UserDefaults.standard.string(forKey: "reelmind_api_token") ?? ""
    }

    public func saveSettings() {
        let trimmedKey = geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(trimmedKey, forKey: "gemini_api_key")
        UserDefaults.standard.set(geminiModel, forKey: "gemini_model")
        UserDefaults.standard.set(useServerMode, forKey: "reelmind_use_server_mode")

        let trimmedURL = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedToken = apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(trimmedURL, forKey: "reelmind_server_url")
        UserDefaults.standard.set(trimmedToken, forKey: "reelmind_api_token")

        statusMessage = "Settings saved successfully."
    }

    public func testConnection() async {
        saveSettings()
        isTesting = true
        connectionSuccess = nil
        statusMessage = nil

        if useServerMode {
            do {
                _ = try await APIClient.shared.checkAuthStatus()
                connectionSuccess = true
                statusMessage = "Connected to ReelMind server successfully."
            } catch {
                connectionSuccess = false
                statusMessage = "Server connection failed: \(error.localizedDescription)"
            }
        } else {
            // Test local Gemini API Key
            guard !geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                connectionSuccess = false
                statusMessage = "Please enter your Gemini API Key first."
                isTesting = false
                return
            }

            do {
                _ = try await GeminiService.shared.optimizePrompt(prompt: "Hello", targetModel: "Midjourney")
                connectionSuccess = true
                statusMessage = "Gemini AI Engine verified and ready!"
            } catch {
                connectionSuccess = false
                statusMessage = "Gemini Error: \(error.localizedDescription)"
            }
        }
        isTesting = false
    }
}
