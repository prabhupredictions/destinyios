import Foundation
import SwiftData
import SwiftUI

/// Hard cap on persisted message body size. Defends against future backend
/// regressions (max_tokens bump, runaway reasoning model output) from
/// poisoning the SwiftData store with content too large for the markdown
/// renderer to handle without watchdog kills. 64 KB is far above the
/// largest currently-shipping ceiling (Bedrock Opus at 8000 tokens ~ 32 KB)
/// while staying well below the MarkdownTextView backstop (40 KB before
/// plain-text fallback). See 2026-06-24 chat-crash audit.
fileprivate let MAX_PERSISTED_CONTENT_BYTES = 64 * 1024

fileprivate func capPersistedContent(_ s: String) -> String {
    guard s.utf8.count > MAX_PERSISTED_CONTENT_BYTES else { return s }
    // Trim to a safe UTF-8 boundary by working with Substring (which
    // splits on Character boundaries, never mid-codepoint).
    let trimmed = String(s.prefix(MAX_PERSISTED_CONTENT_BYTES))
    return trimmed + "\n\n[…response truncated to protect chat performance]"
}

fileprivate func capPersistedContent(_ s: String?) -> String? {
    s.map(capPersistedContent)
}

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
    /// Rich quota-blockage state passed to QuotaExhaustedView. Carries the
    /// reason, plan_id, suggested_plan, fair-use flag, and reset_at so the
    /// view can branch headline + body + CTA precisely. quotaDetails (above)
    /// is kept as a back-compat shortcut for older call sites that read
    /// just the message.
    var quotaError: QuotaErrorInfo?
    var windowManager = MessageWindowManager()
    var cosmicProgressSteps: [CosmicProgressStep] = []
    private var progressTimerTask: Task<Void, Never>? = nil

    private static let cosmicMessageKeys: [String] = [
        "progress_connecting",
        "progress_mapping_sky",
        "progress_reading_planets",
        "progress_planetary_voice",
        "progress_chart_secrets",
        "progress_deeper_patterns",
        "progress_river_of_time",
        "progress_cosmic_windows",
        "progress_destiny_shaped",
        "progress_oracle_weaving",
    ]
    /// Short label shown in the user bubble when a home card sends a rich contextual query.
    /// The full inputText is still sent to the LLM; this only affects what the user sees.
    var pendingDisplayLabel: String? = nil
    /// Buffered query captured when the quota wall fires before a send completes.
    /// ChatView observes `quotaManager.isPremium` and replays this when the user
    /// successfully upgrades. Cleared if the user dismisses the paywall without upgrading.
    var pendingPostUpgradeQuery: String? = nil
    private var streamingTask: Task<Void, Never>? = nil
    private var stepProgressTask: Task<Void, Never>? = nil
    // Tracks whether the app backgrounded mid-stream so we show retry instead of error
    private var backgroundedWhileStreaming = false
    nonisolated(unsafe) private var notificationObservers: [Any] = []
    // Set when background expiry cancels a stream — shows recovery card in UI
    private(set) var interruptedQuestion: String?
    // Last query sent — saved before inputText is cleared so recovery can replay it
    private var lastSentQuery: String = ""

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
        observeAppLifecycle()
    }

    nonisolated deinit {
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
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

    // MARK: - App Lifecycle
    private func observeAppLifecycle() {
        let resignObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.handleAppBackground() }
        }
        let activeObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.handleAppForeground() }
        }
        let expiryObserver = NotificationCenter.default.addObserver(
            forName: .streamingBackgroundExpired,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.handleBackgroundExpiry() }
        }
        notificationObservers = [resignObserver, activeObserver, expiryObserver]
    }

    func handleAppBackground() {
        backgroundedWhileStreaming = isStreaming
    }

    func handleBackgroundExpiry() {
        // iOS is about to suspend — cancel stream cleanly, save question for recovery UI
        guard isStreaming else { return }
        interruptedQuestion = lastSentQuery.isEmpty ? nil : lastSentQuery
        streamingTask?.cancel()
        streamingTask = nil
        stepProgressTask?.cancel()
        cosmicProgressSteps = []
        isStreaming = false
        isLoading = false
        print("[ChatViewModel] Stream cancelled: background time expired")
    }

    func handleAppForeground() {
        // Reset stuck isLoading with no active task (overnight idle residue)
        if isLoading, streamingTask == nil {
            isLoading = false
        }
        // If stream was interrupted by backgrounding, clean up orphaned state
        if backgroundedWhileStreaming && !isStreaming {
            stepProgressTask?.cancel()
            cosmicProgressSteps = []
            errorMessage = nil
            // Remove any orphaned streaming messages left behind
            let orphaned = messages.filter { $0.isStreaming }
            for msg in orphaned {
                messages.removeAll { $0.id == msg.id }
                windowManager.remove(id: msg.id)
                dataManager.context.delete(msg)
            }
        }
        backgroundedWhileStreaming = false

        // Re-sync quota so canAskQuestion is fresh (stale after overnight idle)
        let email = userEmail.isEmpty ? (UserDefaults.standard.string(forKey: "userEmail") ?? "") : userEmail
        guard !email.isEmpty else { return }
        Task { try? await QuotaManager.shared.syncStatus(email: email, force: true) }
    }

    /// Load latest thread for current profile, or start a new chat if none exist.
    /// Called from ChatView.onAppear when no initial question or thread ID is pending.
    ///
    /// Self-heal for poisoned threads: if the previous launch crashed before
    /// the chat finished rendering (watchdog kill, OOM, etc.), the flag
    /// "chat_load_started" stays true in UserDefaults. On the NEXT launch we
    /// skip auto-reopen of the latest thread and start a fresh chat instead,
    /// breaking the crash loop without requiring app reinstall. The user can
    /// still navigate to the toxic thread manually via History — but no
    /// longer gets trapped on app launch.
    func loadDefaultState() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "chat_load_started") {
            // Previous launch never reached chat_load_completed — assume crash.
            // Clear the flag, skip auto-reopen, start fresh.
            defaults.set(false, forKey: "chat_load_started")
            print("⚠️ [ChatViewModel] Detected prior chat-load crash — starting fresh thread instead of auto-reopening latest")
            startNewChat()
            return
        }
        defaults.set(true, forKey: "chat_load_started")

        let threads = dataManager.fetchThreads(
            for: currentSessionId,
            profileId: ProfileContextManager.shared.activeProfileId
        )
        if let latestThread = threads.first {
            loadThread(latestThread)
        } else {
            startNewChat()
        }

        // Clear the in-progress flag after a short delay — long enough for
        // SwiftUI to mount the thread + finish first paint. If the app
        // crashes before this fires, the next launch enters recovery mode.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)  // 3 seconds
            defaults.set(false, forKey: "chat_load_started")
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
        interruptedQuestion = nil

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
            id: "welcome_\(currentThreadId)",
            threadId: currentThreadId,
            role: .assistant,
            content: greeting
        )
        // Always insert into context so SwiftData backing data is valid for SwiftUI rendering
        dataManager.context.insert(welcome)
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

        // Cancel any in-flight stream and remove orphaned streaming messages
        if isStreaming || streamingTask != nil {
            streamingTask?.cancel()
            streamingTask = nil
            stepProgressTask?.cancel()
            progressTimerTask?.cancel()
            progressTimerTask = nil
            cosmicProgressSteps = []
            let orphaned = messages.filter { $0.isStreaming }
            for msg in orphaned {
                messages.removeAll { $0.id == msg.id }
                windowManager.remove(id: msg.id)
                dataManager.context.delete(msg)
            }
            isStreaming = false
        }

        // Clear input and reset state immediately
        inputText = ""
        errorMessage = nil
        suggestedQuestions = []
        interruptedQuestion = nil
        lastSentQuery = query

        let currentEmail = userEmail

        isLoading = true

        // Verify quota with backend BEFORE inserting the user bubble.
        // If we inserted first (the old "responsiveness" path), an exhausted
        // user briefly saw their question accepted before the paywall popped —
        // misleading and looked like the request had been served.
        do {
            let accessResponse = try await QuotaManager.shared.canAccessFeature(.aiQuestions, email: currentEmail)
            if !accessResponse.canAccess {
                isLoading = false

                // Buffer the in-flight query so ChatView can replay it after a
                // successful upgrade (paywall closes, isPremium flips false→true).
                pendingPostUpgradeQuery = query

                // Build the rich QuotaErrorInfo struct so QuotaExhaustedView
                // can branch headline / body / CTA on reason + plan_id + the
                // server-set is_fair_use_violation flag instead of relying
                // on an opaque string. quotaDetails is still set below for
                // back-compat with call sites that haven't been migrated.
                quotaError = QuotaErrorInfo(
                    reason: accessResponse.reason,
                    planId: accessResponse.planId,
                    featureId: accessResponse.feature,
                    message: accessResponse.upgradeCta?.message,
                    action: nil,
                    suggestedPlan: accessResponse.upgradeCta?.suggestedPlan,
                    supportEmail: nil,
                    resetAt: accessResponse.resetAt,
                    serverIsFairUseViolation: accessResponse.isFairUseViolation
                )

                if accessResponse.reason == "daily_limit_reached" {
                    if let resetAtStr = accessResponse.resetAt,
                       let date = ISO8601DateFormatter().date(from: resetAtStr) {
                        let timeFormatter = DateFormatter()
                        timeFormatter.timeStyle = .short
                        let timeStr = timeFormatter.string(from: date)
                        errorMessage = String(format: "daily_limit_reset_time".localized, timeStr)
                    } else {
                        errorMessage = "daily_limit_reached_tomorrow".localized
                    }
                } else if accessResponse.reason == "subscription_expired" {
                    // Lapsed paid user — show the renew paywall, not the
                    // upgrade-to-keep-going copy. quotaError already carries
                    // reason='subscription_expired' so QuotaExhaustedView's
                    // isSubscriptionExpired branch fires for headline/body/CTA.
                    quotaDetails = "subscription_expired_body".localized
                    showQuotaSheet = true
                } else if accessResponse.reason == "overall_limit_reached" {
                    // Prefer server-curated per-plan message (iOS-11 fix). Fall back to
                    // generic localized strings if backend didn't supply one.
                    if let serverMessage = accessResponse.upgradeCta?.message, !serverMessage.isEmpty {
                        quotaDetails = serverMessage
                    } else if QuotaManager.isGuestEmail(currentEmail) {
                        quotaDetails = "sign_in_to_continue_asking".localized
                    } else {
                        quotaDetails = "upgrade_to_keep_going".localized
                    }
                    showQuotaSheet = true
                } else {
                    quotaDetails = accessResponse.upgradeCta?.message ?? "feature_not_available".localized
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

        // Two-phase commit for the chat bubbles. We construct LocalChatMessage
        // instances now (so they're available for the streaming closures) but
        // DEFER the actual append to `messages` / `windowManager` until the
        // server has accepted the request and emitted its first SSE event.
        // Rationale: an earlier-than-server-confirmed append created a "ghost
        // bubble" — the user briefly saw their question rendered before a
        // server-side quota rejection snatched it away. Premium UX demands
        // that we never show content that can be revoked. The 100-300ms
        // window between Send and first SSE event is covered by the input
        // bar's `isLoading` spinner; no chat bubble is ever shown unless the
        // server has committed to streaming a real reply.
        let userMessage = LocalChatMessage(
            threadId: currentThreadId,
            role: .user,
            content: displayContent
        )
        dataManager.context.insert(userMessage)
        if HistorySettingsManager.shared.isHistoryEnabled {
            dataManager.saveMessage(userMessage)
        }

        let request = PredictionRequest(
            query: query,
            birthData: birthData,
            sessionId: currentSessionId,
            conversationId: currentThreadId,
            userEmail: userEmail,
            language: appLanguage,
            responseStyle: responseStyle,
            responseLength: responseLength,
            profileId: ProfileContextManager.shared.activeProfileId
        )

        // Non-streaming sync request. Single atomic commit — bubble appears
        // ONLY when the server has responded successfully. No two-phase
        // commit, no ghost-bubble race, no SSE state machine.
        // The cosmic progress timer covers the wait (8-30s on Opus is
        // expected; NetworkClient timeout is 600s).
        isLoading = false
        isStreaming = true
        cosmicProgressSteps = []
        startCosmicProgressTimer()

        let streamingMsg = LocalChatMessage(
            threadId: currentThreadId,
            role: .assistant,
            content: "",
            isStreaming: true
        )
        // The user bubble + assistant placeholder are committed together
        // BEFORE the network call so the user sees feedback immediately
        // (cosmic progress card under their question). The sync endpoint
        // either returns 200 with the answer or 4xx — atomic outcome,
        // safe to commit upfront.
        dataManager.context.insert(userMessage)
        dataManager.context.insert(streamingMsg)
        messages.append(userMessage)
        windowManager.append(userMessage)
        messages.append(streamingMsg)
        windowManager.append(streamingMsg)

        streamingTask = Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await self.predictionService.predict(request: request)

                // Stop cosmic progress + commit final answer atomically.
                self.stepProgressTask?.cancel()
                self.progressTimerTask?.cancel()
                self.progressTimerTask = nil

                if let idx = self.messages.lastIndex(where: { $0.id == streamingMsg.id }) {
                    // Cap persisted content at 64 KB (UTF-8) — see comment at
                    // top of file. Prevents future runaway responses from
                    // poisoning the SwiftData store.
                    self.messages[idx].content = capPersistedContent(response.answer)
                    self.messages[idx].area = response.lifeArea
                    self.messages[idx].advice = capPersistedContent(response.advice)
                    self.messages[idx].executionTimeMs = response.executionTimeMs
                }
                self.suggestedQuestions = response.followUpSuggestions

                withAnimation(.easeOut(duration: 0.3)) {
                    self.cosmicProgressSteps = []
                }
                try? await Task.sleep(nanoseconds: 300_000_000)
                if let idx = self.messages.lastIndex(where: { $0.id == streamingMsg.id }) {
                    withAnimation(.easeIn(duration: 0.5)) {
                        self.messages[idx].isStreaming = false
                    }
                    if HistorySettingsManager.shared.isHistoryEnabled {
                        self.dataManager.saveMessage(self.messages[idx])
                    }
                }
                self.isStreaming = false
            } catch is CancellationError {
                self.stepProgressTask?.cancel()
                self.progressTimerTask?.cancel()
                self.progressTimerTask = nil
                self.cosmicProgressSteps = []
                self.messages.removeAll { $0.id == streamingMsg.id }
                self.windowManager.remove(id: streamingMsg.id)
                self.dataManager.context.delete(streamingMsg)
                self.isStreaming = false
            } catch let quota as QuotaExhaustedError {
                // Server-side quota rejection (race between /can-access and
                // /predict — possible if quota was consumed by a parallel
                // session between the two calls). Mirror the upfront denial
                // path: drop both bubbles, buffer the query for replay,
                // present the paywall.
                self.stepProgressTask?.cancel()
                self.progressTimerTask?.cancel()
                self.progressTimerTask = nil
                self.cosmicProgressSteps = []
                self.messages.removeAll { $0.id == streamingMsg.id }
                self.windowManager.remove(id: streamingMsg.id)
                self.dataManager.context.delete(streamingMsg)
                if let userIdx = self.messages.lastIndex(where: { $0.id == userMessage.id }) {
                    self.messages.remove(at: userIdx)
                    self.windowManager.remove(id: userMessage.id)
                    self.dataManager.deleteMessage(userMessage)
                }
                self.pendingPostUpgradeQuery = self.lastSentQuery
                // Build the rich error info so QuotaExhaustedView can render
                // plan-aware copy (Plus fair-use → Contact Support; otherwise
                // upgrade CTA). Mid-flight rejections come through
                // NetworkClient.quotaErrorIf403 which now carries plan_id +
                // is_fair_use_violation directly from the server.
                self.quotaError = QuotaErrorInfo(
                    reason: quota.reason,
                    planId: quota.planId,
                    featureId: "ai_questions",
                    message: quota.upgradeMessage,
                    action: nil,
                    suggestedPlan: quota.suggestedPlan,
                    supportEmail: nil,
                    resetAt: quota.resetAt,
                    serverIsFairUseViolation: quota.isFairUseViolation
                )
                if let serverMsg = quota.upgradeMessage, !serverMsg.isEmpty {
                    self.quotaDetails = serverMsg
                } else if quota.reason == "daily_limit_reached" {
                    self.quotaDetails = "daily_limit_reached_tomorrow".localized
                } else if QuotaManager.isGuestEmail(self.userEmail) {
                    self.quotaDetails = "sign_in_to_continue_asking".localized
                } else {
                    self.quotaDetails = "upgrade_to_keep_going".localized
                }
                self.showQuotaSheet = true
                self.isStreaming = false
            } catch {
                self.stepProgressTask?.cancel()
                self.progressTimerTask?.cancel()
                self.progressTimerTask = nil
                self.cosmicProgressSteps = []
                self.interruptedQuestion = self.lastSentQuery.isEmpty ? nil : self.lastSentQuery
                self.messages.removeAll { $0.id == streamingMsg.id }
                self.windowManager.remove(id: streamingMsg.id)
                self.dataManager.context.delete(streamingMsg)
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

    func retryInterruptedQuestion() {
        guard let question = interruptedQuestion else { return }
        interruptedQuestion = nil
        inputText = question
        Task { await sendMessage() }
    }

    // MARK: - Post-Upgrade Replay

    /// Returns the buffered query (set when the quota wall fired before send completed)
    /// and clears the buffer atomically. Caller is responsible for refilling inputText
    /// and triggering sendMessage().
    func consumePendingPostUpgradeQuery() -> String? {
        let query = pendingPostUpgradeQuery
        pendingPostUpgradeQuery = nil
        return query
    }

    /// Discards the buffered post-upgrade query. Call this when the user dismisses
    /// the paywall WITHOUT upgrading so a stale query doesn't auto-fire later.
    func clearPendingPostUpgradeQuery() {
        pendingPostUpgradeQuery = nil
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
    
    
    // MARK: - Progress Step Pacer

    private func startCosmicProgressTimer() {
        progressTimerTask?.cancel()
        progressTimerTask = Task { @MainActor [weak self] in
            var index = 0
            while !Task.isCancelled {
                guard let self else { return }
                let key = Self.cosmicMessageKeys[index % 10]
                let msg = LocalizedString.get(key)
                let step = CosmicProgressStep(text: msg, displayKey: key, isCompleted: false, isActive: true)
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.cosmicProgressSteps = [step]
                }
                index += 1
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                if Task.isCancelled { return }
            }
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
