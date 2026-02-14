import Foundation

// MARK: - Partner Data Model
/// Represents birth data for a partner in compatibility matching
/// Supports multi-partner comparison feature
struct PartnerData: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var gender: String  // "male", "female", "non-binary"
    var birthDate: Date
    var birthTime: Date
    var birthDateSet: Bool  // Track if user has explicitly selected date
    var birthTimeSet: Bool  // Track if user has explicitly selected time
    var city: String
    var latitude: Double
    var longitude: Double
    var placeId: String
    var timeUnknown: Bool
    var savedProfileId: String?  // ID of saved PartnerProfile if loaded from picker
    
    init(
        id: UUID = UUID(),
        name: String = "",
        gender: String = "",
        birthDate: Date = Date(),
        birthTime: Date = Date(),
        birthDateSet: Bool = false,
        birthTimeSet: Bool = false,
        city: String = "",
        latitude: Double = 0,
        longitude: Double = 0,
        placeId: String = "",
        timeUnknown: Bool = false,
        savedProfileId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.gender = gender
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.birthDateSet = birthDateSet
        self.birthTimeSet = birthTimeSet
        self.city = city
        self.latitude = latitude
        self.longitude = longitude
        self.placeId = placeId
        self.timeUnknown = timeUnknown
        self.savedProfileId = savedProfileId
    }
    
    // MARK: - Formatted Display
    var formattedDob: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: birthDate)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: birthTime)
    }
    
    var formattedSummary: String {
        let parts = [name, formattedDob, city].filter { !$0.isEmpty }
        return parts.joined(separator: " · ")
    }
    
    // MARK: - Validation
    var isComplete: Bool {
        !name.isEmpty && !city.isEmpty && latitude != 0 && longitude != 0
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PartnerData, rhs: PartnerData) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Comparison Result Model
/// Stores the result of a compatibility analysis for one partner
/// Used in multi-partner comparison overview
struct ComparisonResult: Identifiable, Hashable {
    let id: UUID
    let partner: PartnerData
    let result: CompatibilityResult
    
    init(partner: PartnerData, result: CompatibilityResult) {
        self.id = UUID()
        self.partner = partner
        self.result = result
    }
    
    // MARK: - Derived Display Values
    var overallScore: Int { result.totalScore }
    var maxScore: Int { result.maxScore }
    var percentage: Double { result.percentage }
    
    var briefSummary: String {
        let summary = result.summary
        if summary.count > 60 {
            return String(summary.prefix(60)) + "..."
        }
        return summary
    }
    
    var statusLabel: String {
        switch percentage {
        case 0.75...1.0: return "Excellent Match"
        case 0.6..<0.75: return "Good Match"
        case 0.45..<0.6: return "Average"
        default: return "Challenging"
        }
    }
    
    var statusColor: String {
        switch percentage {
        case 0.75...1.0: return "green"
        case 0.6..<0.75: return "gold"
        case 0.45..<0.6: return "orange"
        default: return "red"
        }
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ComparisonResult, rhs: ComparisonResult) -> Bool {
        lhs.id == rhs.id
    }
}
