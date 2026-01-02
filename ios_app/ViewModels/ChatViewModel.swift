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
        // Get user's name (from Google/Apple sign-in or "Destiny User" default)
        let userName = UserDefaults.standard.string(forKey: "userName") ?? "Destiny User"
        let greeting = "Hello \(userName)! I'm Destiny, your personal astrology guide. What would you like to know about your day, relationships, or path ahead?"
        
        let welcome = LocalChatMessage(
            threadId: currentThreadId,
            role: .assistant,
            content: greeting
        )
        messages.append(welcome)
        dataManager.saveMessage(welcome)
    }
    
    // MARK: - Send Message with SSE Streaming
    func sendMessage() async {
        let query = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        // Clear input and reset state immediately
        inputText = ""
        errorMessage = nil
        thinkingSteps = []  // Reset thinking steps
        streamingContent = ""  // Reset so typing indicator shows
        
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
        isStreaming = true
        
        // Get birth data
        guard let birthData = loadBirthData() else {
            errorMessage = "Please complete your birth data first"
            isLoading = false
            isStreaming = false
            return
        }
        
        // Create streaming placeholder
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
        
        var finalAnswer = ""
        var response: PredictionResponse?
        
        // Use SSE streaming for real-time progress
        do {
            try await StreamingPredictionService.shared.predictStream(request: request) { [weak self] event in
                guard let self = self else { return }
                
                switch event {
                case .thought(let step, let content, let display):
                    self.thinkingSteps.append(ThinkingStep(step: step, type: .thought, display: display, content: content))
                    
                case .action(let step, let tool, _):
                    let toolDisplay = "🔧 Using \(self.formatToolName(tool))..."
                    self.thinkingSteps.append(ThinkingStep(step: step, type: .action, display: toolDisplay, content: nil))
                    
                case .observation(let step, let display):
                    self.thinkingSteps.append(ThinkingStep(step: step, type: .observation, display: display, content: nil))
                    
                case .finalAnswer(let content):
                    finalAnswer = content
                    self.isLoading = false
                    
                case .answer(let resp):
                    response = resp
                    
                case .done:
                    break
                    
                case .error(let message):
                    self.errorMessage = message
                }
            }
            
            // Stream complete - typewriter the answer
            if let index = messages.firstIndex(where: { $0.id == streamingId }) {
                messages[index].area = response?.lifeArea ?? ""
                messages[index].confidence = response?.confidenceLabel ?? ""
                messages[index].executionTimeMs = response?.executionTimeMs ?? 0
                
                await streamWords(finalAnswer, messageId: streamingId)
                
                messages[index].content = finalAnswer
                messages[index].isStreaming = false
                dataManager.saveMessage(messages[index])
            }
            
            suggestedQuestions = response?.followUpSuggestions ?? []
            
        } catch {
            // Fallback to non-streaming API
            print("[SSE] Fallback: \(error)")
            thinkingSteps = []
            
            do {
                let resp = try await predictionService.predict(request: request)
                
                if let index = messages.firstIndex(where: { $0.id == streamingId }) {
                    messages[index].area = resp.lifeArea
                    messages[index].confidence = resp.confidenceLabel
                    messages[index].executionTimeMs = resp.executionTimeMs
                    await streamWords(resp.answer, messageId: streamingId)
                    messages[index].content = resp.answer
                    messages[index].isStreaming = false
                    dataManager.saveMessage(messages[index])
                }
                suggestedQuestions = resp.followUpSuggestions
            } catch {
                messages.removeAll { $0.id == streamingId }
                errorMessage = "Failed to get response. Please try again."
            }
        }
        
        isStreaming = false
        isLoading = false
        streamingMessageId = nil
        thinkingSteps = []
    }
    
    // Format tool names for display
    private func formatToolName(_ tool: String) -> String {
        tool.replacingOccurrences(of: "_", with: " ").capitalized
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
              var birthData = try? JSONDecoder().decode(BirthData.self, from: data) else {
            return nil
        }
        
        // Apply user's preferred astrology settings
        let ayanamsa = UserDefaults.standard.string(forKey: "ayanamsa") ?? "lahiri"
        let houseSystem = UserDefaults.standard.string(forKey: "houseSystem") ?? "equal"
        birthData.ayanamsa = ayanamsa
        birthData.houseSystem = houseSystem
        
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
