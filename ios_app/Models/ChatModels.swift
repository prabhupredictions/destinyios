import Foundation
import SwiftData

// MARK: - Message Role
enum MessageRole: String, Codable, Sendable, CaseIterable {
    case user
    case assistant
    case system
}

// MARK: - Local Chat Message (SwiftData Model for persistence)
@Model
final class LocalChatMessage {
    @Attribute(.unique) var id: String
    var threadId: String
    var role: String  // MessageRole raw value
    var content: String
    var area: String?  // Life area (marriage, career, etc.)
    var confidence: String?  // e.g., "82%"
    var traceId: String?  // Link to reasoning trace
    var toolCalls: [String]  // Tool call previews (non-optional)
    var sources: [String]  // References (non-optional)
    var createdAt: Date
    var isStreaming: Bool
    var executionTimeMs: Double = 0  // Prediction execution time in milliseconds
    var rating: Int? // User rating (1-5)
    
    init(
        id: String = UUID().uuidString,
        threadId: String,
        role: MessageRole,
        content: String,
        area: String? = nil,
        confidence: String? = nil,
        traceId: String? = nil,
        toolCalls: [String] = [],
        sources: [String] = [],
        createdAt: Date = Date(),
        isStreaming: Bool = false,
        executionTimeMs: Double = 0,
        rating: Int? = nil
    ) {
        self.id = id
        self.threadId = threadId
        self.role = role.rawValue
        self.content = content
        self.area = area
        self.confidence = confidence
        self.traceId = traceId
        self.toolCalls = toolCalls
        self.sources = sources
        self.createdAt = createdAt
        self.isStreaming = isStreaming
        self.executionTimeMs = executionTimeMs
        self.rating = rating
    }
    
    var messageRole: MessageRole {
        MessageRole(rawValue: role) ?? .user
    }
}

// MARK: - Local Chat Thread (SwiftData Model for persistence)
@Model
final class LocalChatThread {
    @Attribute(.unique) var id: String
    var sessionId: String
    var userEmail: String
    var profileId: String?  // Switch Profile feature - scopes thread to specific profile
    var title: String
    var preview: String
    var primaryArea: String?
    var areasDiscussed: [String]
    var messageCount: Int
    var isArchived: Bool
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        sessionId: String,
        userEmail: String,
        profileId: String? = nil,
        title: String = "New Conversation",
        preview: String = "",
        primaryArea: String? = nil,
        areasDiscussed: [String] = [],
        messageCount: Int = 0,
        isArchived: Bool = false,
        isPinned: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.sessionId = sessionId
        self.userEmail = userEmail
        self.profileId = profileId
        self.title = title
        self.preview = preview
        self.primaryArea = primaryArea
        self.areasDiscussed = areasDiscussed
        self.messageCount = messageCount
        self.isArchived = isArchived
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func updateFromMessages(_ messages: [LocalChatMessage]) {
        // Only update title if it's a generic title ("New Conversation") or empty
        // NEVER overwrite "Match:" titles from compatibility results
        let shouldUpdateTitle = title.isEmpty || 
                                title == "New Conversation" || 
                                title == "Conversation"
        
        if shouldUpdateTitle, let first = messages.first(where: { $0.messageRole == .user }) {
            title = String(first.content.prefix(40))
        }
        if let last = messages.last {
            preview = String(last.content.prefix(60))
            updatedAt = last.createdAt
        }
        // Only count user messages (not AI welcome/response messages)
        messageCount = messages.filter { $0.messageRole == .user }.count
    }
}

// MARK: - User Session (SwiftData Model)
@Model
final class UserSession {
    @Attribute(.unique) var sessionId: String
    var userEmail: String
    var birthDataHash: String?  // For linking same chart
    var createdAt: Date
    var lastAccessed: Date
    var expiresAt: Date
    var isActive: Bool
    
    // Cached preferences
    var historyEnabled: Bool
    var saveConversations: Bool
    var groupByDate: Bool
    
    init(
        sessionId: String = UUID().uuidString,
        userEmail: String,
        birthDataHash: String? = nil,
        createdAt: Date = Date(),
        lastAccessed: Date = Date(),
        expiresAt: Date = Date().addingTimeInterval(30 * 24 * 60 * 60), // 30 days
        isActive: Bool = true,
        historyEnabled: Bool = true,
        saveConversations: Bool = true,
        groupByDate: Bool = true
    ) {
        self.sessionId = sessionId
        self.userEmail = userEmail
        self.birthDataHash = birthDataHash
        self.createdAt = createdAt
        self.lastAccessed = lastAccessed
        self.expiresAt = expiresAt
        self.isActive = isActive
        self.historyEnabled = historyEnabled
        self.saveConversations = saveConversations
        self.groupByDate = groupByDate
    }
}
