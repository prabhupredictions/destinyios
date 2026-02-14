import Foundation
import SwiftData

/// Partner profile for compatibility matching and Switch Profile feature
/// Stored locally in SwiftData and synced with server
@Model
final class PartnerProfile: Identifiable {
    @Attribute(.unique) var id: String
    var name: String
    var gender: String              // "male" or "female"
    var dateOfBirth: String         // "YYYY-MM-DD"
    var timeOfBirth: String?        // "HH:MM"
    var cityOfBirth: String?
    var latitude: Double?
    var longitude: Double?
    var timezone: Double?
    var birthTimeUnknown: Bool
    var consentGiven: Bool
    var createdAt: Date
    var updatedAt: Date
    var lastMatchedAt: Date?
    
    // Server sync tracking
    var isSynced: Bool
    var serverSyncedAt: Date?
    
    // Switch Profile feature
    var isSelf: Bool                // True if this is the account owner's profile
    var isActive: Bool              // True if this is the currently active context
    var firstSwitchedAt: Date?      // Set when profile is first switched to (marks as "used")
    
    init(
        id: String = UUID().uuidString,
        name: String,
        gender: String,
        dateOfBirth: String,
        timeOfBirth: String? = nil,
        cityOfBirth: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        timezone: Double? = nil,
        birthTimeUnknown: Bool = false,
        consentGiven: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastMatchedAt: Date? = nil,
        isSynced: Bool = false,
        serverSyncedAt: Date? = nil,
        isSelf: Bool = false,
        isActive: Bool = false,
        firstSwitchedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.gender = gender
        self.dateOfBirth = dateOfBirth
        self.timeOfBirth = timeOfBirth
        self.cityOfBirth = cityOfBirth
        self.latitude = latitude
        self.longitude = longitude
        self.timezone = timezone
        self.birthTimeUnknown = birthTimeUnknown
        self.consentGiven = consentGiven
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastMatchedAt = lastMatchedAt
        self.isSynced = isSynced
        self.serverSyncedAt = serverSyncedAt
        self.isSelf = isSelf
        self.isActive = isActive
        self.firstSwitchedAt = firstSwitchedAt
    }
    
    // MARK: - Helpers
    
    /// Format date of birth for display
    var formattedDateOfBirth: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateOfBirth) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateOfBirth
    }
    
    /// Gender symbol for display
    var genderSymbol: String {
        gender == "male" ? "♂" : "♀"
    }
    
    /// First letter of name for avatar
    var avatarInitial: String {
        String(name.prefix(1).uppercased())
    }
    
    /// Mark as used in a match
    func markAsUsedInMatch() {
        lastMatchedAt = Date()
        updatedAt = Date()
    }
}

// MARK: - API Response Model

/// Response model for partner from server
struct PartnerProfileResponse: Codable {
    let id: String
    let name: String
    let gender: String
    let dateOfBirth: String
    let timeOfBirth: String?
    let cityOfBirth: String?
    let latitude: Double?
    let longitude: Double?
    let timezone: Double?
    let birthTimeUnknown: Bool
    let consentGiven: Bool
    let createdAt: String
    let updatedAt: String
    let lastMatchedAt: String?
    let isSelf: Bool?
    let isActive: Bool?
    let firstSwitchedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, gender, latitude, longitude, timezone
        case dateOfBirth = "date_of_birth"
        case timeOfBirth = "time_of_birth"
        case cityOfBirth = "city_of_birth"
        case birthTimeUnknown = "birth_time_unknown"
        case consentGiven = "consent_given"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastMatchedAt = "last_matched_at"
        case isSelf = "is_self"
        case isActive = "is_active"
        case firstSwitchedAt = "first_switched_at"
    }
    
    /// Convert to SwiftData model
    func toPartnerProfile() -> PartnerProfile {
        // ISO8601 with fractional seconds and timezone
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Fallback: DateFormatter for dates without timezone (server format)
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        fallbackFormatter.timeZone = TimeZone(identifier: "UTC")
        
        // Helper to parse date with fallback
        func parseDate(_ string: String?) -> Date? {
            guard let string = string else { return nil }
            return iso8601Formatter.date(from: string) ?? fallbackFormatter.date(from: string)
        }
        
        return PartnerProfile(
            id: id,
            name: name,
            gender: gender,
            dateOfBirth: dateOfBirth,
            timeOfBirth: timeOfBirth,
            cityOfBirth: cityOfBirth,
            latitude: latitude,
            longitude: longitude,
            timezone: timezone,
            birthTimeUnknown: birthTimeUnknown,
            consentGiven: consentGiven,
            createdAt: parseDate(createdAt) ?? Date(),
            updatedAt: parseDate(updatedAt) ?? Date(),
            lastMatchedAt: parseDate(lastMatchedAt),
            isSynced: true,
            serverSyncedAt: Date(),
            isSelf: isSelf ?? false,
            isActive: isActive ?? false,
            firstSwitchedAt: parseDate(firstSwitchedAt)
        )
    }
}

// MARK: - API Request Model

/// Request model for creating/updating partner on server
struct PartnerProfileRequest: Codable {
    let name: String
    let gender: String
    let dateOfBirth: String
    let timeOfBirth: String?
    let cityOfBirth: String?
    let latitude: Double?
    let longitude: Double?
    let timezone: Double?
    let birthTimeUnknown: Bool
    let isSelf: Bool
    
    enum CodingKeys: String, CodingKey {
        case name, gender, latitude, longitude, timezone
        case dateOfBirth = "date_of_birth"
        case timeOfBirth = "time_of_birth"
        case cityOfBirth = "city_of_birth"
        case birthTimeUnknown = "birth_time_unknown"
        case isSelf = "is_self"
    }
    
    init(from profile: PartnerProfile) {
        self.name = profile.name
        self.gender = profile.gender
        self.dateOfBirth = profile.dateOfBirth
        self.timeOfBirth = profile.timeOfBirth
        self.cityOfBirth = profile.cityOfBirth
        self.latitude = profile.latitude
        self.longitude = profile.longitude
        self.timezone = profile.timezone
        self.birthTimeUnknown = profile.birthTimeUnknown
        self.isSelf = profile.isSelf
    }
}
