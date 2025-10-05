import Foundation
import Security

// MARK: - TokenStore
final class TokenStore {
    static let shared = TokenStore()
    private init() {}

    // Keychain service & accounts
    private let service = "com.amanpay.tokens"
    private let kAccess  = "access"
    private let kRefresh = "refresh"

    // MARK: Public API — Tokens

    /// Save tokens (only overwrites non-nil values).
    func save(access: String?, refresh: String?) {
        if let a = access { setKeychain(a, account: kAccess) }
        if let r = refresh { setKeychain(r, account: kRefresh) }
    }

    /// Update only access token (useful after refresh).
    func updateAccess(_ access: String) {
        setKeychain(access, account: kAccess)
    }

    func readAccess()  -> String? { getKeychain(account: kAccess) }
    func readRefresh() -> String? { getKeychain(account: kRefresh) }

    /// Remove both tokens from keychain.
    func clear() {
        deleteKeychain(account: kAccess)
        deleteKeychain(account: kRefresh)
    }

    // MARK: - Keychain helpers

    @discardableResult
    private func setKeychain(_ value: String, account: String) -> OSStatus {
        // delete old first (idempotent)
        deleteKeychain(account: account)

        var query: [String: Any] = [
            kSecClass as String            : kSecClassGenericPassword,
            kSecAttrService as String      : service,
            kSecAttrAccount as String      : account,
            kSecValueData as String        : Data(value.utf8),
            // Reasonable accessibility for background networking
            kSecAttrAccessible as String   : kSecAttrAccessibleAfterFirstUnlock
        ]
        #if !targetEnvironment(simulator)
        // If you ever need to share between targets, set kSecAttrAccessGroup here
        #endif
        let status = SecItemAdd(query as CFDictionary, nil)
        #if DEBUG
        if status != errSecSuccess { print("🔐 SecItemAdd[\(account)] => \(status)") }
        #endif
        return status
    }

    private func getKeychain(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String            : kSecClassGenericPassword,
            kSecAttrService as String      : service,
            kSecAttrAccount as String      : account,
            kSecReturnData as String       : true,
            kSecMatchLimit as String       : kSecMatchLimitOne
        ]
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        #if DEBUG
        if status != errSecSuccess && status != errSecItemNotFound {
            print("🔐 SecItemCopyMatching[\(account)] => \(status)")
        }
        #endif
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    @discardableResult
    private func deleteKeychain(account: String) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account
        ]
        let status = SecItemDelete(query as CFDictionary)
        #if DEBUG
        if status != errSecSuccess && status != errSecItemNotFound {
            print("🔐 SecItemDelete[\(account)] => \(status)")
        }
        #endif
        return status
    }
}

// MARK: - User cache (UserDefaults)
// Public profile (UserDTO) is NOT sensitive like tokens; cache it for instant UI hydration.
extension TokenStore {
    // Namespaced key (separate per target: Dev/Prod)
    private static let userKey: String = {
        (Bundle.main.bundleIdentifier ?? "com.amanpay.app") + ".user.json"
    }()

    /// Save user profile JSON (for quick hydration on app launch).
    func save(user: UserDTO) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: Self.userKey)
        }
    }

    /// Read cached user profile if available.
    func readUser() -> UserDTO? {
        guard let data = UserDefaults.standard.data(forKey: Self.userKey) else { return nil }
        return try? JSONDecoder().decode(UserDTO.self, from: data)
    }

    /// Clear cached user profile.
    func clearUser() {
        UserDefaults.standard.removeObject(forKey: Self.userKey)
    }

    /// One-time migration from old key (e.g., "ap_user_json") to the new namespaced key.
    func migrateUserKeyIfNeeded(from oldKey: String = "ap_user_json") {
        guard oldKey != Self.userKey else { return }
        let defaults = UserDefaults.standard
        guard
            let oldData = defaults.data(forKey: oldKey),
            defaults.data(forKey: Self.userKey) == nil
        else { return }
        defaults.set(oldData, forKey: Self.userKey)
        defaults.removeObject(forKey: oldKey)
        #if DEBUG
        print("✅ Migrated user cache from '\(oldKey)' to '\(Self.userKey)'")
        #endif
    }
}
