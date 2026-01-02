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
        let messageCount: Int
        let isPinned: Bool
        let isArchived: Bool
        let createdAt: String
        let updatedAt: String
        let dateGroup: String?
        
        enum CodingKeys: String, CodingKey {
            case id, title, preview
            case primaryArea = "primary_area"
            case messageCount = "message_count"
            case isPinned = "is_pinned"
            case isArchived = "is_archived"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case dateGroup = "date_group"
        }
    }
    
    struct ThreadDetailResponse: Codable {
        let id: String
        let title: String?
        let preview: String?
        let primaryArea: String?
        let messageCount: Int
        let isPinned: Bool
        let isArchived: Bool
        let createdAt: String
        let updatedAt: String
        let messages: [MessageResponse]
        let areasDiscussed: [String]
        let hasBirthData: Bool
        
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
        
        enum CodingKeys: String, CodingKey {
            case id, role, content, area, confidence, sources
            case traceId = "trace_id"
            case toolCalls = "tool_calls"
            case createdAt = "created_at"
        }
    }
    
    // MARK: - Sync Methods
    
    /// Fetch all threads from server for a user
    func fetchThreads(userEmail: String) async throws -> [ThreadResponse] {
        let urlString = "\(baseURL)/chat-history/threads/\(userEmail)"
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
    func syncFromServer(userEmail: String, dataManager: DataManager) async {
        print("[ChatHistorySync] Starting sync for \(userEmail)")
        
        do {
            // 1. Fetch all threads
            let threads = try await fetchThreads(userEmail: userEmail)
            print("[ChatHistorySync] Found \(threads.count) threads")
            
            // 2. For each thread, fetch messages and save locally
            for thread in threads {
                if let detail = try await fetchThreadDetail(threadId: thread.id, userEmail: userEmail) {
                    // Save thread locally
                    let localThread = LocalChatThread(
                        id: thread.id,
                        sessionId: thread.id,  // Use thread ID as session
                        userEmail: userEmail,
                        title: thread.title ?? "Conversation",
                        preview: thread.preview ?? "",
                        primaryArea: thread.primaryArea,
                        areasDiscussed: detail.areasDiscussed,
                        messageCount: thread.messageCount,
                        isArchived: thread.isArchived,
                        isPinned: thread.isPinned,
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
                            isStreaming: false
                        )
                        dataManager.saveMessage(localMessage)
                    }
                }
            }
            
            print("[ChatHistorySync] Sync complete - \(threads.count) threads synced")
            
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
