import Foundation
import SwiftUI

/// ViewModel for Chat screen with streaming and history support
@MainActor
@Observable
class ChatViewModel {
    // MARK: - State
    var messages: [LocalChatMessage] = []
    var isLoading = false
    var isStreaming = false
    var streamingContent = ""  // For typewriter effect on final answer
    var thinkingSteps: [ThinkingStep] = []  // Claude-like thinking display
    var errorMessage: String?
    var inputText = ""
    var chatHistory: [LocalChatThread] = []
    var showHistory = false
    var suggestedQuestions: [String] = []  // Follow-up suggestions from API
    
    // Current session/thread
    var currentSessionId: String = ""
    var currentThreadId: String = ""
    var userEmail: String = ""
    
    // MARK: - Streaming State
    private var streamingMessageId: String?
    
    // MARK: - Dependencies
    private let predictionService: PredictionServiceProtocol
    let dataManager: DataManager
    
    // MARK: - Init
    init(
        predictionService: PredictionServiceProtocol = PredictionService(),
        dataManager: DataManager = .shared
    ) {
        self.predictionService = predictionService
        self.dataManager = dataManager
        
        loadUserSession()
    }
    
    // MARK: - Session Management
    private func loadUserSession() {
        userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
        
        // Get or create session
        let session = dataManager.getOrCreateSession(for: userEmail)
        currentSessionId = session.sessionId
        
        // Load history
        loadHistory()
        
        // Start new thread or load latest
        let threads = dataManager.fetchThreads(for: currentSessionId)
        if let latestThread = threads.first {
            loadThread(latestThread)
        } else {
            startNewChat()
        }
    }
    
    // MARK: - History Management
    func loadHistory() {
        chatHistory = dataManager.fetchThreads(for: currentSessionId)
    }
    
    func loadThread(_ thread: LocalChatThread) {
        currentThreadId = thread.id
        messages = dataManager.fetchMessages(for: thread.id)
        
        // Add welcome if empty
        if messages.isEmpty {
            addWelcomeMessage()
        }
    }
    
    func startNewChat() {
        // Create new thread
        let thread = dataManager.createThread(
            sessionId: currentSessionId,
            userEmail: userEmail
        )
        currentThreadId = thread.id
        messages = []
        
        addWelcomeMessage()
        loadHistory()
    }
    
    func deleteThread(_ thread: LocalChatThread) {
        dataManager.deleteThread(thread)
        loadHistory()
        
        // If deleted current thread, start new
        if thread.id == currentThreadId {
            startNewChat()
        }
    }
    
    func togglePinThread(_ thread: LocalChatThread) {
        dataManager.togglePinThread(thread)
        loadHistory()
    }
    
    // MARK: - Welcome Message
    private func addWelcomeMessage() {
        let welcome = LocalChatMessage(
            threadId: currentThreadId,
            role: .assistant,
            content: "Hello! I'm Destiny, your personal astrology guide. What would you like to know about your day, relationships, or path ahead?"
        )
        messages.append(welcome)
        dataManager.saveMessage(welcome)
    }
    
    // MARK: - Send Message with Streaming
    func sendMessage() async {
        let query = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        // Clear input immediately
        inputText = ""
        errorMessage = nil
        
        // Add user message
        let userMessage = LocalChatMessage(
            threadId: currentThreadId,
            role: .user,
            content: query
        )
        messages.append(userMessage)
        dataManager.saveMessage(userMessage)
        
        // Record question usage in backend (async, don't block UI)
        Task {
            await recordQuotaUsage()
        }
        
        isLoading = true
        
        // Get birth data
        guard let birthData = loadBirthData() else {
            errorMessage = "Please complete your birth data first"
            isLoading = false
            return
        }
        
        // Create streaming placeholder (will be populated when response arrives)
        let streamingId = UUID().uuidString
        let placeholderMessage = LocalChatMessage(
            id: streamingId,
            threadId: currentThreadId,
            role: .assistant,
            content: "",
            isStreaming: true
        )
        messages.append(placeholderMessage)
        streamingMessageId = streamingId
        
        let request = PredictionRequest(
            query: query,
            birthData: birthData,
            sessionId: currentSessionId,
            conversationId: currentThreadId,
            userEmail: userEmail
        )
        
        // Premium UX: typing indicator → API call → polished cards appear (no raw markdown)
        do {
            // API call - typing indicator shows during this
            let response = try await predictionService.predict(request: request)
            
            // Update message with complete content immediately (no typewriter for raw markdown)
            if let index = messages.firstIndex(where: { $0.id == streamingId }) {
                messages[index].content = response.answer
                messages[index].isStreaming = false  // Triggers polished card view
                messages[index].area = response.lifeArea
                messages[index].confidence = response.confidenceLabel
                dataManager.saveMessage(messages[index])
            }
            
            // Store follow-up suggestions for display
            suggestedQuestions = response.followUpSuggestions
            
            isLoading = false
            streamingMessageId = nil
            
        } catch {
            // Error - remove placeholder and show error message
            messages.removeAll { $0.id == streamingId }
            errorMessage = "Failed to get response. Please try again."
            isLoading = false
            streamingMessageId = nil
        }
    }
    
    // MARK: - Word-by-Word Streaming
    private func streamWords(_ text: String, messageId: String) async {
        let words = text.components(separatedBy: " ")
        streamingContent = ""  // Reset
        
        for (index, word) in words.enumerated() {
            // Small delay between words (30-50ms)
            try? await Task.sleep(nanoseconds: UInt64.random(in: 25_000_000...45_000_000))
            
            // Update streaming content - this triggers @Observable UI update
            if index < words.count - 1 {
                streamingContent += word + " "
            } else {
                streamingContent += word
            }
        }
        
        // After streaming, update the actual message
        if let msgIndex = messages.firstIndex(where: { $0.id == messageId }) {
            messages[msgIndex].content = streamingContent
        }
    }
    
    // MARK: - Helpers
    private func loadBirthData() -> BirthData? {
        guard let data = UserDefaults.standard.data(forKey: "userBirthData"),
              let birthData = try? JSONDecoder().decode(BirthData.self, from: data) else {
            return nil
        }
        return birthData
    }
    
    func clearChat() {
        // Delete current thread messages
        for message in messages {
            dataManager.deleteMessage(message)
        }
        
        messages = []
        addWelcomeMessage()
    }
    
    // MARK: - Quota Management
    private func recordQuotaUsage() async {
        do {
            // Record usage in backend
            try await QuotaManager.shared.recordQuestionOnServer(email: userEmail)
            
            // Update local cache
            var used = UserDefaults.standard.integer(forKey: "quotaUsed")
            used += 1
            UserDefaults.standard.set(used, forKey: "quotaUsed")
            
            print("Recorded question usage for: \(userEmail)")
        } catch {
            print("Failed to record quota usage: \(error)")
            // Still increment local cache as fallback
            var used = UserDefaults.standard.integer(forKey: "quotaUsed")
            used += 1
            UserDefaults.standard.set(used, forKey: "quotaUsed")
        }
    }
    
    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading && !isStreaming
    }
    
    /// Check if user can ask another question (has remaining quota)
    var canAskQuestion: Bool {
        let isGuest = UserDefaults.standard.bool(forKey: "isGuest")
        let isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        
        // Premium users always can ask
        if isPremium { return true }
        
        // Check quota
        let used = UserDefaults.standard.integer(forKey: "quotaUsed")
        let limit = isGuest ? 3 : 10  // Guest: 3, Registered: 10
        
        return used < limit
    }
}
