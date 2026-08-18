import Foundation
import Security

enum KeychainService {
    private static let service = "com.zeddius.app.tokens"

    enum Key: String {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }

    // No kSecAttrAccessGroup is passed here: when a keychain-access-groups
    // entitlement is present, omitting the attribute makes the OS use the
    // first group in that entitlement (com.zeddius.shared) as the default,
    // which is exactly the group the future Watch app needs to read from.
    static func set(_ value: String, for key: Key) {
        let data = Data(value.utf8)
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]
        SecItemDelete(query as CFDictionary)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(query as CFDictionary, nil)
    }

    static func get(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: Key) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func clearAll() {
        delete(.accessToken)
        delete(.refreshToken)
    }
}
