import Foundation

// MARK: - Chat Thread (Matches verified API)
struct ChatThread: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let preview: String
    let area: String
    let messageCount: Int
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, preview, area
        case messageCount = "message_count"
        case updatedAt = "updated_at"
    }
}

// MARK: - Feedback Request (Matches verified API)
struct FeedbackRequest: Codable, Sendable {
    let predictionId: String
    let rating: Int
    let feedbackText: String
    let userEmail: String
    let query: String
    let predictionText: String
    let area: String
    
    enum CodingKeys: String, CodingKey {
        case predictionId = "prediction_id"
        case feedbackText = "feedback_text"
        case userEmail = "user_email"
        case predictionText = "prediction_text"
        case rating, query, area
    }
}

// MARK: - Compatibility Request
struct CompatibilityRequest: Codable, Sendable {
    let boy: BirthDetails
    let girl: BirthDetails
    var sessionId: String?
    var userEmail: String?
    var profileId: String?  // Active profile for thread scoping
    
    // Multi-partner comparison support
    var comparisonGroupId: String?
    var partnerIndex: Int?
    
    enum CodingKeys: String, CodingKey {
        case boy, girl
        case sessionId = "session_id"
        case userEmail = "user_email"
        case profileId = "profile_id"
        case comparisonGroupId = "comparison_group_id"
        case partnerIndex = "partner_index"
    }
}

// MARK: - Birth Details (For Compatibility)
struct BirthDetails: Codable, Sendable {
    let dob: String
    let time: String
    let lat: Double
    let lon: Double
    var name: String = "Native"
    var place: String = "Unknown"
}

// MARK: - Dosha Summary (V2.1)
struct DoshaSummary: Codable, Sendable {
    let totalDoshas: Int?
    let cancelledCount: Int?
    let activeCount: Int?
    let details: [String: DoshaDetail]?
    
    enum CodingKeys: String, CodingKey {
        case totalDoshas = "total_doshas"
        case cancelledCount = "cancelled_count"
        case activeCount = "active_count"
        case details
    }
}

struct DoshaDetail: Codable, Sendable {
    let present: Bool?
    let cancelled: Bool?
    let reasonShort: String?
    
    enum CodingKeys: String, CodingKey {
        case present, cancelled
        case reasonShort = "reason_short"
    }
}

// MARK: - Compatibility Response
struct CompatibilityResponse: Codable, Sendable {
    let sessionId: String?
    let status: String
    let predictionId: String?
    let llmAnalysis: String?
    let analysisData: AnalysisData?
    
    // Multi-partner comparison support
    let comparisonGroupId: String?
    let partnerIndex: Int?
    
    // V2.1 — Hard-no gate + adjusted scores
    let hardNoFlags: HardNoFlags?
    let adjustedTotalScore: Double?
    let adjustedCategory: String?
    let doshaSummary: DoshaSummary?
    let comparisonIndicators: ComparisonIndicators?
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case predictionId = "prediction_id"
        case llmAnalysis = "llm_analysis"
        case analysisData = "analysis_data"
        case comparisonGroupId = "comparison_group_id"
        case partnerIndex = "partner_index"
        case hardNoFlags = "hard_no_flags"
        case adjustedTotalScore = "adjusted_total_score"
        case adjustedCategory = "adjusted_category"
        case doshaSummary = "dosha_summary"
        case comparisonIndicators = "comparison_indicators"
        case status
    }
}

// MARK: - Analysis Data (Raw Dosha/Yoga Data)
struct AnalysisData: Codable, Sendable {
    let joint: JointData?
    let boy: PersonData?
    let girl: PersonData?
}

struct JointData: Codable, Sendable {
    let ashtakootMatching: [String: AnyCodable]?
    let mangalCompatibility: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case ashtakootMatching = "ashtakoot_matching"
        case mangalCompatibility = "mangal_compatibility"
    }
}

struct PersonData: Codable, Sendable {
    let details: BirthDetails?
    let raw: RawDoshaData?
    let formatted: [String: String]?
    let chartData: ChartData?  // NEW: For UI chart display
    
    enum CodingKeys: String, CodingKey {
        case details, raw, formatted
        case chartData = "chart_data"
    }
}

// MARK: - AnyCodable Helper for dynamic JSON
struct AnyCodable: Codable, Sendable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let arrayValue = value as? [Any] {
            try container.encode(arrayValue.map { AnyCodable($0) })
        } else if let dictValue = value as? [String: Any] {
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        } else {
            try container.encodeNil()
        }
    }
}

// MARK: - Hard-No Gate Flags (V2.1)
struct HardNoFlags: Codable, Sendable {
    let isRecommended: Bool
    let rejectionReasons: [String]
    
    enum CodingKeys: String, CodingKey {
        case isRecommended = "is_recommended"
        case rejectionReasons = "rejection_reasons"
    }
}

// MARK: - Comparison Indicators (LLM-generated)
struct ComparisonIndicators: Codable, Sendable {
    let yogaImpact: YogaImpact?
    let dashaOutlook: DashaOutlook?
    let overallVerdict: OverallVerdict?
    
    struct YogaImpact: Codable, Sendable {
        let score: Double?
        let summary: String?
    }
    
    struct DashaOutlook: Codable, Sendable {
        let label: String?
        let summary: String?
    }
    
    struct OverallVerdict: Codable, Sendable {
        let category: String?
        let oneLiner: String?
        
        enum CodingKeys: String, CodingKey {
            case category
            case oneLiner = "one_liner"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case yogaImpact = "yoga_impact"
        case dashaOutlook = "dasha_outlook"
        case overallVerdict = "overall_verdict"
    }
}

// MARK: - Compatibility Follow-Up Request (for Ask Destiny)
struct CompatibilityFollowUpRequest: Codable, Sendable {
    let query: String
    let sessionId: String
    let userEmail: String
    
    enum CodingKeys: String, CodingKey {
        case query
        case sessionId = "session_id"
        case userEmail = "user_email"
    }
}

// MARK: - Compatibility Follow-Up Response
struct CompatibilityFollowUpResponse: Codable, Sendable {
    let status: String?       // "success", "redirect", "error", "blocked"
    let target: String?       // For redirect responses: "Boy" or "Girl"
    let answer: String?       // AI answer for compatibility questions
    let message: String?      // Error or info message
    let birthData: BirthDetails? // For redirect: target's birth details
    let reason: String?       // Reason for redirect
    let executionTimeMs: Double?  // Execution time in milliseconds
    let followUpSuggestions: [String]?  // LLM-generated follow-up questions
    
    enum CodingKeys: String, CodingKey {
        case status, target, answer, message, reason
        case birthData = "birth_data"
        case executionTimeMs = "execution_time_ms"
        case followUpSuggestions = "follow_up_suggestions"
    }
}

// MARK: - User (Placeholder for Auth)
struct User: Codable, Identifiable, Sendable {
    let id: String
    var email: String?
    var name: String?
    var provider: String? // "apple" or "google"
}

