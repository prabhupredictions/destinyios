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

    // MARK: - Teardown

    enum TearDownReason {
        case userStop
        case viewDisappear
        case threadSwitch
        case profileSwitch
        case backgroundExpiry
        case paywallPresent
        case deepLink
        case sendReentry
    }

    /// Single chokepoint for cancelling an active generation. Cancels every
    /// outstanding Task/Timer, clears transient UI state, deletes the orphan
    /// assistant-placeholder bubble (Task 12 wires this for streaming), and
    /// resets `isStreaming`/`isLoading`.
    ///
    /// Idempotent. Safe to call from any path; the 9 historical cancel sites
    /// (background-expiry, sendMessage re-entry, thread switch, etc.) all
    /// funnel through here so we never leak a Task or a placeholder bubble.
    func tearDownGenerationState(reason: TearDownReason) {
        #if DEBUG
        print("[ChatViewModel] teardown reason: \(reason)")
        #endif
        streamingTask?.cancel()
        streamingTask = nil
        stepProgressTask?.cancel()
        stepProgressTask = nil
        progressTimerTask?.cancel()
        progressTimerTask = nil
        revealTask?.cancel()
        revealTask = nil
        revealComplete = false
        smoothPumpTask?.cancel()
        smoothPumpTask = nil
        smoothPumpTarget = ""
        smoothPumpStreamOpen = false

        cosmicProgressSteps = []
        streamingContent = ""

        // Delete orphan assistant placeholders (rows with content == ""
        // and isStreaming == true). Sync path's success branch sets
        // isStreaming=false BEFORE this would run, so a successful
        // commit is never touched.
        let orphaned = messages.filter { $0.isStreaming && $0.content.isEmpty }
        for msg in orphaned {
            messages.removeAll { $0.id == msg.id }
            windowManager.remove(id: msg.id)
            dataManager.context.delete(msg)
        }

        isStreaming = false
        isLoading = false
    }

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
    /// Typewriter reveal task — paces .finalAnswer content into streamingContent
    /// character-by-character so the UI shows a ChatGPT-style reveal even when
    /// the backend emits the answer as a single blob (current Bedrock behavior).
    /// Cancelled by tearDownGenerationState and by reduce-motion clients.
    private var revealTask: Task<Void, Never>? = nil
    /// Set to true once the typewriter reveal has consumed the full answer.
    /// .done waits on this before committing the atomic flip to MarkdownTextView.
    private var revealComplete: Bool = false

    // MARK: - Smooth pump state (real-streaming display interpolation)
    //
    // Bedrock emits tokens in bursts (10ch, 50ms pause, 30ch, 200ms pause, ...).
    // If the .token handler writes `streamingContent = accumulatedAnswer`
    // synchronously on each chunk, the typewriter looks chunky — the user sees
    // a block of text, then a pause, then another block. ChatGPT/Claude.ai
    // hide this with display interpolation: tokens grow a TARGET string, but
    // a separate display pump reveals characters at a smooth ~60Hz rate. We
    // do the same. See startSmoothPump() for the rate-adaptive logic.
    private var smoothPumpTask: Task<Void, Never>? = nil
    /// The latest target text from the .token / .finalAnswer accumulator.
    /// The pump never reads beyond this — once it reaches the end, it parks.
    private var smoothPumpTarget: String = ""
    /// True while the SSE stream is open (tokens still arriving). Goes false
    /// on .finalAnswer or .done. When false AND pump has reached the target,
    /// the pump exits.
    private var smoothPumpStreamOpen: Bool = false
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
        stopGeneration()

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
        // Streaming-safety: tear down any active generation BEFORE the
        // thread id swaps. Otherwise the .done handler for thread A could
        // land on thread B's messages array. Discovered missing during
        // 2026-06-28 audit.
        tearDownGenerationState(reason: .threadSwitch)
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
    
    // MARK: - Send Message (flag-routed)

    /// Public entry. Routes to streaming or sync based on AppConfig cohort flag.
    /// Per docs/superpowers/plans/2026-06-28-streaming-typewriter-v2.md task 12.
    func sendMessage() async {
        let userId = userEmail
        let cfg = AppConfig.shared
        let stream = cfg.shouldStreamFor(userId: userId)
        #if DEBUG
        let bundleVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "?"
        print("[ChatViewModel] sendMessage routing decision: stream=\(stream) | enabled=\(cfg.streamingEnabled) cohortPct=\(cfg.streamingCohortPercent) minVer=\(cfg.streamingMinAppVersion) bundleVer=\(bundleVersion) versionAllowed=\(cfg.versionAllowed) inCohort=\(cfg.inCohort(userId)) UI_TEST_MODE=\(ProcessInfo.processInfo.environment["UI_TEST_MODE"] ?? "nil") userId=\(userId)")
        #endif
        if stream {
            await sendMessageStreaming()
        } else {
            await sendMessageSync()
        }
    }

    // MARK: - Send Message (Non-Streaming — matches compat chat pattern)
    func sendMessageSync() async {
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
                    // DONE-ONLY-MUTATION: the single content commit on the sync path
                    // (mirrors the streaming-path invariant enforced by
                    // StreamingPredictionServiceTests). Cap persisted content at
                    // 64 KB (UTF-8) — see comment at top of file. Prevents future
                    // runaway responses from poisoning the SwiftData store.
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

    // MARK: - Streaming path (Task 12)

    /// Storage for the .answer event's full PredictionResponse — captured ahead
    /// of .done so the SINGLE atomic flip in commitFinalAnswer has everything
    /// (answer, lifeArea, advice, executionTimeMs, followUpSuggestions).
    private var pendingFinalResponse: PredictionResponse?
    private var streamErrorMessage: String?

    /// Streaming send path. Consumes SSE events from StreamingPredictionService
    /// and feeds streamingContent (only — never messages[idx].content). The
    /// atomic flip into the persisted bubble happens in commitFinalAnswer
    /// (called from the single .done handler).
    func sendMessageStreaming() async {
        print("[STREAM] step 1 — entered sendMessageStreaming")
        let query = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, !isLoading, !isStreaming else {
            print("[STREAM] EARLY-RETURN guard@694: empty=\(query.isEmpty) isLoading=\(isLoading) isStreaming=\(isStreaming)")
            return
        }
        print("[STREAM] step 2 — past guard, query='\(query.prefix(40))'")

        // Re-entry safety: tear down any prior generation cleanly.
        tearDownGenerationState(reason: .sendReentry)
        print("[STREAM] step 3 — past tearDown")

        // Short label for the user bubble; full query still goes to LLM.
        let displayContent = pendingDisplayLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? query
        pendingDisplayLabel = nil

        lastSentQuery = query
        inputText = ""
        errorMessage = nil
        suggestedQuestions = []
        interruptedQuestion = nil
        isLoading = true

        let currentEmail = userEmail

        // Verify quota with backend BEFORE inserting the user bubble (mirrors sync path).
        print("[STREAM] step 4 — about to call canAccessFeature")
        do {
            let accessResponse = try await QuotaManager.shared.canAccessFeature(.aiQuestions, email: currentEmail)
            print("[STREAM] step 5 — quota returned canAccess=\(accessResponse.canAccess) reason=\(accessResponse.reason ?? "nil")")
            if !accessResponse.canAccess {
                print("[STREAM] EARLY-RETURN quota denied reason=\(accessResponse.reason ?? "nil")")
                isLoading = false
                pendingPostUpgradeQuery = query
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
                    quotaDetails = "subscription_expired_body".localized
                    showQuotaSheet = true
                } else if accessResponse.reason == "overall_limit_reached" {
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
            print("[STREAM] quota check threw: \(error)")
        }
        print("[STREAM] step 6 — past quota check")

        guard let birthData = loadBirthData() else {
            print("[STREAM] EARLY-RETURN loadBirthData returned nil")
            errorMessage = "Please complete your birth data first"
            isLoading = false
            return
        }
        print("[STREAM] step 7 — birthData ok, building request")

        let appLanguage = UserDefaults.standard.string(forKey: "appLanguageCode") ?? "en"
        let responseLength = UserDefaults.standard.string(forKey: "userResponseLength") ?? "detailed"
        let responseStyle = UserDefaults.standard.string(forKey: "userContentStyle") ?? "guidance"

        // Build the user + assistant-placeholder pair atomically.
        let userMessage = LocalChatMessage(
            threadId: currentThreadId,
            role: .user,
            content: displayContent
        )
        let streamingMsg = LocalChatMessage(
            threadId: currentThreadId,
            role: .assistant,
            content: "",
            isStreaming: true
        )
        dataManager.context.insert(userMessage)
        dataManager.context.insert(streamingMsg)
        print("[STREAM] step 8 — inserted user + streaming msgs into SwiftData context")
        if HistorySettingsManager.shared.isHistoryEnabled {
            dataManager.saveMessage(userMessage)
        }
        messages.append(userMessage)
        windowManager.append(userMessage)
        messages.append(streamingMsg)
        windowManager.append(streamingMsg)
        print("[STREAM] step 9 — appended to messages array + windowManager")

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
        print("[STREAM] step 10 — built PredictionRequest")

        isLoading = false
        isStreaming = true
        cosmicProgressSteps = []
        startCosmicProgressTimer()
        print("[STREAM] step 11 — set isStreaming=true, started cosmic timer")

        let idempotencyKey = UUID().uuidString
        print("[STREAM] step 12 — about to spawn streamingTask")

        streamingTask = Task { [weak self] in
            print("[StreamingTask] Task body began — self=\(self == nil ? "nil" : "alive")")
            guard let self else {
                print("[StreamingTask] ABORTED — weak self was nil; VM deallocated before Task ran")
                return
            }
            print("[StreamingTask] entered — about to open SSE stream")
            // 30 Hz coalescer note: the Bedrock backend currently emits the
            // final answer as a single .finalAnswer event, so the coalescer
            // runs effectively once. When token-level streaming lands
            // server-side, this is the buffer that will replay at 30 Hz.
            var accumulatedAnswer = ""

            do {
                try await StreamingPredictionService.shared.predictStream(
                    request: request,
                    idempotencyKey: idempotencyKey
                ) { [weak self] event in
                    guard let self else { return }
                    #if DEBUG
                    switch event {
                    case .thought: print("[StreamingTask] event=.thought")
                    case .action: print("[StreamingTask] event=.action")
                    case .observation: print("[StreamingTask] event=.observation")
                    case .progressStep: print("[StreamingTask] event=.progressStep")
                    case .token: print("[StreamingTask] event=.token")
                    case .finalAnswer: print("[StreamingTask] event=.finalAnswer")
                    case .answer: print("[StreamingTask] event=.answer")
                    case .done: print("[StreamingTask] event=.done")
                    case .error(let msg): print("[StreamingTask] event=.error msg=\(msg)")
                    case .backpressure(let r): print("[StreamingTask] event=.backpressure retry=\(r)s")
                    }
                    #endif
                    Task { @MainActor in
                        switch event {
                        case .thought, .action, .observation, .progressStep:
                            self.handleProgressEvent(event)
                        case .token(let chunk):
                            // Real per-token SSE path. Bedrock emits tokens in
                            // BURSTS (10ch, 50ms pause, 30ch, 200ms pause, ...).
                            // If we mirror those bursts straight to the UI, the
                            // typewriter feels chunky — a stutter the user sees
                            // as "block, pause, block, pause". ChatGPT/Claude.ai
                            // hide this by interpolating: the raw token stream
                            // grows accumulatedAnswer, and a separate display
                            // pump reveals characters at a smooth, constant rate.
                            // We do the same — see startSmoothPump() below for
                            // the ~60Hz ticker that drives self.streamingContent.
                            self.revealTask?.cancel()
                            self.revealComplete = true
                            accumulatedAnswer += chunk
                            // On the FIRST token: hide cosmic progress and pin the
                            // user's question to the top so the answer has full
                            // screen real estate to grow into. After this, no further
                            // auto-scroll — the user reads top-down naturally.
                            if !self.cosmicProgressSteps.isEmpty {
                                self.cosmicProgressSteps = []
                                self.stepProgressTask?.cancel(); self.stepProgressTask = nil
                                self.progressTimerTask?.cancel(); self.progressTimerTask = nil
                            }
                            self.smoothPumpTarget = accumulatedAnswer
                            self.smoothPumpStreamOpen = true
                            if self.smoothPumpTask == nil {
                                self.startSmoothPump()
                            }
                        case .finalAnswer(let content):
                            // Two paths:
                            //  (a) Backends that already streamed tokens — accumulatedAnswer
                            //      is populated. Reconcile to the server's canonical text
                            //      (in case of post-trim) and signal the smooth pump that
                            //      no more tokens are coming — the pump will drain to
                            //      the final character at the same smooth rate.
                            //  (b) Backends that only emit a single .finalAnswer blob
                            //      (e.g. flag rollback). Fall back to the existing
                            //      typewriter reveal so users still get a paced reveal.
                            if accumulatedAnswer.isEmpty {
                                accumulatedAnswer = content
                                self.startTypewriterReveal(fullText: content, streamingMsgId: streamingMsg.id)
                            } else {
                                if content != accumulatedAnswer {
                                    accumulatedAnswer = content
                                }
                                // Tell the smooth pump this is the canonical final text,
                                // then close the stream so the pump drains to the end
                                // at the normal rate (no jumpy reveal).
                                self.smoothPumpTarget = accumulatedAnswer
                                self.smoothPumpStreamOpen = false
                                self.revealComplete = true
                            }
                        case .answer(let response):
                            // Capture full response for the single atomic flip in .done.
                            self.pendingFinalResponse = response
                        case .done:
                            // C-2: defensive — if server emitted .done without ever
                            // sending an .answer frame (malformed completion), treat as
                            // a stream error and fall back to sync /predict instead of
                            // letting commitFinalAnswer silently early-return and leave
                            // the streaming bubble on screen.
                            //
                            // Tightened: also require streamingContent to be empty so a
                            // token-only stream that lost its `.answer` frame doesn't
                            // silently commit an empty message.
                            if self.pendingFinalResponse == nil &&
                               (self.messages.first(where: { $0.id == streamingMsg.id })?.content.isEmpty ?? true) &&
                               self.streamingContent.isEmpty {
                                self.tearDownGenerationState(reason: .userStop)
                                self.inputText = query
                                await self.sendMessageSync()
                                return
                            }
                            // Close the smooth pump's stream window so it knows no more
                            // tokens are coming and can drain to the final char.
                            self.smoothPumpStreamOpen = false
                            // Wait for the typewriter / smooth pump to finish revealing
                            // before flipping to the persisted MarkdownTextView path —
                            // otherwise the user sees the reveal truncate halfway and
                            // snap to formatted.
                            await self.waitForRevealCompletion()
                            await self.waitForSmoothPumpDrain()
                            await self.commitFinalAnswer(
                                streamingMsgId: streamingMsg.id,
                                response: self.pendingFinalResponse
                            )
                        case .backpressure:
                            // C-2: server is shedding load (semaphore overflow).
                            // Transparently fall back to sync /predict — tear down the
                            // streaming bubble and replay the user's query via sync so
                            // the UI never hangs waiting for a stream that won't come.
                            self.tearDownGenerationState(reason: .userStop)
                            self.inputText = query
                            await self.sendMessageSync()
                            return
                        case .error(let message):
                            self.streamErrorMessage = message
                        }
                    }
                }
            } catch is CancellationError {
                #if DEBUG
                print("[StreamingTask] CancellationError — discarded partial")
                #endif
                // Stop button or teardown — discard partial; banner shows lastSentQuery.
                self.tearDownGenerationState(reason: .userStop)
                self.interruptedQuestion = self.lastSentQuery.isEmpty ? nil : self.lastSentQuery
            } catch let quota as QuotaExhaustedError {
                #if DEBUG
                print("[StreamingTask] QuotaExhaustedError reason=\(quota.reason)")
                #endif
                await self.handleQuotaErrorFromStream(
                    quota: quota,
                    streamingMsgId: streamingMsg.id,
                    userMessage: userMessage
                )
            } catch {
                #if DEBUG
                print("[StreamingTask] FALLBACK-TO-SYNC error=\(error) localizedDescription=\(error.localizedDescription)")
                #endif
                // Transparent fallback to sync /predict.
                self.tearDownGenerationState(reason: .userStop)
                self.inputText = query
                await self.sendMessageSync()
            }
        }
    }

    // MARK: - Client-side Typewriter Reveal

    /// Pace `fullText` into `streamingContent` character-by-character so the
    /// UI shows a smooth reveal even when the backend emits the answer as a
    /// single `.finalAnswer` blob (current Bedrock behavior — see Task 12).
    ///
    /// Rate: ~120 chars/sec (~8 chars per 66ms tick on a 15Hz timeline).
    /// This is faster than typical human typing (~40–60 wpm = ~300 chars/min)
    /// and slower than an instant paste — it reads as "AI is composing" without
    /// dragging out 1KB+ answers to >10 seconds.
    ///
    /// Cancellable via `revealTask?.cancel()` (called by `tearDownGenerationState`
    /// on user-stop / thread-switch / etc.). Honors Reduce Motion by skipping
    /// the reveal entirely and showing the full text immediately.
    @MainActor
    private func startTypewriterReveal(fullText: String, streamingMsgId: String) {
        revealTask?.cancel()
        revealComplete = false

        // Reduce Motion: skip the typewriter, show full text immediately.
        if UIAccessibility.isReduceMotionEnabled {
            streamingContent = fullText
            revealComplete = true
            return
        }

        let chars = Array(fullText)
        let total = chars.count
        guard total > 0 else {
            revealComplete = true
            return
        }

        // Adaptive pacing — total reveal time stays in the 3–8s window across
        // all answer lengths so the user never waits >8s for the reveal to
        // finish but short answers still feel deliberate. ~33ms tick = 30 Hz.
        // Markdown re-parse cost is bounded by MarkdownTextView's 40 KB cap
        // and `nonisolated` static helpers (commit 8dc2a32).
        let targetSeconds: Double
        if total < 300 { targetSeconds = 2.0 }       // short answer — quick
        else if total < 1000 { targetSeconds = 3.5 } // normal
        else if total < 3000 { targetSeconds = 5.0 } // long
        else { targetSeconds = 7.0 }                  // very long — never drag past ~7s

        let tickInterval: UInt64 = 33_000_000 // 33ms → 30 Hz
        let totalTicks = max(1, Int(targetSeconds / 0.033))
        let charsPerTick = max(1, Int(ceil(Double(total) / Double(totalTicks))))

        revealTask = Task { @MainActor [weak self] in
            guard let self else { return }
            var revealed = 0
            while revealed < total {
                if Task.isCancelled { return }
                let next = min(revealed + charsPerTick, total)
                self.streamingContent = String(chars[0..<next])
                revealed = next
                if revealed >= total { break }
                try? await Task.sleep(nanoseconds: tickInterval)
            }
            self.revealComplete = true
        }
    }

    /// Wait until the typewriter reveal has consumed the full `.finalAnswer`
    /// text, so `.done` doesn't flip to `MarkdownTextView` mid-reveal.
    /// Polls every 50ms. Returns immediately if reveal is already done.
    /// Bounded at 30s as a safety valve so a stuck reveal never blocks `.done`.
    @MainActor
    private func waitForRevealCompletion() async {
        let deadline = Date().addingTimeInterval(30)
        while !revealComplete && Date() < deadline {
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
    }

    // MARK: - Smooth Pump (rate-adaptive display interpolation)
    //
    // The .token handler feeds `smoothPumpTarget` raw (bursty) text from
    // Bedrock. This pump runs at ~60Hz on the main actor and reveals
    // characters into `streamingContent` at a smooth, ADAPTIVE rate:
    //
    //   - If the unrevealed backlog is tiny (≤2 chars), pause briefly so
    //     the reveal doesn't outpace incoming tokens and stutter.
    //   - If the backlog is small (≤20 chars), reveal 1 char/tick — slow,
    //     human-typing-speed feel (~60 chars/sec).
    //   - If the backlog is medium (≤80 chars), reveal 2 chars/tick — keeps
    //     pace with most Bedrock burst rates (~120 chars/sec).
    //   - If the backlog is large (>80 chars), reveal up to N/40 chars/tick
    //     so we drain backlogs >1.5s in ≤1.5s — prevents the visible reveal
    //     from falling far behind the actual completion.
    //
    // When the stream closes (.finalAnswer / .done set smoothPumpStreamOpen
    // = false), the pump drains to the end and exits. waitForSmoothPumpDrain()
    // is the .done waiter equivalent of waitForRevealCompletion().
    @MainActor
    private func startSmoothPump() {
        smoothPumpTask?.cancel()
        smoothPumpTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let tick: UInt64 = 16_666_667 // ~60Hz (1/60 s in ns)
            while !Task.isCancelled {
                let target = self.smoothPumpTarget
                let shown = self.streamingContent
                let totalCh = target.count
                let shownCh = shown.count

                if shownCh >= totalCh {
                    // Caught up to target. If stream is closed, we're done.
                    if !self.smoothPumpStreamOpen { break }
                    // Otherwise wait briefly for more tokens.
                    try? await Task.sleep(nanoseconds: tick * 2)
                    continue
                }

                let backlog = totalCh - shownCh
                let charsThisTick: Int
                if backlog <= 2 {
                    // Tiny backlog: pause to avoid stuttering when tokens
                    // are arriving slower than reveal rate.
                    try? await Task.sleep(nanoseconds: tick * 3)
                    continue
                } else if backlog <= 20 {
                    charsThisTick = 1
                } else if backlog <= 80 {
                    charsThisTick = 2
                } else {
                    // Drain large backlogs proportionally — at 60Hz with
                    // N/40 chars/tick, an 800-char backlog drains in ~0.33s.
                    charsThisTick = max(3, backlog / 40)
                }

                let nextCount = min(shownCh + charsThisTick, totalCh)
                // String.prefix is O(n) on Substring index walk; for our
                // sizes (≤40 KB MarkdownTextView cap) this is fine.
                self.streamingContent = String(target.prefix(nextCount))

                try? await Task.sleep(nanoseconds: tick)
            }
            self.smoothPumpTask = nil
        }
    }

    /// Wait for the smooth pump to drain to the end of the target before
    /// committing the final message. Mirrors waitForRevealCompletion's role
    /// for the legacy single-blob typewriter path.
    @MainActor
    private func waitForSmoothPumpDrain() async {
        let deadline = Date().addingTimeInterval(30)
        while smoothPumpTask != nil && Date() < deadline {
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
    }

    /// SINGLE point in this file where a streaming message's content is committed.
    /// Called only from the .done event handler in sendMessageStreaming.
    @MainActor
    private func commitFinalAnswer(streamingMsgId: String, response: PredictionResponse?) async {
        guard let response else { return }
        stepProgressTask?.cancel(); stepProgressTask = nil
        progressTimerTask?.cancel(); progressTimerTask = nil

        if let idx = messages.lastIndex(where: { $0.id == streamingMsgId }) {
            // DONE-ONLY-MUTATION: the single point in this file where a streaming
            // message's content is committed. Enforced by StreamingPredictionServiceTests.
            messages[idx].content = capPersistedContent(response.answer)
            messages[idx].area = response.lifeArea
            messages[idx].advice = capPersistedContent(response.advice)
            messages[idx].executionTimeMs = response.executionTimeMs
            messages[idx].isStreaming = false
            if HistorySettingsManager.shared.isHistoryEnabled {
                dataManager.saveMessage(messages[idx])
            }
        }
        suggestedQuestions = response.followUpSuggestions
        streamingContent = ""
        cosmicProgressSteps = []
        isStreaming = false
        pendingFinalResponse = nil
    }

    /// Translate streaming progress events into cosmicProgressSteps entries.
    /// The startCosmicProgressTimer() fallback cycles canned messages every
    /// 1.5s; when real .progressStep events arrive they overwrite that single
    /// active step, so the timer becomes a no-op in practice.
    private func handleProgressEvent(_ event: StreamingPredictionService.StreamEvent) {
        switch event {
        case .progressStep(_, _, _, _, let displayKey, _):
            guard let key = displayKey else { return }
            let msg = LocalizedString.get(key)
            let step = CosmicProgressStep(text: msg, displayKey: key, isCompleted: false, isActive: true)
            withAnimation(.easeInOut(duration: 0.4)) {
                cosmicProgressSteps = [step]
            }
        default:
            return
        }
    }

    /// Mirror of the sync path's quota-error handling — drop both bubbles,
    /// buffer the query for replay, present the paywall.
    @MainActor
    private func handleQuotaErrorFromStream(
        quota: QuotaExhaustedError,
        streamingMsgId: String,
        userMessage: LocalChatMessage
    ) async {
        tearDownGenerationState(reason: .userStop)
        if let userIdx = messages.lastIndex(where: { $0.id == userMessage.id }) {
            messages.remove(at: userIdx)
            windowManager.remove(id: userMessage.id)
            dataManager.deleteMessage(userMessage)
        }
        pendingPostUpgradeQuery = lastSentQuery
        quotaError = QuotaErrorInfo(
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
            quotaDetails = serverMsg
        } else if quota.reason == "daily_limit_reached" {
            quotaDetails = "daily_limit_reached_tomorrow".localized
        } else if QuotaManager.isGuestEmail(userEmail) {
            quotaDetails = "sign_in_to_continue_asking".localized
        } else {
            quotaDetails = "upgrade_to_keep_going".localized
        }
        showQuotaSheet = true
    }

    /// Public cancel — wired to the Stop button in ChatInputBar.
    /// Idempotent; safe to call while no stream is active.
    func stopGeneration() {
        tearDownGenerationState(reason: .userStop)
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
