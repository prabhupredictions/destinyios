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
}

// MARK: - Keychain Keys
extension KeychainService {
    struct Keys {
        static let userId = "userId"
        static let authToken = "authToken"
        static let refreshToken = "refreshToken"
    }
}
