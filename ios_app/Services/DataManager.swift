import SwiftData
import Foundation

/// Manages SwiftData persistence for chat history and sessions
@MainActor
final class DataManager {
    /// Shared instance for production use
    static let shared = DataManager()
    
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    
    /// Initialize with optional in-memory storage (for testing)
    init(inMemory: Bool = false) {
        let schema = Schema([
            UserSession.self,
            LocalChatThread.self,
            LocalChatMessage.self,
            UserBirthProfile.self,
            PartnerProfile.self,
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none  // Can enable for iCloud sync later
        )
        
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to initialize SwiftData: \(error)")
        }
    }
    
    // MARK: - Session Management
    
    /// Get or create an active session for a user
    func getOrCreateSession(for email: String) -> UserSession {
        let predicate = #Predicate<UserSession> { session in
            session.userEmail == email && session.isActive
        }
        let descriptor = FetchDescriptor<UserSession>(predicate: predicate)
        
        if let existing = try? context.fetch(descriptor).first {
            existing.lastAccessed = Date()
            try? context.save()
            return existing
        }
        
        let newSession = UserSession(userEmail: email)
        context.insert(newSession)
        try? context.save()
        return newSession
    }
    
    /// Get session by ID
    func getSession(id: String) -> UserSession? {
        let predicate = #Predicate<UserSession> { $0.sessionId == id }
        let descriptor = FetchDescriptor<UserSession>(predicate: predicate)
        return try? context.fetch(descriptor).first
    }
    
    // MARK: - Thread Management
    
    /// Fetch all threads for a session, optionally filtered by profile
    /// - Parameters:
    ///   - sessionId: Session ID to filter by
    ///   - profileId: Optional profile ID for Switch Profile feature (nil = show all profiles)
    ///   - includeArchived: Whether to include archived threads
    func fetchThreads(for sessionId: String, profileId: String? = nil, includeArchived: Bool = false) -> [LocalChatThread] {
        let predicate: Predicate<LocalChatThread>
        
        if let profileId = profileId {
            // Filter by session AND profile
            if includeArchived {
                predicate = #Predicate<LocalChatThread> { $0.sessionId == sessionId && $0.profileId == profileId }
            } else {
                predicate = #Predicate<LocalChatThread> { $0.sessionId == sessionId && $0.profileId == profileId && !$0.isArchived }
            }
        } else {
            // Filter by session only (show all profiles)
            if includeArchived {
                predicate = #Predicate<LocalChatThread> { $0.sessionId == sessionId }
            } else {
                predicate = #Predicate<LocalChatThread> { $0.sessionId == sessionId && !$0.isArchived }
            }
        }
        
        let descriptor = FetchDescriptor<LocalChatThread>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        var threads = (try? context.fetch(descriptor)) ?? []
        
        // Sort pinned to top
        threads.sort { thread1, thread2 in
            if thread1.isPinned && !thread2.isPinned { return true }
            if !thread1.isPinned && thread2.isPinned { return false }
            return thread1.updatedAt > thread2.updatedAt
        }
        
        return threads
    }
    
    /// Fetch all threads for a user (by email) - for History screen
    /// If profileId is provided, only threads for that profile are returned
    func fetchAllThreads(for userEmail: String, profileId: String? = nil, includeArchived: Bool = false) -> [LocalChatThread] {
        let descriptor = FetchDescriptor<LocalChatThread>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        var threads = (try? context.fetch(descriptor)) ?? []
        
        print("[DataManager.fetchAllThreads] Total fetched: \(threads.count), userEmail: \(userEmail), filterProfileId: \(profileId ?? "nil")")
        
        // Filter by userEmail and archived status
        threads = threads.filter { thread in
            let emailMatch = thread.userEmail == userEmail
            let archivedMatch = includeArchived || !thread.isArchived
            return emailMatch && archivedMatch
        }
        
        print("[DataManager.fetchAllThreads] After email filter: \(threads.count)")
        
        // Debug: Print all thread profileIds before filtering
        for thread in threads {
            print("[DataManager.fetchAllThreads] Thread '\(thread.title)' has profileId: '\(thread.profileId ?? "nil")'")
        }
        
        // Filter by profileId if provided (Switch Profile feature)
        if let profileId = profileId {
            let beforeCount = threads.count
            threads = threads.filter { thread in
                // Match threads with this profileId, OR threads with nil profileId and self profile
                if let threadProfileId = thread.profileId {
                    let match = threadProfileId == profileId
                    if !match {
                        print("[DataManager.fetchAllThreads] FILTERED OUT: '\(thread.title)' profileId '\(threadProfileId)' != filter '\(profileId)'")
                    }
                    return match
                } else {
                    // Legacy threads (no profileId) belong to "self"
                    let match = profileId == "self" || ProfileContextManager.shared.isUsingSelf
                    if !match {
                        print("[DataManager.fetchAllThreads] FILTERED OUT (legacy): '\(thread.title)' nil profileId, filter '\(profileId)'")
                    }
                    return match
                }
            }
            print("[DataManager.fetchAllThreads] After profileId filter: \(threads.count) (was \(beforeCount))")
        }
        
        // Sort pinned to top
        threads.sort { thread1, thread2 in
            if thread1.isPinned && !thread2.isPinned { return true }
            if !thread1.isPinned && thread2.isPinned { return false }
            return thread1.updatedAt > thread2.updatedAt
        }
        
        return threads
    }
    
    /// Create a new thread
    func createThread(sessionId: String, userEmail: String, profileId: String? = nil, title: String = "New Conversation") -> LocalChatThread {
        let thread = LocalChatThread(sessionId: sessionId, userEmail: userEmail, profileId: profileId, title: title)
        context.insert(thread)
        try? context.save()
        return thread
    }
    
    /// Save thread (upsert - insert or update) - for sync from server
    func saveThread(_ thread: LocalChatThread) {
        // Check if thread already exists
        if let existing = getThread(id: thread.id) {
            // Update existing - INCLUDING userEmail for migration scenarios
            existing.userEmail = thread.userEmail  // Critical for guest→registered migration
            existing.title = thread.title
            existing.preview = thread.preview
            existing.primaryArea = thread.primaryArea
            existing.areasDiscussed = thread.areasDiscussed
            existing.messageCount = thread.messageCount
            existing.isPinned = thread.isPinned
            existing.isArchived = thread.isArchived
            existing.updatedAt = thread.updatedAt
            existing.profileId = thread.profileId  // Switch Profile feature
        } else {
            // Insert new
            context.insert(thread)
        }
        try? context.save()
    }
    
    /// Get thread by ID
    func getThread(id: String) -> LocalChatThread? {
        let predicate = #Predicate<LocalChatThread> { $0.id == id }
        let descriptor = FetchDescriptor<LocalChatThread>(predicate: predicate)
        return try? context.fetch(descriptor).first
    }
    
    /// Public alias for getThread to match usage in ViewModels
    func fetchThread(id: String) -> LocalChatThread? {
        getThread(id: id)
    }
    
    /// Update thread from its messages
    func updateThread(_ thread: LocalChatThread) {
        let messages = fetchMessages(for: thread.id)
        thread.updateFromMessages(messages)
        try? context.save()
    }
    
    /// Archive a thread
    func archiveThread(_ thread: LocalChatThread) {
        thread.isArchived = true
        thread.updatedAt = Date()
        try? context.save()
    }
    
    /// Toggle pin status
    func togglePinThread(_ thread: LocalChatThread) {
        thread.isPinned.toggle()
        try? context.save()
    }
    
    /// Delete a thread and its messages (local + server)
    func deleteThread(_ thread: LocalChatThread) {
        let threadId = thread.id
        let messages = fetchMessages(for: threadId)
        for message in messages {
            context.delete(message)
        }
        context.delete(thread)
        try? context.save()
        
        // Also delete from server so it doesn't re-sync on login
        deleteThreadFromServer(threadId: threadId)
    }
    
    /// Fire-and-forget server-side thread deletion
    private func deleteThreadFromServer(threadId: String) {
        guard let email = UserDefaults.standard.string(forKey: "userEmail"), !email.isEmpty else { return }
        
        Task {
            let urlString = "\(APIConfig.baseURL)/chat-history/threads/\(email)/\(threadId)"
            guard let url = URL(string: urlString) else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
            
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    print("[DataManager] Server delete thread \(threadId): HTTP \(httpResponse.statusCode)")
                }
            } catch {
                print("[DataManager] Failed to delete server thread \(threadId): \(error)")
            }
        }
    }
    
    /// Delete ALL threads and messages for a user email
    /// Used during guest→registered migration to clear local guest data
    /// Server data will be re-synced with correct IDs
    func deleteAllThreads(for userEmail: String) {
        let threads = fetchAllThreads(for: userEmail, includeArchived: true)
        print("[DataManager] Deleting \(threads.count) local threads for \(userEmail)")
        
        for thread in threads {
            let messages = fetchMessages(for: thread.id)
            for message in messages {
                context.delete(message)
            }
            context.delete(thread)
        }
        try? context.save()
    }
    
    // MARK: - Message Management
    
    /// Fetch all messages for a thread
    func fetchMessages(for threadId: String) -> [LocalChatMessage] {
        let predicate = #Predicate<LocalChatMessage> { $0.threadId == threadId }
        let descriptor = FetchDescriptor<LocalChatMessage>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// Save a message (upsert - insert or skip if exists) - for sync from server
    func saveMessage(_ message: LocalChatMessage) {
        // Check if message already exists to prevent duplicates
        if getMessage(id: message.id) != nil {
            // Message already exists, skip insert
            return
        }
        
        context.insert(message)
        try? context.save()
        
        if let thread = getThread(id: message.threadId) {
            updateThread(thread)
        }
    }
    
    /// Get message by ID
    func getMessage(id: String) -> LocalChatMessage? {
        let predicate = #Predicate<LocalChatMessage> { $0.id == id }
        let descriptor = FetchDescriptor<LocalChatMessage>(predicate: predicate)
        return try? context.fetch(descriptor).first
    }
    
    /// Update an existing message (for streaming)
    func updateMessage(_ message: LocalChatMessage, content: String, isStreaming: Bool) {
        message.content = content
        message.isStreaming = isStreaming
        try? context.save()
    }
    
    /// Delete a message
    func deleteMessage(_ message: LocalChatMessage) {
        let threadId = message.threadId
        context.delete(message)
        try? context.save()
        
        if let thread = getThread(id: threadId) {
            updateThread(thread)
        }
    }
    
    // MARK: - Cleanup
    
    /// Clear old threads older than specified days
    func clearOldData(olderThan days: Int = 90) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = #Predicate<LocalChatThread> { $0.updatedAt < cutoff && !$0.isPinned }
        let descriptor = FetchDescriptor<LocalChatThread>(predicate: predicate)
        
        if let oldThreads = try? context.fetch(descriptor) {
            for thread in oldThreads {
                deleteThread(thread)
            }
        }
    }
    
    /// Clear all data (for testing or logout)
    func clearAllData() {
        let messageDescriptor = FetchDescriptor<LocalChatMessage>()
        if let messages = try? context.fetch(messageDescriptor) {
            for message in messages {
                context.delete(message)
            }
        }
        
        let threadDescriptor = FetchDescriptor<LocalChatThread>()
        if let threads = try? context.fetch(threadDescriptor) {
            for thread in threads {
                context.delete(thread)
            }
        }
        
        let sessionDescriptor = FetchDescriptor<UserSession>()
        if let sessions = try? context.fetch(sessionDescriptor) {
            for session in sessions {
                context.delete(session)
            }
        }
        
        try? context.save()
    }
    
    // MARK: - Helper Methods
    
    /// Get threads grouped by date for UI display
    func fetchThreadsGroupedByDate(for sessionId: String) -> [(String, [LocalChatThread])] {
        let threads = fetchThreads(for: sessionId)
        let calendar = Calendar.current
        let now = Date()
        
        var grouped: [String: [LocalChatThread]] = [:]
        
        for thread in threads {
            let key: String
            if calendar.isDateInToday(thread.updatedAt) {
                key = "Today"
            } else if calendar.isDateInYesterday(thread.updatedAt) {
                key = "Yesterday"
            } else if let daysAgo = calendar.dateComponents([.day], from: thread.updatedAt, to: now).day, daysAgo < 7 {
                key = "Last 7 Days"
            } else if let daysAgo = calendar.dateComponents([.day], from: thread.updatedAt, to: now).day, daysAgo < 30 {
                key = "Last 30 Days"
            } else {
                key = "Older"
            }
            
            if grouped[key] == nil {
                grouped[key] = []
            }
            grouped[key]?.append(thread)
        }
        
        let order = ["Today", "Yesterday", "Last 7 Days", "Last 30 Days", "Older"]
        return order.compactMap { key in
            if let threads = grouped[key], !threads.isEmpty {
                return (key, threads)
            }
            return nil
        }
    }
    
    /// Get chat threads grouped by date for user email (for Chat History sidebar)
    /// Excludes compatibility threads (compat_*, conv_* prefixes)
    func fetchChatThreadsGroupedByDate(for userEmail: String, profileId: String? = nil) -> [(String, [LocalChatThread])] {
        let allThreads = fetchAllThreads(for: userEmail, profileId: profileId)
        
        // Filter out compatibility-related threads
        let chatThreads = allThreads.filter { thread in
            let id = thread.id.lowercased()
            let isCompat = id.hasPrefix("compat_") || id.hasPrefix("conv_")
            let hasUserInteraction = thread.messageCount > 0
            return !isCompat && hasUserInteraction
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        var grouped: [String: [LocalChatThread]] = [:]
        
        for thread in chatThreads {
            let key: String
            if calendar.isDateInToday(thread.updatedAt) {
                key = "Today"
            } else if calendar.isDateInYesterday(thread.updatedAt) {
                key = "Yesterday"
            } else if let daysAgo = calendar.dateComponents([.day], from: thread.updatedAt, to: now).day, daysAgo < 7 {
                key = "Last 7 Days"
            } else if let daysAgo = calendar.dateComponents([.day], from: thread.updatedAt, to: now).day, daysAgo < 30 {
                key = "Last 30 Days"
            } else {
                key = "Older"
            }
            
            if grouped[key] == nil {
                grouped[key] = []
            }
            grouped[key]?.append(thread)
        }
        
        let order = ["Today", "Yesterday", "Last 7 Days", "Last 30 Days", "Older"]
        return order.compactMap { key in
            if let threads = grouped[key], !threads.isEmpty {
                return (key, threads)
            }
            return nil
        }
    }
    
    // MARK: - Birth Profile Management
    
    /// Save or update birth profile
    func saveBirthProfile(_ profile: UserBirthProfile) {
        // Check if profile with this email already exists
        if let existing = getBirthProfile(for: profile.email) {
            // Update existing
            existing.dateOfBirth = profile.dateOfBirth
            existing.timeOfBirth = profile.timeOfBirth
            existing.cityOfBirth = profile.cityOfBirth
            existing.latitude = profile.latitude
            existing.longitude = profile.longitude
            existing.placeId = profile.placeId
            existing.gender = profile.gender
            existing.timeUnknown = profile.timeUnknown
            existing.updatedAt = Date()
        } else {
            // Insert new
            context.insert(profile)
        }
        try? context.save()
    }
    
    /// Get birth profile by email
    func getBirthProfile(for email: String) -> UserBirthProfile? {
        let predicate = #Predicate<UserBirthProfile> { $0.email == email }
        let descriptor = FetchDescriptor<UserBirthProfile>(predicate: predicate)
        return try? context.fetch(descriptor).first
    }
    
    /// Get current user's birth profile
    func getCurrentUserProfile() -> UserBirthProfile? {
        // Try stored email first
        if let email = UserDefaults.standard.string(forKey: "userEmail"), !email.isEmpty {
            return getBirthProfile(for: email)
        }
        
        // Try generated email from stored birth data (User-Scoped)
        let dataKey = StorageKeys.userKey(for: StorageKeys.userBirthData)
        if let data = UserDefaults.standard.data(forKey: dataKey),
           let birthData = try? JSONDecoder().decode(BirthData.self, from: data) {
            let generatedEmail = EmailGenerator.generateFromComponents(
                dateOfBirth: birthData.dob,
                timeOfBirth: birthData.time,
                cityOfBirth: birthData.cityOfBirth ?? "",
                latitude: birthData.latitude,
                longitude: birthData.longitude
            )
            return getBirthProfile(for: generatedEmail)
        }
        
        return nil
    }
    
    /// Check if user can ask a question (quota check)
    func canAskQuestion() -> Bool {
        return QuotaManager.shared.canAsk
    }
    
    /// Increment question count for current user
    func incrementQuestionCount() {
        // Deprecated: Usage is now tracked via API calls in ViewModels.
        // Kept for backward compatibility.
    }
    
    /// Get remaining questions for current user
    func getRemainingQuestions() -> Int {
        // Deprecated: Exact count is now managed by backend
        return QuotaManager.shared.canAsk ? 1 : 0
    }
    
    /// Delete birth profile
    func deleteBirthProfile(_ profile: UserBirthProfile) {
        context.delete(profile)
        try? context.save()
    }
}

