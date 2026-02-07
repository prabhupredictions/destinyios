import Foundation

// MARK: - Notification Item
/// Single notification from the inbox
struct NotificationItem: Codable, Identifiable, Equatable {
    let id: String
    let type: String
    let channel: String
    let subject: String?
    let preview: String?
    let status: String
    let read: Bool
    let createdAt: String?
    let readAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, channel, subject, preview, status, read
        case createdAt = "created_at"
        case readAt = "read_at"
    }
    
    // MARK: - Computed Properties
    
    /// Parsed creation date
    var createdDate: Date? {
        guard let createdAt = createdAt else { return nil }
        return ISO8601DateFormatter().date(from: createdAt) ??
               DateFormatter.backendFormatter.date(from: createdAt)
    }
    
    /// Friendly time ago string
    var timeAgo: String {
        guard let date = createdDate else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Icon name based on notification type
    var iconName: String {
        switch type.uppercased() {
        case "DAILY_PREDICTION", "DAILY_PREDICTION_READY":
            return "sun.max.fill"
        case "TRANSIT_ALERT":
            return "sparkles"
        case "SUBSCRIPTION_EXPIRING":
            return "creditcard.fill"
        case "WELCOME":
            return "hand.wave.fill"
        case "LIFE_ALERT":
            return "exclamationmark.triangle.fill"
        default:
            return "bell.fill"
        }
    }
    
    /// Title with fallback
    var displayTitle: String {
        subject ?? type.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    /// Body preview with fallback
    var displayBody: String {
        preview ?? "Tap to view details"
    }
}

// MARK: - API Responses

struct NotificationListResponse: Codable {
    let notifications: [NotificationItem]
    let totalCount: Int
    let page: Int
    let pageSize: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case notifications
        case totalCount = "total_count"
        case page
        case pageSize = "page_size"
        case hasMore = "has_more"
    }
}

struct UnreadCountResponse: Codable {
    let count: Int
}

struct MarkReadResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let backendFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
}
