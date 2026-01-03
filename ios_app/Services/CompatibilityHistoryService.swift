import Foundation

// MARK: - Compatibility History Service
/// Manages persistence of compatibility match history using UserDefaults
/// All data is stored per-user to prevent data mixing between accounts
final class CompatibilityHistoryService {
    
    // MARK: - Constants
    private static let storageKeyPrefix = "compatibility_history_"
    private static let maxItems = 10
    
    // MARK: - Singleton
    static let shared = CompatibilityHistoryService()
    private init() {}
    
    /// Get current user's email for storage key
    private var currentUserEmail: String {
        UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
    }
    
    /// Get storage key for current user
    private var storageKey: String {
        "\(Self.storageKeyPrefix)\(currentUserEmail)"
    }
    
    // MARK: - Load All
    /// Loads all saved history items for current user, sorted by most recent first
    func loadAll() -> [CompatibilityHistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }
        
        do {
            let items = try JSONDecoder().decode([CompatibilityHistoryItem].self, from: data)
            return items.sorted { $0.timestamp > $1.timestamp }
        } catch {
            print("[CompatibilityHistoryService] Failed to decode history for \(currentUserEmail): \(error)")
            return []
        }
    }
    
    // MARK: - Save
    /// Saves a new history item for current user. If session already exists, updates it.
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
        print("[CompatibilityHistoryService] updateChatMessages called for sessionId: '\(sessionId)', messageCount: \(messages.count)")
        var items = loadAll()
        print("[CompatibilityHistoryService] Loaded \(items.count) items. SessionIds: \(items.map { $0.sessionId })")
        
        if let index = items.firstIndex(where: { $0.sessionId == sessionId }) {
            print("[CompatibilityHistoryService] FOUND sessionId at index \(index), updating...")
            // Convert messages to Codable format
            let messageData = messages.map { CompatChatMessageData(from: $0) }
            items[index].chatMessages = messageData
            persist(items)
            print("[CompatibilityHistoryService] Persisted \(messageData.count) messages")
        } else {
            print("[CompatibilityHistoryService] WARNING: sessionId '\(sessionId)' NOT FOUND in stored items!")
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
    /// Clears all history for current user
    func clearAll() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        print("[CompatibilityHistoryService] Cleared history for \(currentUserEmail)")
    }
    
    /// Clears all history for a specific user (used on logout)
    func clearAll(forUser email: String) {
        let key = "\(Self.storageKeyPrefix)\(email)"
        UserDefaults.standard.removeObject(forKey: key)
        print("[CompatibilityHistoryService] Cleared history for \(email)")
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
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("[CompatibilityHistoryService] Failed to encode history: \(error)")
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
            
            // Fetch full details for each thread and convert to local format
            for thread in compatThreads {
                // Skip if already exists locally
                if get(sessionId: thread.id) != nil {
                    continue
                }
                
                // Fetch thread details with metadata
                let threadDetailURL = URL(string: "\(APIConfig.baseURL)/chat-history/threads/\(userEmail)/\(thread.id)")
                guard let detailURL = threadDetailURL else { continue }
                
                var detailRequest = URLRequest(url: detailURL)
                detailRequest.httpMethod = "GET"
                detailRequest.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
                
                do {
                    let (detailData, detailResponse) = try await URLSession.shared.data(for: detailRequest)
                    
                    guard let httpDetailResponse = detailResponse as? HTTPURLResponse,
                          httpDetailResponse.statusCode == 200 else {
                        print("[CompatibilityHistoryService] Failed to fetch details for \(thread.id)")
                        continue
                    }
                    
                    // Parse thread detail with metadata and messages
                    struct MessageItem: Codable {
                        let id: String?  // Changed from Int? - backend returns string
                        let role: String
                        let content: String
                        let createdAt: String?
                        
                        enum CodingKeys: String, CodingKey {
                            case id, role, content
                            case createdAt = "created_at"
                        }
                    }
                    
                    struct ThreadDetailResponse: Codable {
                        let id: String
                        let title: String?
                        let metadata: CompatibilityResponse?
                        let messages: [MessageItem]?
                        let createdAt: String?
                        let updatedAt: String?
                        
                        enum CodingKeys: String, CodingKey {
                            case id, title, metadata, messages
                            case createdAt = "created_at"
                            case updatedAt = "updated_at"
                        }
                    }
                    
                    let threadDetail = try JSONDecoder().decode(ThreadDetailResponse.self, from: detailData)
                    
                    // Extract data from metadata
                    var boyName = "Partner"
                    var girlName = "Partner"
                    var boyDob = ""
                    var girlDob = ""
                    var boyCity = ""
                    var girlCity = ""
                    var totalScore = 0
                    var kutas: [KutaDetail] = []
                    var result: CompatibilityResult? = nil
                    
                    if let metadata = threadDetail.metadata {
                        // Parse names from title
                        if let title = threadDetail.title, title.contains("&") {
                            let parts = title.replacingOccurrences(of: "Match: ", with: "").components(separatedBy: " & ")
                            if parts.count == 2 {
                                boyName = parts[0]
                                girlName = parts[1]
                            }
                        }
                        
                        // Extract birth details from analysisData
                        if let analysisData = metadata.analysisData {
                            if let boyDetails = analysisData.boy?.details {
                                boyDob = boyDetails.dob
                                boyCity = boyDetails.place  // BirthDetails uses 'place' not 'city'
                            }
                            if let girlDetails = analysisData.girl?.details {
                                girlDob = girlDetails.dob
                                girlCity = girlDetails.place  // BirthDetails uses 'place' not 'city'
                            }
                            // Extract score from ashtakoot (Dictionary access)
                            if let ashtakoot = analysisData.joint?.ashtakootMatching,
                               let scoreValue = ashtakoot["total_score"]?.value {
                                if let scoreInt = scoreValue as? Int {
                                    totalScore = scoreInt
                                } else if let scoreDouble = scoreValue as? Double {
                                    totalScore = Int(scoreDouble)
                                }
                            }
                            
                            // Build kutas array from ashtakootMatching.guna_scores
                            if let ashtakoot = analysisData.joint?.ashtakootMatching {
                                // Same structure as CompatibilityViewModel
                                if let gunaScores = ashtakoot["guna_scores"]?.value as? [String: Any] {
                                    let kutaNames: [(String, String, Int)] = [
                                        ("varna", "Varna", 1),
                                        ("vashya", "Vashya", 2),
                                        ("tara", "Tara", 3),
                                        ("yoni", "Yoni", 4),
                                        ("maitri", "Maitri", 5),
                                        ("gana", "Gana", 6),
                                        ("bhakoot", "Bhakoot", 7),
                                        ("nadi", "Nadi", 8)
                                    ]
                                    
                                    for (key, name, maxPoints) in kutaNames {
                                        if let kutaData = gunaScores[key] as? [String: Any],
                                           let score = kutaData["score"] as? Int {
                                            kutas.append(KutaDetail(name: name, maxPoints: maxPoints, points: score))
                                        } else if let kutaData = gunaScores[key] as? [String: Any],
                                                  let score = kutaData["score"] as? Double {
                                            kutas.append(KutaDetail(name: name, maxPoints: maxPoints, points: Int(score)))
                                        }
                                    }
                                    print("[CompatibilityHistoryService] Built \(kutas.count) kutas from guna_scores")
                                } else {
                                    print("[CompatibilityHistoryService] No guna_scores found in ashtakootMatching")
                                }
                            }
                        }
                        
                        // Create CompatibilityResult from metadata using proper init
                        result = CompatibilityResult(
                            totalScore: totalScore,
                            maxScore: 36,
                            kutas: kutas,  // Now populated from ashtakootMatching
                            summary: metadata.llmAnalysis ?? "",
                            recommendation: totalScore >= 18 ? "Favorable for marriage" : "Additional remedies may be helpful",
                            analysisData: metadata.analysisData,
                            sessionId: metadata.sessionId
                        )
                    }
                    
                    // Convert backend messages to local format
                    var restoredMessages: [CompatChatMessageData] = []
                    if let backendMessages = threadDetail.messages {
                        for msg in backendMessages {
                            let chatMsg = CompatChatMessageData(
                                id: UUID().uuidString,
                                content: msg.content,
                                isUser: msg.role == "user",
                                timestamp: ISO8601DateFormatter().date(from: msg.createdAt ?? "") ?? Date(),
                                type: msg.role == "user" ? "user" : "ai"
                            )
                            restoredMessages.append(chatMsg)
                        }
                        print("[CompatibilityHistoryService] Restored \(restoredMessages.count) chat messages from server")
                    }
                    
                    // Create full history item
                    let item = CompatibilityHistoryItem(
                        sessionId: thread.id,
                        timestamp: ISO8601DateFormatter().date(from: threadDetail.createdAt ?? thread.createdAt) ?? Date(),
                        boyName: boyName,
                        boyDob: boyDob,
                        boyCity: boyCity,
                        girlName: girlName,
                        girlDob: girlDob,
                        girlCity: girlCity,
                        totalScore: totalScore,
                        maxScore: 36,
                        result: result,
                        chatMessages: restoredMessages
                    )
                    
                    save(item)
                    print("[CompatibilityHistoryService] Restored full history: \(thread.id)")
                    
                } catch {
                    print("[CompatibilityHistoryService] Failed to parse thread \(thread.id): \(error)")
                }
            }
            
            print("[CompatibilityHistoryService] Sync complete")
            
        } catch {
            print("[CompatibilityHistoryService] Sync error: \(error)")
        }
    }
}
