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
    var streamingContent = ""
    var thinkingSteps: [ThinkingStep] = []
    var errorMessage: String?
    var inputText = ""
    var chatHistory: [LocalChatThread] = []
    var showHistory = false
    var suggestedQuestions: [String] = []  // Follow-up suggestions from API
    var showQuotaSheet = false
    var quotaDetails: String?
    var typewriterMessageId: String?  // Message currently being typewritten
    var windowManager = MessageWindowManager()
    var cosmicProgressSteps: [CosmicProgressStep] = []
    /// Short label shown in the user bubble when a home card sends a rich contextual query.
    /// The full inputText is still sent to the LLM; this only affects what the user sees.
    var pendingDisplayLabel: String? = nil
    private var streamingTask: Task<Void, Never>? = nil
    private var stepProgressTask: Task<Void, Never>? = nil

    // Current session/thread
    var currentSessionId: String = ""
    var currentThreadId: String = ""
    var userEmail: String = ""
    
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

        // Load sidebar history only — thread loading is deferred to ChatView.onAppear
        // so the view can decide: load latest thread OR start new (if a question is pending)
        loadHistory()
    }

    /// Load latest thread for current profile, or start a new chat if none exist.
    /// Called from ChatView.onAppear when no initial question or thread ID is pending.
    func loadDefaultState() {
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

    // MARK: - Profile Switch
    /// Called when active profile changes — isolates chat per profile
    func handleProfileSwitch() {
        // Clear current conversation state
        messages = []
        windowManager.replaceAll([])
        suggestedQuestions = []
        errorMessage = nil
        streamingContent = ""
        typewriterMessageId = nil
        stopStreaming()

        // Reload history filtered for the new profile and load its latest thread
        loadHistory()
        loadDefaultState()
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
        windowManager.replaceAll(messages)
        
        // Add welcome if empty
        if messages.isEmpty {
            addWelcomeMessage()
        }
    }
    
    func startNewChat() {
        // Create new thread with profile context
        if HistorySettingsManager.shared.isHistoryEnabled {
            let thread = dataManager.createThread(
                sessionId: currentSessionId,
                userEmail: userEmail,
                profileId: ProfileContextManager.shared.activeProfileId  // Switch Profile feature
            )
            currentThreadId = thread.id
        } else {
            // Generate an ephemeral thread ID (not persisted)
            currentThreadId = UUID().uuidString
        }
        messages = []
        windowManager.replaceAll([])
        
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
        let greeting = String(format: "chat_welcome_greeting".localized, profileName)
        
        let welcome = LocalChatMessage(
            id: "welcome",
            threadId: currentThreadId,
            role: .assistant,
            content: greeting
        )
        messages.append(welcome)
        windowManager.append(welcome)
        if HistorySettingsManager.shared.isHistoryEnabled {
            dataManager.saveMessage(welcome)
        }
    }
    
    // MARK: - Send Message (Non-Streaming — matches compat chat pattern)
    func sendMessage() async {
        let query = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        // Short label for the user bubble; full query still goes to LLM
        let displayContent = pendingDisplayLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? query
        pendingDisplayLabel = nil

        // Clear input and reset state immediately
        inputText = ""
        errorMessage = nil
        suggestedQuestions = []

        let currentEmail = userEmail

        // Add user message immediately for responsiveness
        let userMessage = LocalChatMessage(
            threadId: currentThreadId,
            role: .user,
            content: displayContent
        )
        messages.append(userMessage)
        windowManager.append(userMessage)
        if HistorySettingsManager.shared.isHistoryEnabled {
            dataManager.saveMessage(userMessage)
        }
        
        isLoading = true
        
        // Verify quota with backend
        do {
            let accessResponse = try await QuotaManager.shared.canAccessFeature(.aiQuestions, email: currentEmail)
            if !accessResponse.canAccess {
                isLoading = false
                
                // Remove message
                if let idx = messages.lastIndex(where: { $0.id == userMessage.id }) {
                    messages.remove(at: idx)
                    windowManager.remove(id: userMessage.id)
                    dataManager.deleteMessage(userMessage)
                }
                
                if accessResponse.reason == "daily_limit_reached" {
                    if let resetAtStr = accessResponse.resetAt,
                       let date = ISO8601DateFormatter().date(from: resetAtStr) {
                        let timeFormatter = DateFormatter()
                        timeFormatter.timeStyle = .short
                        let timeStr = timeFormatter.string(from: date)
                        errorMessage = "Daily limit reached. Resets at \(timeStr)."
                    } else {
                        errorMessage = "Daily limit reached. Resets tomorrow."
                    }
                } else if accessResponse.reason == "overall_limit_reached" {
                    if currentEmail.contains("guest") || currentEmail.contains("@gen.com") {
                        quotaDetails = "sign_in_to_continue_asking".localized
                    } else {
                        quotaDetails = "create_account_to_continue".localized
                    }
                    showQuotaSheet = true
                } else {
                    quotaDetails = accessResponse.upgradeCta?.message ?? "Upgrade to unlock this feature."
                    showQuotaSheet = true
                }
                return
            }
        } catch {
            print("Quota check failed: \(error)")
        }
        
        // Get birth data
        guard let birthData = loadBirthData() else {
            errorMessage = "Please complete your birth data first"
            isLoading = false
            return
        }
        
        let appLanguage = UserDefaults.standard.string(forKey: "appLanguageCode") ?? "en"
        
        // Read response length and content style directly from UserDefaults to avoid stale cache
        let responseLength = UserDefaults.standard.string(forKey: "userResponseLength") ?? "detailed"
        let responseStyle = UserDefaults.standard.string(forKey: "userContentStyle") ?? "guidance"

        let request = PredictionRequest(
            query: query,
            birthData: birthData,
            sessionId: currentSessionId,
            conversationId: currentThreadId,
            userEmail: userEmail,
            language: appLanguage,
            responseStyle: responseStyle,
            responseLength: responseLength
        )
        
        // Streaming API call — replaces fake typewriter
        isLoading = false
        isStreaming = true
        cosmicProgressSteps = []

        let streamingMsg = LocalChatMessage(
            threadId: currentThreadId,
            role: .assistant,
            content: "",
            isStreaming: true
        )
        messages.append(streamingMsg)
        windowManager.append(streamingMsg)

        streamingTask = Task { [weak self] in
            guard let self else { return }
            var finalResponse: PredictionResponse? = nil
            var accumulatedAnswer = ""

            do {
                try await StreamingPredictionService.shared.predictStream(
                    request: request
                ) { event in
                    switch event {
                    case .action:
                        break  // No longer used for progress tracking

                    case .progressStep(_, _, _, let isDone, let displayKey, _):
                        if !isDone {
                            if let key = displayKey {
                                let text = NSLocalizedString(key, comment: "")
                                for i in self.cosmicProgressSteps.indices {
                                    self.cosmicProgressSteps[i].isActive = false
                                }
                                let step = CosmicProgressStep(text: text, displayKey: key, isCompleted: false, isActive: true)
                                withAnimation(.easeOut(duration: 0.35)) {
                                    self.cosmicProgressSteps.append(step)
                                }
                            }
                        } else {
                            if let idx = self.cosmicProgressSteps.indices.last(where: { self.cosmicProgressSteps[$0].isActive }) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    self.cosmicProgressSteps[idx].isCompleted = true
                                    self.cosmicProgressSteps[idx].isActive = false
                                }
                            }
                        }

                    case .finalAnswer(let content):
                        accumulatedAnswer = content
                        if let idx = self.messages.lastIndex(where: { $0.id == streamingMsg.id }) {
                            self.messages[idx].content = accumulatedAnswer
                        }

                    case .answer(let response):
                        finalResponse = response

                    case .done:
                        self.stepProgressTask?.cancel()
                        for i in self.cosmicProgressSteps.indices {
                            self.cosmicProgressSteps[i].isCompleted = true
                            self.cosmicProgressSteps[i].isActive = false
                        }

                        let answer = finalResponse?.answer ?? accumulatedAnswer
                        if let idx = self.messages.lastIndex(where: { $0.id == streamingMsg.id }) {
                            self.messages[idx].content = answer
                            self.messages[idx].isStreaming = false
                            self.messages[idx].area = finalResponse?.lifeArea
                            self.messages[idx].advice = finalResponse?.advice
                            if HistorySettingsManager.shared.isHistoryEnabled {
                                self.dataManager.saveMessage(self.messages[idx])
                            }
                        }
                        self.suggestedQuestions = finalResponse?.followUpSuggestions ?? []
                        self.isStreaming = false

                    case .error(let msg):
                        self.stepProgressTask?.cancel()
                        self.errorMessage = msg
                        self.cosmicProgressSteps = []
                        self.messages.removeAll { $0.id == streamingMsg.id }
                        self.windowManager.remove(id: streamingMsg.id)
                        self.isStreaming = false

                    default: break
                    }
                }
            } catch is CancellationError {
                self.stepProgressTask?.cancel()
                self.cosmicProgressSteps = []
                self.messages.removeAll { $0.id == streamingMsg.id }
                self.windowManager.remove(id: streamingMsg.id)
                self.isStreaming = false
            } catch {
                self.stepProgressTask?.cancel()
                self.cosmicProgressSteps = []
                self.errorMessage = "Failed to get response. Please try again."
                self.messages.removeAll { $0.id == streamingMsg.id }
                self.windowManager.remove(id: streamingMsg.id)
                self.isStreaming = false
            }
        }
    }

    func stopStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        stepProgressTask?.cancel()
        stepProgressTask = nil
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
        windowManager.replaceAll([])
        addWelcomeMessage()
    }
    
    
    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
    
    /// Check if user can ask another question (uses server-synced state)
    var canAskQuestion: Bool {
        QuotaManager.shared.canAsk
    }
}
