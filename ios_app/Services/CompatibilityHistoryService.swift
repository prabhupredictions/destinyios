import Foundation

// MARK: - Compatibility History Service
/// Manages persistence of compatibility match history using UserDefaults
/// All data is stored per-user-per-profile to prevent data mixing between profiles
final class CompatibilityHistoryService {
    
    // MARK: - Constants
    private static let storageKeyPrefix = "compatibility_history"
    private static let maxItems = 10
    
    // MARK: - Singleton
    static let shared = CompatibilityHistoryService()
    private init() {}
    
    /// Profile context for scoped keys
    private var profileContext: ProfileContextManager { .shared }
    
    /// Get current user's email for storage key
    private var currentUserEmail: String {
        UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
    }
    
    /// Get storage key for current profile
    private var storageKey: String {
        profileContext.profileScopedKey(Self.storageKeyPrefix)
    }
    
    // MARK: - Load All
    /// Loads all saved history items for current profile, sorted by most recent first
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
    
    // MARK: - Load Groups (Multi-Partner Support)
    /// Loads history items grouped by comparisonGroupId
    /// Returns: Array of ComparisonGroup for grouped items + ungrouped single items
    func loadGroups() -> [ComparisonGroup] {
        let allItems = loadAll()
        var groups: [String: [CompatibilityHistoryItem]] = [:]
        var ungroupedItems: [CompatibilityHistoryItem] = []
        
        // Separate grouped and ungrouped items
        for item in allItems {
            if let groupId = item.comparisonGroupId {
                groups[groupId, default: []].append(item)
            } else {
                ungroupedItems.append(item)
            }
        }
        
        var result: [ComparisonGroup] = []
        
        // Create ComparisonGroup for each group
        for (groupId, items) in groups {
            let sortedItems = items.sorted { ($0.partnerIndex ?? 0) < ($1.partnerIndex ?? 0) }
            let userName = items.first?.boyName ?? "You"
            let timestamp = items.first?.timestamp ?? Date()
            
            result.append(ComparisonGroup(
                id: groupId,
                timestamp: timestamp,
                userName: userName,
                items: sortedItems
            ))
        }
        
        // Wrap ungrouped items as single-item groups
        for item in ungroupedItems {
            result.append(ComparisonGroup(
                id: item.sessionId,
                timestamp: item.timestamp,
                userName: item.boyName,
                items: [item]
            ))
        }
        
        // Sort by most recent
        return result.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Delete Group
    /// Deletes all items in a comparison group
    func deleteGroup(groupId: String) {
        var items = loadAll()
        items.removeAll { $0.comparisonGroupId == groupId || $0.sessionId == groupId }
        persist(items)
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
    /// Clears all history for current user (current profile only)
    func clearAll() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        print("[CompatibilityHistoryService] Cleared history for current profile")
    }
    
    /// Clears ALL compatibility history for a specific user across ALL profiles
    /// Used on logout to prevent cross-profile data contamination
    func clearAll(forUser email: String) {
        let keyPrefix = "\(Self.storageKeyPrefix)_\(email)_"
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        
        var clearedCount = 0
        for key in allKeys {
            if key.hasPrefix(keyPrefix) {
                UserDefaults.standard.removeObject(forKey: key)
                clearedCount += 1
                print("[CompatibilityHistoryService] Cleared key: \(key)")
            }
        }
        
        print("[CompatibilityHistoryService] Cleared \(clearedCount) history key(s) for \(email)")
    }
    
    // MARK: - Get Item
    /// Gets a single history item by session ID
    func get(sessionId: String) -> CompatibilityHistoryItem? {
        loadAll().first { $0.sessionId == sessionId }
    }
    
    // MARK: - Find Existing Match
    /// Finds an existing match by boy and girl DOB + Time (to avoid re-triggering LLM for same pair)
    /// Same person = same DOB + same birth time
    /// - Parameters:
    ///   - boyDob: Boy's date of birth in "yyyy-MM-dd" format
    ///   - boyTime: Boy's birth time in "HH:mm:ss" format
    ///   - girlDob: Girl's date of birth in "yyyy-MM-dd" format
    ///   - girlTime: Girl's birth time in "HH:mm:ss" format
    /// - Returns: Existing history item if found, nil otherwise
    func findExistingMatch(boyDob: String, boyTime: String, girlDob: String, girlTime: String) -> CompatibilityHistoryItem? {
        let items = loadAll()
        // Match on DOB + Time for accurate rematch detection
        // Same person = same DOB + same birth time
        return items.first { item in
            // DOB must match
            guard item.boyDob == boyDob && item.girlDob == girlDob else { return false }
            
            // Time must match (if stored)
            // For legacy items without time, match by DOB only
            if let storedBoyTime = item.boyTime, let storedGirlTime = item.girlTime {
                return storedBoyTime == boyTime && storedGirlTime == girlTime
            }
            
            // Legacy item without time - match by DOB only
            return true
        }
    }
    
    /// Finds existing match by Date objects (convenience method)
    /// Uses both date and time components for matching
    func findExistingMatch(boyDob: Date, boyTime: Date, girlDob: Date, girlTime: Date) -> CompatibilityHistoryItem? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "HH:mm:ss"
        
        let boyDobStr = dateFormatter.string(from: boyDob)
        let boyTimeStr = timeFormatter.string(from: boyTime)
        let girlDobStr = dateFormatter.string(from: girlDob)
        let girlTimeStr = timeFormatter.string(from: girlTime)
        
        return findExistingMatch(boyDob: boyDobStr, boyTime: boyTimeStr, girlDob: girlDobStr, girlTime: girlTimeStr)
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
    
    /// Persist items to a specific profile's storage key (used during sync)
    private func persist(_ items: [CompatibilityHistoryItem], toProfileKey profileKey: String) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: profileKey)
        } catch {
            print("[CompatibilityHistoryService] Failed to encode history for \(profileKey): \(error)")
        }
    }
    
    /// Load items from a specific profile's storage key
    private func loadAll(fromProfileKey profileKey: String) -> [CompatibilityHistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: profileKey) else {
            return []
        }
        do {
            return try JSONDecoder().decode([CompatibilityHistoryItem].self, from: data)
        } catch {
            return []
        }
    }
    
    /// Save item to a specific profile's storage (used during sync)
    private func save(_ item: CompatibilityHistoryItem, toProfileId profileId: String, userEmail: String) {
        let profileKey = "\(Self.storageKeyPrefix)_\(userEmail)_\(profileId)"
        var items = loadAll(fromProfileKey: profileKey)
        
        // Check for duplicate
        if let existingIndex = items.firstIndex(where: { $0.sessionId == item.sessionId }) {
            items[existingIndex] = item
        } else {
            items.insert(item, at: 0)
        }
        
        // Limit to maxItems
        if items.count > Self.maxItems {
            items = Array(items.prefix(Self.maxItems))
        }
        
        persist(items, toProfileKey: profileKey)
        print("[CompatibilityHistoryService] Saved item \(item.sessionId) to profile \(profileId)")
    }
    
    // MARK: - Sync from Server
    /// Syncs compatibility history from backend chat-history (for recovery after iOS clear)
    /// NOTE: Clears existing local history first to prevent duplicates from ID mismatch
    func syncFromServer(userEmail: String) async {
        print("[CompatibilityHistoryService] Starting sync for \(userEmail)")
        
        // CRITICAL: Clear existing local history for this user to prevent duplicates
        // Local items have client-generated IDs, server has server-generated IDs
        clearAll(forUser: userEmail)
        print("[CompatibilityHistoryService] Cleared local history for \(userEmail) before sync")
        
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
                let profileId: String?
                let createdAt: String
                
                enum CodingKeys: String, CodingKey {
                    case id, title, preview
                    case primaryArea = "primary_area"
                    case profileId = "profile_id"
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
                        let isReport: Bool?  // New field: true if this is initial report, not chat
                        
                        enum CodingKeys: String, CodingKey {
                            case id, role, content
                            case createdAt = "created_at"
                            case isReport = "is_report"
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
                    var boyTime: String? = nil
                    var girlTime: String? = nil
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
                        
                        // Extract birth details from analysisData (including time)
                        if let analysisData = metadata.analysisData {
                            if let boyDetails = analysisData.boy?.details {
                                boyDob = boyDetails.dob
                                boyTime = boyDetails.time  // NEW: Extract birth time
                                boyCity = boyDetails.place  // BirthDetails uses 'place' not 'city'
                            }
                            if let girlDetails = analysisData.girl?.details {
                                girlDob = girlDetails.dob
                                girlTime = girlDetails.time  // NEW: Extract birth time
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
                                        if let kutaData = gunaScores[key] as? [String: Any] {
                                            let scoreVal: Int
                                            if let s = kutaData["score"] as? Int {
                                                scoreVal = s
                                            } else if let s = kutaData["score"] as? Double {
                                                scoreVal = Int(s)
                                            } else {
                                                scoreVal = 0
                                            }
                                            let desc = kutaData["description"] as? String ?? ""
                                            kutas.append(KutaDetail(name: name, maxPoints: maxPoints, points: scoreVal, description: desc))
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
                    // Filter out report messages (isReport == true) - only include chat messages
                    var restoredMessages: [CompatChatMessageData] = []
                    if let backendMessages = threadDetail.messages {
                        for msg in backendMessages {
                            // Skip initial report messages - only restore follow-up chat
                            if msg.isReport == true {
                                continue
                            }
                            let chatMsg = CompatChatMessageData(
                                id: UUID().uuidString,
                                content: msg.content,
                                isUser: msg.role == "user",
                                timestamp: ISO8601DateFormatter().date(from: msg.createdAt ?? "") ?? Date(),
                                type: msg.role == "user" ? "user" : "ai"
                            )
                            restoredMessages.append(chatMsg)
                        }
                        print("[CompatibilityHistoryService] Restored \(restoredMessages.count) chat messages from server (filtered reports)")
                    }
                    
                    // Create full history item
                    // Extract comparison group info from metadata (if present)
                    let comparisonGroupId = threadDetail.metadata?.comparisonGroupId
                    let partnerIndex = threadDetail.metadata?.partnerIndex
                    
                    let item = CompatibilityHistoryItem(
                        sessionId: thread.id,
                        timestamp: ISO8601DateFormatter().date(from: threadDetail.createdAt ?? thread.createdAt) ?? Date(),
                        boyName: boyName,
                        boyDob: boyDob,
                        boyTime: boyTime,
                        boyCity: boyCity,
                        girlName: girlName,
                        girlDob: girlDob,
                        girlTime: girlTime,
                        girlCity: girlCity,
                        totalScore: totalScore,
                        maxScore: 36,
                        result: result,
                        chatMessages: restoredMessages,
                        comparisonGroupId: comparisonGroupId,
                        partnerIndex: partnerIndex
                    )
                    
                    // Save to the correct profile's storage based on server profile_id
                    let targetProfileId = thread.profileId ?? "self"
                    save(item, toProfileId: targetProfileId, userEmail: userEmail)
                    print("[CompatibilityHistoryService] Restored full history: \(thread.id) to profile: \(targetProfileId)")
                    
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
