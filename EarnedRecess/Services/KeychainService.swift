import Foundation
import Security
import CryptoKit

final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    // MARK: - PIN Management

    func savePIN(_ pin: String) throws {
        let hash = hashPIN(pin)
        let data = Data(hash.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: Constants.Keychain.pinHashKey,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func verifyPIN(_ pin: String) -> Bool {
        guard let stored = readPINHash() else { return false }
        return hashPIN(pin) == stored
    }

    func pinExists() -> Bool {
        readPINHash() != nil
    }

    func changePIN(current: String, new: String) throws {
        guard verifyPIN(current) else { throw KeychainError.incorrectPIN }
        try savePIN(new)
    }

    func deletePIN() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: Constants.Keychain.pinHashKey
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - PIN Attempt Tracking

    func getPINAttempts() -> Int {
        guard let data = readKeychainData(account: "pin.attempts"),
              let str = String(data: data, encoding: .utf8),
              let value = Int(str) else { return 0 }
        return value
    }

    func setPINAttempts(_ count: Int) {
        let data = Data(String(count).utf8)
        writeKeychainData(data, account: "pin.attempts")
    }

    func getPINLockoutUntil() -> Date? {
        guard let data = readKeychainData(account: "pin.lockoutUntil"),
              let str = String(data: data, encoding: .utf8),
              let interval = Double(str) else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    func setPINLockoutUntil(_ date: Date?) {
        if let date = date {
            let data = Data(String(date.timeIntervalSince1970).utf8)
            writeKeychainData(data, account: "pin.lockoutUntil")
        } else {
            deleteKeychainItem(account: "pin.lockoutUntil")
        }
    }

    // MARK: - Private

    private func hashPIN(_ pin: String) -> String {
        let salt = deviceSalt()
        let data = Data((pin + salt).utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func deviceSalt() -> String {
        if let data = readKeychainData(account: "pin.salt"),
           let salt = String(data: data, encoding: .utf8) {
            return salt
        }
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let salt = bytes.map { String(format: "%02x", $0) }.joined()
        writeKeychainData(Data(salt.utf8), account: "pin.salt")
        return salt
    }

    private func readPINHash() -> String? {
        guard let data = readKeychainData(account: Constants.Keychain.pinHashKey),
              let hash = String(data: data, encoding: .utf8) else { return nil }
        return hash
    }

    private func readKeychainData(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private func writeKeychainData(_ data: Data, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func deleteKeychainItem(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case incorrectPIN

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status): return "Keychain save failed: \(status)"
        case .incorrectPIN: return "Incorrect PIN"
        }
    }
}
