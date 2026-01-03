import Foundation

/// Centralized helper for generating user-scoped storage keys
struct StorageKeys {
    
    // MARK: - Core Keys
    static let userBirthData = "userBirthData"
    static let userGender = "userGender"
    static let birthTimeUnknown = "birthTimeUnknown"
    static let hasBirthData = "hasBirthData"
    static let quotaUsed = "quotaUsed"
    
    // MARK: - Key Generation
    
    /// detailed description of what it does
    /// - Parameters:
    ///   - key: The base key name (e.g. "userBirthData")
    ///   - email: The user's email. If nil, uses current stored email. If that fails, uses "guest".
    /// - Returns: A user-scoped key like "userBirthData_user@example.com"
    static func userKey(for key: String, email: String? = nil) -> String {
        let userEmail = email ?? UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
        return "\(key)_\(userEmail)"
    }
    
    /// Get all user-scoped keys that should be cleared on full reset
    static func allKeys(for email: String) -> [String] {
        return [
            userKey(for: userBirthData, email: email),
            userKey(for: userGender, email: email),
            userKey(for: birthTimeUnknown, email: email),
            userKey(for: hasBirthData, email: email),
            userKey(for: quotaUsed, email: email)
        ]
    }
}
