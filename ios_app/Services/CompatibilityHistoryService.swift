import Foundation

// MARK: - Compatibility History Service
/// Manages persistence of compatibility match history using UserDefaults
final class CompatibilityHistoryService {
    
    // MARK: - Constants
    private static let storageKey = "compatibility_match_history"
    private static let maxItems = 10
    
    // MARK: - Singleton
    static let shared = CompatibilityHistoryService()
    private init() {}
    
    // MARK: - Load All
    /// Loads all saved history items, sorted by most recent first
    func loadAll() -> [CompatibilityHistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else {
            return []
        }
        
        do {
            let items = try JSONDecoder().decode([CompatibilityHistoryItem].self, from: data)
            return items.sorted { $0.timestamp > $1.timestamp }
        } catch {
            print("[HistoryService] Failed to decode history: \(error)")
            return []
        }
    }
    
    // MARK: - Save
    /// Saves a new history item. If session already exists, updates it.
    func save(_ item: CompatibilityHistoryItem) {
        var items = loadAll()
        
        // Check for duplicate
        if let existingIndex = items.firstIndex(where: { $0.sessionId == item.sessionId }) {
            // Update existing
            items[existingIndex] = item
        } else {
            // Insert at beginning (most recent)
            items.insert(item, at: 0)
        }
        
        // Limit to maxItems
        if items.count > Self.maxItems {
            items = Array(items.prefix(Self.maxItems))
        }
        
        persist(items)
    }
    
    // MARK: - Update Chat Messages
    /// Updates chat messages for an existing session
    func updateChatMessages(sessionId: String, messages: [CompatChatMessage]) {
        var items = loadAll()
        
        if let index = items.firstIndex(where: { $0.sessionId == sessionId }) {
            // Convert messages to Codable format
            let messageData = messages.map { CompatChatMessageData(from: $0) }
            items[index].chatMessages = messageData
            persist(items)
        }
    }
    
    // MARK: - Delete Single
    /// Deletes a single history item by session ID
    func delete(sessionId: String) {
        var items = loadAll()
        items.removeAll { $0.sessionId == sessionId }
        persist(items)
    }
    
    // MARK: - Delete Multiple
    /// Deletes multiple history items by session IDs
    func delete(sessionIds: Set<String>) {
        var items = loadAll()
        items.removeAll { sessionIds.contains($0.sessionId) }
        persist(items)
    }
    
    // MARK: - Clear All
    /// Clears all history
    func clearAll() {
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }
    
    // MARK: - Get Item
    /// Gets a single history item by session ID
    func get(sessionId: String) -> CompatibilityHistoryItem? {
        loadAll().first { $0.sessionId == sessionId }
    }
    
    // MARK: - Private Helpers
    private func persist(_ items: [CompatibilityHistoryItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            print("[HistoryService] Failed to encode history: \(error)")
        }
    }
    
    // MARK: - Sync from Server
    /// Syncs compatibility history from backend chat-history (for recovery after iOS clear)
    func syncFromServer(userEmail: String) async {
        print("[CompatibilityHistoryService] Starting sync for \(userEmail)")
        
        let urlString = "\(APIConfig.baseURL)/chat-history/threads/\(userEmail)"
        guard let url = URL(string: urlString) else {
            print("[CompatibilityHistoryService] Invalid URL")
            return
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("[CompatibilityHistoryService] Server returned non-200")
                return
            }
            
            // Parse threads response
            struct ThreadsResponse: Codable {
                let threads: [ThreadInfo]
            }
            struct ThreadInfo: Codable {
                let id: String
                let title: String?
                let preview: String?
                let primaryArea: String?
                let createdAt: String
                
                enum CodingKeys: String, CodingKey {
                    case id, title, preview
                    case primaryArea = "primary_area"
                    case createdAt = "created_at"
                }
            }
            
            let threadsResponse = try JSONDecoder().decode(ThreadsResponse.self, from: data)
            
            // Filter for compatibility threads
            let compatThreads = threadsResponse.threads.filter { 
                ($0.primaryArea == "compatibility") || ($0.id.hasPrefix("compat_"))
            }
            
            print("[CompatibilityHistoryService] Found \(compatThreads.count) compatibility threads")
            
            // Convert to local format and merge with existing
            for thread in compatThreads {
                // Parse names from title if available (format: "Match: Name1 & Name2")
                var boyName = "Partner"
                var girlName = "Partner"
                if let title = thread.title, title.contains("&") {
                    let parts = title.replacingOccurrences(of: "Match: ", with: "").components(separatedBy: " & ")
                    if parts.count == 2 {
                        boyName = parts[0]
                        girlName = parts[1]
                    }
                }
                
                // Create minimal history item (full details from server not available without fetching each thread)
                let item = CompatibilityHistoryItem(
                    sessionId: thread.id,
                    timestamp: ISO8601DateFormatter().date(from: thread.createdAt) ?? Date(),
                    boyName: boyName,
                    boyDob: "",  // Not available from thread list
                    boyCity: "",
                    girlName: girlName,
                    girlDob: "",
                    girlCity: "",
                    totalScore: 0,
                    maxScore: 36,
                    result: nil,  // Not available from thread list
                    chatMessages: []
                )
                
                // Only add if not already exists
                if get(sessionId: thread.id) == nil {
                    save(item)
                }
            }
            
            print("[CompatibilityHistoryService] Sync complete")
            
        } catch {
            print("[CompatibilityHistoryService] Sync error: \(error)")
        }
    }
}
