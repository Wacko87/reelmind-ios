import Foundation
import Observation

@Observable
@MainActor
public final class SettingsViewModel {
    public var serverURL: String = ""
    public var apiToken: String = ""
    public var isTesting: Bool = false
    public var connectionSuccess: Bool? = nil
    public var statusMessage: String? = nil

    private let apiClient: APIClient

    public init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
        loadSettings()
    }

    public func loadSettings() {
        self.serverURL = UserDefaults.standard.string(forKey: "reelmind_server_url") ?? "https://reelmind.wacko87.es"
        self.apiToken = UserDefaults.standard.string(forKey: "reelmind_api_token") ?? ""
    }

    public func saveSettings() {
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

        do {
            _ = try await apiClient.checkAuthStatus()
            connectionSuccess = true
            statusMessage = "Connected to ReelMind server successfully."
        } catch {
            connectionSuccess = false
            statusMessage = "Connection failed: \(error.localizedDescription)"
        }
        isTesting = false
    }
}
