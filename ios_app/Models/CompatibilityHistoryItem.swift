import Foundation

// MARK: - Compatibility History Item
/// Represents a saved compatibility match for history
struct CompatibilityHistoryItem: Codable, Identifiable, Equatable {
    var id: String { sessionId }
    
    static func == (lhs: CompatibilityHistoryItem, rhs: CompatibilityHistoryItem) -> Bool {
        lhs.sessionId == rhs.sessionId
    }
    
    let sessionId: String
    let timestamp: Date
    
    // Partner details
    let boyName: String
    let boyDob: String
    let boyCity: String
    let girlName: String
    let girlDob: String
    let girlCity: String
    
    // Score
    let totalScore: Int
    let maxScore: Int
    
    // Full result for restore
    let result: CompatibilityResult?
    
    // Chat messages from Ask Destiny
    var chatMessages: [CompatChatMessageData]
    
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
