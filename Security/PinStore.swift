import Foundation
import Security
import CryptoKit

final class PinStore {
    static let shared = PinStore(); private init() {}

    private let service = "com.amanpay.pin"
    private let kPinHash = "pin.hash"
    private let kPinSalt = "pin.salt"

    /// PIN bor-yo‘qligi
    var exists: Bool {
        getData(account: kPinHash) != nil && getData(account: kPinSalt) != nil
    }

    /// PIN yaratish yoki almashtirish
    @discardableResult
    func save(pin: String) -> Bool {
        guard let salt = makeSalt(count: 16) else { return false }
        let hash = sha256(pin: pin, salt: salt)
        setData(hash, account: kPinHash)
        setData(salt, account: kPinSalt)
        return true
    }

    /// Joriy PIN to‘g‘riligini tekshirish
    func verify(pin: String) -> Bool {
        guard
            let salt = getData(account: kPinSalt),
            let hash = getData(account: kPinHash)
        else { return false }
        return sha256(pin: pin, salt: salt) == hash
    }

    /// PINni tozalash
    func clear() {
        del(account: kPinHash)
        del(account: kPinSalt)
    }

    // MARK: - Crypto
    private func sha256(pin: String, salt: Data) -> Data {
        let input = Data(pin.utf8) + salt
        let digest = SHA256.hash(data: input)
        return Data(digest)
    }
    private func makeSalt(count: Int) -> Data? {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return status == errSecSuccess ? Data(bytes) : nil
    }

    // MARK: - Keychain helpers (WhenPasscodeSetThisDeviceOnly — pro)
    @discardableResult
    private func setData(_ value: Data, account: String) -> OSStatus {
        del(account: account)
        var q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: value
        ]
        #if targetEnvironment(simulator)
        q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        #else
        q[kSecAttrAccessible as String] = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        #endif
        return SecItemAdd(q as CFDictionary, nil)
    }
    private func getData(account: String) -> Data? {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var res: AnyObject?
        let status = SecItemCopyMatching(q as CFDictionary, &res)
        guard status == errSecSuccess, let d = res as? Data else { return nil }
        return d
    }
    private func del(account: String) {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(q as CFDictionary)
    }
}
