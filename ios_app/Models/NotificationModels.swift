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
    let actionUrl: String?
    let imageUrl: String?
    let chatPrompt: String?
    let topic: String?
    let overallTone: String?

    enum CodingKeys: String, CodingKey {
        case id, type, channel, subject, preview, status, read, topic
        case createdAt   = "created_at"
        case readAt      = "read_at"
        case actionUrl   = "action_url"
        case imageUrl    = "image_url"
        case chatPrompt  = "chat_prompt"
        case overallTone = "overall_tone"
    }

    // MARK: - Computed Properties

    /// Parsed creation date
    var createdDate: Date? {
        guard let createdAt else { return nil }
        return ISO8601DateFormatter().date(from: createdAt) ??
               DateFormatter.backendFormatter.date(from: createdAt)
    }

    /// Exact date: "May 17, 2026"
    var timeAgo: String {
        guard let date = createdDate else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, yyyy"
        return fmt.string(from: date)
    }

    /// Relative time display ("2h ago", "Yesterday at 3:14 PM"). Falls
    /// back to absolute date for items older than 7 days.
    var relativeTime: String {
        guard let date = createdAtDate else { return "" }
        let now = Date()
        let interval = now.timeIntervalSince(date)
        if interval < 60 {
            return NSLocalizedString("notif_just_now", value: "Just now", comment: "")
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        if interval < 86_400 * 7 {
            return formatter.localizedString(for: date, relativeTo: now)
        }
        let abs = DateFormatter()
        abs.dateStyle = .medium
        return abs.string(from: date)
    }

    /// Date bucket for grouping in the inbox list.
    var inboxBucket: InboxBucket {
        guard let date = createdAtDate else { return .earlier }
        let cal = Calendar.current
        if cal.isDateInToday(date) { return .today }
        if cal.isDateInYesterday(date) { return .yesterday }
        let weekOfYear = cal.component(.weekOfYear, from: date)
        let nowWeek = cal.component(.weekOfYear, from: Date())
        let year = cal.component(.year, from: date)
        let nowYear = cal.component(.year, from: Date())
        if year == nowYear && weekOfYear == nowWeek { return .thisWeek }
        if year == nowYear && weekOfYear == nowWeek - 1 { return .lastWeek }
        return .earlier
    }

    private var createdAtDate: Date? {
        guard let createdAt else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = isoFormatter.date(from: createdAt) { return d }
        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: createdAt)
    }

    /// True if the notification was created today
    var isToday: Bool {
        guard let date = createdDate else { return false }
        return Calendar.current.isDateInToday(date)
    }

    /// Icon name based on notification type
    var iconName: String {
        switch type.uppercased() {
        case "DAILY_PREDICTION", "DAILY_PREDICTION_READY": return "sun.max.fill"
        case "TRANSIT_ALERT":          return "sparkles"
        case "SUBSCRIPTION_EXPIRING":  return "creditcard.fill"
        case "WELCOME":                return "star.fill"
        case "LIFE_ALERT":             return "exclamationmark.triangle.fill"
        case "COMPATIBILITY_READY":    return "heart.fill"
        case "CUSTOM_ALERT":           return "bell.badge.fill"
        default:                       return "bell.fill"
        }
    }

    /// Short chip label for the life area topic
    var topicChip: String? {
        guard let t = topic, !t.isEmpty, t != "general" else { return nil }
        return t.replacingOccurrences(of: "_", with: " ").capitalized
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

// MARK: - Inbox Bucket

enum InboxBucket: Int, CaseIterable, Comparable {
    case today, yesterday, thisWeek, lastWeek, earlier
    var localizedLabel: String {
        switch self {
        case .today:     return NSLocalizedString("notif_section_today",     value: "Today",     comment: "")
        case .yesterday: return NSLocalizedString("notif_section_yesterday", value: "Yesterday", comment: "")
        case .thisWeek:  return NSLocalizedString("notif_section_this_week", value: "This Week", comment: "")
        case .lastWeek:  return NSLocalizedString("notif_section_last_week", value: "Last Week", comment: "")
        case .earlier:   return NSLocalizedString("notif_section_earlier",   value: "Earlier",   comment: "")
        }
    }
    static func < (lhs: InboxBucket, rhs: InboxBucket) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
