import Foundation
import Security

/// Thread-safe service for secure storage of credentials in the iOS Keychain.
public final class KeychainService: Sendable {
    public static let shared = KeychainService()

    private let serviceName = "com.reelmind.app"

    private init() {}

    // MARK: - Core Operations

    @discardableResult
    public func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // First remove any existing item with this key
        delete(key: key)

        guard !value.isEmpty else { return true }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    public func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    @discardableResult
    public func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Migration Helper

    /// Migrates a key from UserDefaults to Keychain if found, and clears it from UserDefaults.
    public func migrateFromUserDefaultsIfNeeded(key: String) {
        if let userDefaultsValue = UserDefaults.standard.string(forKey: key),
           !userDefaultsValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Save to Keychain
            save(key: key, value: userDefaultsValue)
            // Remove insecure plaintext entry from UserDefaults
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
