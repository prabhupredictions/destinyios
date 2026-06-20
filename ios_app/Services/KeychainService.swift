import Foundation
import Security

/// Secure keychain storage service for sensitive data
final class KeychainService: @unchecked Sendable {
    static let shared = KeychainService()
    private init() {}
    
    // MARK: - Error Types
    enum KeychainError: Error, LocalizedError {
        case duplicateEntry
        case unknown(OSStatus)
        case notFound
        case encodingError
        
        var errorDescription: String? {
            switch self {
            case .duplicateEntry:
                return "Item already exists in keychain"
            case .unknown(let status):
                return "Keychain error: \(status)"
            case .notFound:
                return "Item not found in keychain"
            case .encodingError:
                return "Failed to encode data"
            }
        }
    }
    
    // MARK: - Constants
    private let service = "com.destiny.astrology"
    
    // MARK: - Public Methods
    
    /// Save data to keychain
    func save(data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    /// Save string to keychain
    func saveString(_ string: String, forKey key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.encodingError
        }
        try save(data: data, forKey: key)
    }
    
    /// Load data from keychain
    func load(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        return result as? Data
    }
    
    /// Load string from keychain
    func loadString(forKey key: String) -> String? {
        guard let data = load(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Delete item from keychain
    func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    /// Check if key exists
    func exists(forKey key: String) -> Bool {
        return load(forKey: key) != nil
    }
    
    /// Clear all saved data
    func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        SecItemDelete(query as CFDictionary)
    }

    /// C3 (1.7) — tri-state probe: does any keychain key for this service start with `prefix`?
    /// - Returns: `.present` if a match is found, `.absent` if explicitly not found,
    ///   `.indeterminate` when the keychain is locked or returns an unknown status.
    /// Used by the first-launch wipe at App init to distinguish "no leftover state"
    /// from "we don't yet know" — the wipe is suppressed in the indeterminate case
    /// AND the hasLaunchedBefore latch is NOT set, so a future unlocked launch can
    /// re-evaluate.
    enum KeyProbeResult {
        case present
        case absent
        case indeterminate
    }

    func probeAnyKey(withPrefix prefix: String) -> KeyProbeResult {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let items = result as? [[String: Any]] else { return .absent }
            for item in items {
                if let account = item[kSecAttrAccount as String] as? String,
                   account.hasPrefix(prefix) {
                    return .present
                }
            }
            return .absent
        case errSecItemNotFound:
            return .absent
        case errSecInteractionNotAllowed:
            // Keychain locked — defer the decision to a future unlocked launch.
            return .indeterminate
        default:
            // Unknown error — assume state exists (fail-safe; the wipe is irreversible).
            print("[Keychain] probeAnyKey unexpected OSStatus=\(status) for prefix=\(prefix); assuming .indeterminate")
            return .indeterminate
        }
    }
}

// MARK: - Keychain Keys
extension KeychainService {
    struct Keys {
        static let userId = "userId"
        static let authToken = "authToken"
        static let refreshToken = "refreshToken"
    }
}
