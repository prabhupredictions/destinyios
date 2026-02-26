import Foundation

// MARK: - Compatibility History Item
/// Represents a saved compatibility match for history
struct CompatibilityHistoryItem: Codable, Identifiable, Equatable {
    var id: String { sessionId }
    
    static func == (lhs: CompatibilityHistoryItem, rhs: CompatibilityHistoryItem) -> Bool {
        lhs.sessionId == rhs.sessionId
    }
    
    let sessionId: String
    var timestamp: Date
    
    // Multi-Partner Grouping (nil for single-partner matches)
    let comparisonGroupId: String?
    let partnerIndex: Int?  // Order within group (0 = first partner)
    
    // Partner details (DOB in yyyy-MM-dd, time in HH:mm:ss — matches API format)
    let boyName: String
    let boyDob: String
    let boyTime: String
    let boyCity: String
    let girlName: String
    let girlDob: String
    let girlTime: String
    let girlCity: String
    
    // Score
    var totalScore: Int
    var maxScore: Int
    
    // Full result for restore
    var result: CompatibilityResult?
    
    // Chat messages from Ask Destiny
    var chatMessages: [CompatChatMessageData]
    
    // Pin status
    var isPinned: Bool
    
    // MARK: - Computed Properties
    
    var displayTitle: String {
        "\(boyName) & \(girlName)"
    }
    
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var scorePercentage: Double {
        guard maxScore > 0 else { return 0 }
        return Double(totalScore) / Double(maxScore) * 100
    }
    
    /// Whether this item is part of a multi-partner comparison group
    var isInGroup: Bool {
        comparisonGroupId != nil
    }
    
    init(
        sessionId: String,
        timestamp: Date,
        boyName: String,
        boyDob: String,
        boyTime: String,
        boyCity: String,
        girlName: String,
        girlDob: String,
        girlTime: String,
        girlCity: String,
        totalScore: Int,
        maxScore: Int,
        result: CompatibilityResult?,
        chatMessages: [CompatChatMessageData],
        comparisonGroupId: String? = nil,
        partnerIndex: Int? = nil,
        isPinned: Bool = false
    ) {
        self.sessionId = sessionId
        self.timestamp = timestamp
        self.comparisonGroupId = comparisonGroupId
        self.partnerIndex = partnerIndex
        self.boyName = boyName
        self.boyDob = boyDob
        self.boyTime = boyTime
        self.boyCity = boyCity
        self.girlName = girlName
        self.girlDob = girlDob
        self.girlTime = girlTime
        self.girlCity = girlCity
        self.totalScore = totalScore
        self.maxScore = maxScore
        self.result = result
        self.chatMessages = chatMessages
        self.isPinned = isPinned
    }
    
    // Custom decoder for backwards compatibility (existing items lack isPinned)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        comparisonGroupId = try container.decodeIfPresent(String.self, forKey: .comparisonGroupId)
        partnerIndex = try container.decodeIfPresent(Int.self, forKey: .partnerIndex)
        boyName = try container.decode(String.self, forKey: .boyName)
        boyDob = try container.decode(String.self, forKey: .boyDob)
        boyTime = try container.decode(String.self, forKey: .boyTime)
        boyCity = try container.decode(String.self, forKey: .boyCity)
        girlName = try container.decode(String.self, forKey: .girlName)
        girlDob = try container.decode(String.self, forKey: .girlDob)
        girlTime = try container.decode(String.self, forKey: .girlTime)
        girlCity = try container.decode(String.self, forKey: .girlCity)
        totalScore = try container.decode(Int.self, forKey: .totalScore)
        maxScore = try container.decode(Int.self, forKey: .maxScore)
        result = try container.decodeIfPresent(CompatibilityResult.self, forKey: .result)
        chatMessages = try container.decode([CompatChatMessageData].self, forKey: .chatMessages)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }
}

// MARK: - Comparison Group
/// Represents a group of related compatibility matches (1 user vs N partners)
struct ComparisonGroup: Identifiable, Equatable {
    static func == (lhs: ComparisonGroup, rhs: ComparisonGroup) -> Bool {
        lhs.id == rhs.id
    }
    let id: String  // groupId
    let timestamp: Date
    let userName: String
    let items: [CompatibilityHistoryItem]
    var isPinned: Bool = false
    
    // MARK: - Computed Properties
    
    var partnerCount: Int {
        items.count
    }
    
    var displayTitle: String {
        if partnerCount == 1 {
            return items.first?.displayTitle ?? "Match"
        } else {
            return "\(userName) + \(partnerCount) partners"
        }
    }
    
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var bestMatch: CompatibilityHistoryItem? {
        items.max(by: { $0.totalScore < $1.totalScore })
    }
    
    var averageScore: Double {
        guard !items.isEmpty else { return 0 }
        let total = items.reduce(0) { $0 + $1.totalScore }
        return Double(total) / Double(items.count)
    }
    
    var sortedItems: [CompatibilityHistoryItem] {
        items.sorted { $0.totalScore > $1.totalScore }
    }
}

// MARK: - Chat Message Data (Codable version)
/// Codable version of CompatChatMessage for storage
struct CompatChatMessageData: Codable, Identifiable {
    let id: String
    let content: String
    let isUser: Bool
    let timestamp: Date
    let type: String  // "user", "ai", "info", "error"
    
    // Memberwise initializer for direct instantiation
    init(id: String, content: String, isUser: Bool, timestamp: Date, type: String = "ai") {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.type = type
    }
    
    init(from message: CompatChatMessage) {
        self.id = message.id.uuidString
        self.content = message.content
        self.isUser = message.isUser
        self.timestamp = message.timestamp
        self.type = message.type.rawValue
    }
    
    func toMessage() -> CompatChatMessage {
        CompatChatMessage(
            content: content,
            isUser: isUser,
            type: CompatChatMessage.MessageType(rawValue: type) ?? .ai
        )
    }
}
