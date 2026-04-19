import Foundation
import Security
import CryptoKit

class KeychainService {
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

    // MARK: - Private

    private func hashPIN(_ pin: String) -> String {
        let data = Data((pin + "earnedrecess.salt").utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func readPINHash() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: Constants.Keychain.pinHashKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let hash = String(data: data, encoding: .utf8) else { return nil }
        return hash
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
