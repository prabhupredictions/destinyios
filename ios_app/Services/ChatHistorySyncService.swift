import Foundation

/// Service to sync chat history from server to local storage
/// Similar pattern to ProfileService for subscription sync
@MainActor
class ChatHistorySyncService {
    static let shared = ChatHistorySyncService()
    
    private let baseURL = APIConfig.baseURL
    
    // MARK: - API Response Models
    
    struct ThreadListResponse: Codable {
        let threads: [ThreadResponse]
        let totalCount: Int
        let today: [ThreadResponse]?
        let yesterday: [ThreadResponse]?
        let thisWeek: [ThreadResponse]?
        let thisMonth: [ThreadResponse]?
        let older: [ThreadResponse]?
        
        enum CodingKeys: String, CodingKey {
            case threads
            case totalCount = "total_count"
            case today, yesterday
            case thisWeek = "this_week"
            case thisMonth = "this_month"
            case older
        }
    }
    
    struct ThreadResponse: Codable {
        let id: String
        let title: String?
        let preview: String?
        let primaryArea: String?
        let messageCount: Int?
        let isPinned: Bool?
        let isArchived: Bool?
        let createdAt: String
        let updatedAt: String
        let dateGroup: String?
        let profileId: String?  // For Switch Profile feature
        
        enum CodingKeys: String, CodingKey {
            case id, title, preview
            case primaryArea = "primary_area"
            case messageCount = "message_count"
            case isPinned = "is_pinned"
            case isArchived = "is_archived"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case dateGroup = "date_group"
            case profileId = "profile_id"
        }
    }
    
    struct ThreadDetailResponse: Codable {
        let id: String
        let title: String?
        let preview: String?
        let primaryArea: String?
        let messageCount: Int?
        let isPinned: Bool?
        let isArchived: Bool?
        let createdAt: String
        let updatedAt: String
        let messages: [MessageResponse]
        let areasDiscussed: [String]?
        let hasBirthData: Bool?
        
        enum CodingKeys: String, CodingKey {
            case id, title, preview, messages
            case primaryArea = "primary_area"
            case messageCount = "message_count"
            case isPinned = "is_pinned"
            case isArchived = "is_archived"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case areasDiscussed = "areas_discussed"
            case hasBirthData = "has_birth_data"
        }
    }
    
    struct MessageResponse: Codable {
        let id: String
        let role: String
        let content: String
        let area: String?
        let confidence: String?
        let traceId: String?
        let toolCalls: [[String: String]]?
        let sources: [String]?
        let createdAt: String
        let rating: Int?
        
        enum CodingKeys: String, CodingKey {
            case id, role, content, area, confidence, sources, rating
            case traceId = "trace_id"
            case toolCalls = "tool_calls"
            case createdAt = "created_at"
        }
    }
    
    // MARK: - Sync Methods
    
    /// Fetch all threads from server for a user (optionally filtered by profile)
    func fetchThreads(userEmail: String, profileId: String? = nil) async throws -> [ThreadResponse] {
        var urlString = "\(baseURL)/chat-history/threads/\(userEmail)"
        
        // Add profile_id filter if provided
        if let profileId = profileId {
            urlString += "?profile_id=\(profileId)"
        }
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("[ChatHistorySync] Failed to fetch threads: \(response)")
            return []
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(ThreadListResponse.self, from: data)
        return result.threads
    }
    
    /// Fetch messages for a specific thread
    func fetchThreadDetail(threadId: String, userEmail: String) async throws -> ThreadDetailResponse? {
        let urlString = "\(baseURL)/chat-history/threads/\(userEmail)/\(threadId)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("[ChatHistorySync] Failed to fetch thread detail: \(response)")
            return nil
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(ThreadDetailResponse.self, from: data)
    }
    
    /// Sync all chat history from server to local SwiftData
    /// Fetches ALL threads for the user email (not filtered by profile) for client-side filtering
    /// NOTE: Clears existing local threads first to prevent duplicates from ID mismatch
    func syncFromServer(userEmail: String, dataManager: DataManager) async {
        print("[ChatHistorySync] Starting full sync for \(userEmail)")
        
        do {
            // 0. CRITICAL: Clear existing local threads for this user to prevent duplicates
            // Local messages have client-generated UUIDs, server has server-generated UUIDs
            // Deduplication by ID fails when IDs don't match, causing duplicates
            dataManager.deleteAllThreads(for: userEmail)
            print("[ChatHistorySync] Cleared local threads for \(userEmail) before sync")
            
            // 1. Fetch ALL threads for user (no profile filter - client-side filtering)
            let threads = try await fetchThreads(userEmail: userEmail, profileId: nil)
            print("[ChatHistorySync] Found \(threads.count) total threads for \(userEmail)")
            
            // 2. For each thread, fetch messages and save locally
            for thread in threads {
                if let detail = try await fetchThreadDetail(threadId: thread.id, userEmail: userEmail) {
                    // Save thread locally
                    let localThread = LocalChatThread(
                        id: thread.id,
                        sessionId: thread.id,  // Use thread ID as session
                        userEmail: userEmail,
                        profileId: thread.profileId,  // Switch Profile feature
                        title: thread.title ?? "Conversation",
                        preview: thread.preview ?? "",
                        primaryArea: thread.primaryArea,
                        areasDiscussed: detail.areasDiscussed ?? [],
                        messageCount: thread.messageCount ?? 0,
                        isArchived: thread.isArchived ?? false,
                        isPinned: thread.isPinned ?? false,
                        createdAt: parseDate(thread.createdAt),
                        updatedAt: parseDate(thread.updatedAt)
                    )
                    dataManager.saveThread(localThread)
                    
                    // Save messages locally
                    for message in detail.messages {
                        let toolCallStrings = message.toolCalls?.compactMap { dict -> String? in
                            return dict["name"] ?? dict["tool"]
                        } ?? []
                        
                        let localMessage = LocalChatMessage(
                            id: message.id,
                            threadId: thread.id,
                            role: MessageRole(rawValue: message.role) ?? .assistant,
                            content: message.content,
                            area: message.area,
                            confidence: message.confidence,
                            traceId: message.traceId,
                            toolCalls: toolCallStrings,
                            sources: message.sources ?? [],
                            createdAt: parseDate(message.createdAt),
                            isStreaming: false,
                            rating: message.rating
                        )
                        dataManager.saveMessage(localMessage)
                    }
                }
            }
            
            print("[ChatHistorySync] Sync complete - \(threads.count) threads synced for \(userEmail)")
            
        } catch {
            print("[ChatHistorySync] Error: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    private func parseDate(_ dateString: String) -> Date {
        let formatters = [
            ISO8601DateFormatter(),
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        // Fallback: try standard date formatter
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        if let date = df.date(from: dateString) {
            return date
        }
        
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = df.date(from: dateString) {
            return date
        }
        
        return Date()
    }
}
