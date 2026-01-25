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
        isActive: Bool = false
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
    }
    
    // MARK: - Helpers
    
    /// Format date of birth for display
    var formattedDateOfBirth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateOfBirth) {
            formatter.dateFormat = "dd MMM yyyy"
            return formatter.string(from: date)
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
    }
    
    /// Convert to SwiftData model
    func toPartnerProfile() -> PartnerProfile {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
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
            createdAt: dateFormatter.date(from: createdAt) ?? Date(),
            updatedAt: dateFormatter.date(from: updatedAt) ?? Date(),
            lastMatchedAt: lastMatchedAt.flatMap { dateFormatter.date(from: $0) },
            isSynced: true,
            serverSyncedAt: Date(),
            isSelf: isSelf ?? false,
            isActive: isActive ?? false
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
