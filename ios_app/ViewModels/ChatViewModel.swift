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
    var showQuotaSheet = false
    var quotaDetails: String?
    
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
        predictionService: PredictionServiceProtocol? = nil,
        dataManager: DataManager? = nil
    ) {
        self.predictionService = predictionService ?? PredictionService()
        self.dataManager = dataManager ?? DataManager.shared
        
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
        
        // Start new thread or load latest for CURRENT PROFILE
        // Must filter by profile ID to show correct thread when profile is switched
        let threads = dataManager.fetchThreads(
            for: currentSessionId,
            profileId: ProfileContextManager.shared.activeProfileId
        )
        if let latestThread = threads.first {
            loadThread(latestThread)
        } else {
            startNewChat()
        }
    }
    
    // MARK: - History Management
    func loadHistory() {
        // Filter by active profile for Switch Profile feature
        chatHistory = dataManager.fetchThreads(
            for: currentSessionId,
            profileId: ProfileContextManager.shared.activeProfileId
        )
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
        // Create new thread with profile context
        let thread = dataManager.createThread(
            sessionId: currentSessionId,
            userEmail: userEmail,
            profileId: ProfileContextManager.shared.activeProfileId  // Switch Profile feature
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
        // Use active profile name for Switch Profile feature
        // If viewing as another profile, greet them by that name
        let profileName = ProfileContextManager.shared.activeProfileName
        let greeting = "Hello \(profileName)! I'm Destiny, your personal astrology guide. What would you like to know about your day, relationships, or path ahead?"
        
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
        // Check quota before proceeding
        let currentEmail = userEmail
        
        
        // Add user message immediately for responsiveness
        let userMessage = LocalChatMessage(
            threadId: currentThreadId,
            role: .user,
            content: query
        )
        messages.append(userMessage)
        dataManager.saveMessage(userMessage)
        
        isLoading = true
        isStreaming = true
        
        // Verify quota with backend
        do {
            let accessResponse = try await QuotaManager.shared.canAccessFeature(.aiQuestions, email: currentEmail)
            if !accessResponse.canAccess {
                isLoading = false
                isStreaming = false
                
                // Remove message
                if let idx = messages.lastIndex(where: { $0.id == userMessage.id }) {
                    messages.remove(at: idx)
                    dataManager.deleteMessage(userMessage)
                }
                
                // Detailed Error Handling - Professional Quota UI
                // Daily limit: Red banner only (temporary)
                // Overall limit / Feature not available: Bottom sheet only (upgrade prompt)
                if accessResponse.reason == "daily_limit_reached" {
                    // DAILY LIMIT: Show red banner only, no sheet
                    if let resetAtStr = accessResponse.resetAt,
                       let date = ISO8601DateFormatter().date(from: resetAtStr) {
                        let timeFormatter = DateFormatter()
                        timeFormatter.timeStyle = .short
                        let timeStr = timeFormatter.string(from: date)
                        errorMessage = "Daily limit reached. Resets at \(timeStr)."
                    } else {
                        errorMessage = "Daily limit reached. Resets tomorrow."
                    }
                    // No sheet for daily limit - just banner
                } else if accessResponse.reason == "overall_limit_reached" {
                    // OVERALL LIMIT: Show bottom sheet only, no banner
                    if currentEmail.contains("guest") || currentEmail.contains("@gen.com") {
                        // Guest users should only see Sign In option (no subscribe)
                        quotaDetails = "sign_in_to_continue_asking".localized
                    } else {
                        quotaDetails = "You've reached your free limit. Subscribe for unlimited access."
                    }
                    showQuotaSheet = true
                } else {
                    // FEATURE NOT AVAILABLE: Show bottom sheet only
                    quotaDetails = accessResponse.upgradeCta?.message ?? "Upgrade to unlock this feature."
                    showQuotaSheet = true
                }
                return
            }
        } catch {
            print("Quota check failed: \(error)")
        }
        
        // Record question usage in backend (async)
        // Note: usage is recorded *after* checks pass, but ideally should be *after* successful response?
        // Current logic: record *attempt*.
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
                    let toolDisplay = self.friendlyToolName(tool)
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
                messages[index].traceId = response?.predictionId  // Link for rating sync
                
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
                    messages[index].traceId = resp.predictionId  // Link for rating sync
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
    
    // Format tool names for display — user-friendly cosmic text
    private func friendlyToolName(_ tool: String) -> String {
        let toolNames: [String: String] = [
            "planets_data": "🪐 Mapping your planetary positions...",
            "houses": "🏛️ Analyzing your house placements...",
            "dignity": "👑 Checking planetary dignities...",
            "functional": "⚖️ Evaluating benefic & malefic influences...",
            "shadbala": "💪 Measuring planetary strengths...",
            "avasthas": "🌙 Reading planetary states...",
            "ashtakavarga": "📊 Calculating transit strengths...",
            "dasha": "⏳ Tracing your planetary periods...",
            "transits": "🌠 Scanning upcoming cosmic movements...",
            "divisional": "🔍 Examining divisional charts...",
            "nakshatra": "⭐ Reading your birth star influences...",
            "yoga_dosha": "🧿 Detecting yogas and doshas...",
            "mangal_dosha": "♂️ Checking Mangal Dosha...",
            "kala_sarpa": "🐍 Analyzing Kala Sarpa influence...",
            "bhavat_bhavam": "🔗 Exploring house connections..."
        ]
        return toolNames[tool] ?? "🔮 Analyzing your chart..."
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
        // Check active profile first (for Switch Profile feature)
        if let profileBirthData = ProfileContextManager.shared.activeBirthData {
            print("[ChatViewModel] Using birth data from active profile: \(ProfileContextManager.shared.activeProfileName)")
            
            // Convert UserBirthData to BirthData
            var birthData = BirthData(
                dob: profileBirthData.dob,
                time: profileBirthData.time,
                latitude: profileBirthData.latitude,
                longitude: profileBirthData.longitude,
                cityOfBirth: profileBirthData.cityOfBirth,
                ayanamsa: profileBirthData.ayanamsa,
                houseSystem: profileBirthData.houseSystem
            )
            birthData = normalizeTimeFormat(birthData)
            return birthData
        }
        
        // Fallback: Load from UserDefaults
        guard let data = UserDefaults.standard.data(forKey: "userBirthData"),
              var birthData = try? JSONDecoder().decode(BirthData.self, from: data) else {
            return nil
        }
        
        // Normalize time to 24-hour format (HH:mm)
        // This handles legacy data that may be stored as "8:30 PM" instead of "20:30"
        birthData = normalizeTimeFormat(birthData)
        
        // Apply user's preferred astrology settings
        let ayanamsa = UserDefaults.standard.string(forKey: "ayanamsa") ?? "lahiri"
        let houseSystem = UserDefaults.standard.string(forKey: "houseSystem") ?? "whole_sign"
        birthData.ayanamsa = ayanamsa
        birthData.houseSystem = houseSystem
        
        return birthData
    }
    
    /// Convert 12-hour time (e.g., "8:30 PM") to 24-hour (e.g., "20:30")
    private func normalizeTimeFormat(_ data: BirthData) -> BirthData {
        let time = data.time
        
        // Check if already in HH:mm format (24-hour)
        let hhmmRegex = "^\\d{2}:\\d{2}$"
        if time.range(of: hhmmRegex, options: .regularExpression) != nil {
            return data // Already normalized
        }
        
        // Try to parse 12-hour format (h:mm a or hh:mm a)
        let formatter12 = DateFormatter()
        formatter12.locale = Locale(identifier: "en_US_POSIX")
        formatter12.dateFormat = "h:mm a"
        
        if let date = formatter12.date(from: time) {
            let formatter24 = DateFormatter()
            formatter24.dateFormat = "HH:mm"
            let normalizedTime = formatter24.string(from: date)
            
            print("[ChatViewModel] Normalized time from '\(time)' to '\(normalizedTime)'")
            
            // Create new BirthData with normalized time
            return BirthData(
                dob: data.dob,
                time: normalizedTime,
                latitude: data.latitude,
                longitude: data.longitude,
                cityOfBirth: data.cityOfBirth,
                ayanamsa: data.ayanamsa,
                houseSystem: data.houseSystem
            )
        }
        
        // If can't parse, return as-is (API will catch the error)
        return data
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
        // Quota is now recorded server-side by /predict endpoint
        // Just update local cache for UI display
        var used = UserDefaults.standard.integer(forKey: "quotaUsed")
        used += 1
        UserDefaults.standard.set(used, forKey: "quotaUsed")
        print("✅ Quota recorded server-side for: \(userEmail)")
    }
    
    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading && !isStreaming
    }
    
    /// Check if user can ask another question (uses server-synced state)
    var canAskQuestion: Bool {
        QuotaManager.shared.canAsk
    }
}
