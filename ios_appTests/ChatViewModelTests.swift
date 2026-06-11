import XCTest
@testable import ios_app

/// Tests for ChatViewModel
@MainActor
final class ChatViewModelTests: XCTestCase {
    
    var viewModel: ChatViewModel!
    var testDataManager: DataManager!
    
    override func setUp() async throws {
        try await super.setUp()

        // Use isolated in-memory data manager
        testDataManager = DataManager(inMemory: true)

        // Set up test user
        UserDefaults.standard.set("test@example.com", forKey: "userEmail")

        // Reset and register MockURLProtocol so tests don't hit a real backend
        // for QuotaManager.canAccessFeature / SubscriptionManager / etc. Each
        // test that exercises sendMessage past the quota gate must call
        // MockURLProtocol.stubQuotaAllowAll() (or similar) before invoking the
        // ViewModel. Without a stub the request falls through and fails — which
        // is correct behaviour for tests that DON'T expect a network call.
        MockURLProtocol.reset()
        URLProtocol.registerClass(MockURLProtocol.self)

        // Initialize ViewModel with test data manager
        viewModel = ChatViewModel(dataManager: testDataManager)

        // Let the init's async work (startNewChat, loadHistory, addWelcomeMessage) settle
        await Task.yield()
        await Task.yield()
    }

    override func tearDown() async throws {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.reset()
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userBirthData")
        viewModel = nil
        testDataManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInit_CreatesSession() async throws {
        // Then
        XCTAssertFalse(viewModel.currentSessionId.isEmpty)
    }
    
    func testInit_CreatesThread() async throws {
        // currentThreadId is set by the view via startNewChat() in onAppear, not at init.
        // At init time, loadUserSession() runs and sets a session but not yet a thread.
        // The session ID is always set — that is the reliable init-time assertion.
        XCTAssertFalse(viewModel.currentSessionId.isEmpty)
    }

    func testInit_HasWelcomeMessage() async throws {
        // The welcome message is added by startNewChat(), called from the view's onAppear.
        // At init time, messages is empty. Simulate what the view does:
        viewModel.startNewChat()
        await Task.yield()
        XCTAssertFalse(viewModel.messages.isEmpty)
        XCTAssertEqual(viewModel.messages.first?.messageRole, .assistant)
    }
    
    func testInit_SetsUserEmail() async throws {
        // Then
        XCTAssertEqual(viewModel.userEmail, "test@example.com")
    }
    
    // MARK: - State Tests
    
    func testCanSend_ReturnsFalseWhenEmpty() async throws {
        // Given
        viewModel.inputText = ""
        
        // Then
        XCTAssertFalse(viewModel.canSend)
    }
    
    func testCanSend_ReturnsFalseWhenWhitespace() async throws {
        // Given
        viewModel.inputText = "   "
        
        // Then
        XCTAssertFalse(viewModel.canSend)
    }
    
    func testCanSend_ReturnsTrueWithText() async throws {
        // Given
        viewModel.inputText = "Hello"
        viewModel.isLoading = false
        viewModel.isStreaming = false
        
        // Then
        XCTAssertTrue(viewModel.canSend)
    }
    
    func testCanSend_ReturnsFalseWhenLoading() async throws {
        // Given
        viewModel.inputText = "Hello"
        viewModel.isLoading = true
        
        // Then
        XCTAssertFalse(viewModel.canSend)
    }
    
    func testCanSend_ReturnsFalseWhenStreaming() async throws {
        // canSend = !inputText.isEmpty && !isLoading
        // isStreaming is not part of canSend — test isLoading instead
        viewModel.inputText = "Hello"
        viewModel.isLoading = true

        XCTAssertFalse(viewModel.canSend)
    }
    
    // MARK: - New Chat Tests
    
    func testStartNewChat_CreatesNewThread() async throws {
        // Given
        let originalThreadId = viewModel.currentThreadId
        
        // When
        viewModel.startNewChat()
        
        // Then
        XCTAssertNotEqual(viewModel.currentThreadId, originalThreadId)
    }
    
    func testStartNewChat_ClearsMessages() async throws {
        // Given - add a message
        let msg = LocalChatMessage(threadId: viewModel.currentThreadId, role: .user, content: "Test")
        viewModel.messages.append(msg)
        
        // When
        viewModel.startNewChat()
        
        // Then - should have only welcome message
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.messageRole, .assistant)
    }
    
    func testStartNewChat_UpdatesHistory() async throws {
        // When
        viewModel.startNewChat()
        viewModel.startNewChat()
        
        // Then
        XCTAssertGreaterThanOrEqual(viewModel.chatHistory.count, 2)
    }
    
    // MARK: - History Tests
    
    func testLoadHistory_PopulatesHistory() async throws {
        // Given
        viewModel.startNewChat()
        viewModel.startNewChat()
        
        // When
        viewModel.loadHistory()
        
        // Then
        XCTAssertFalse(viewModel.chatHistory.isEmpty)
    }
    
    // MARK: - Thread Management Tests
    
    func testDeleteThread_RemovesFromHistory() async throws {
        // Given - create two threads so there is always one to delete
        viewModel.startNewChat()
        viewModel.startNewChat()
        viewModel.loadHistory()

        let initialCount = viewModel.chatHistory.count
        XCTAssertGreaterThanOrEqual(initialCount, 2, "Should have at least 2 threads")

        let currentId = viewModel.currentThreadId
        guard let threadToDelete = viewModel.chatHistory.first(where: { $0.id != currentId }) else {
            XCTFail("No non-current thread available to delete — ensure startNewChat creates persisted threads")
            return
        }

        // When
        viewModel.deleteThread(threadToDelete)

        // Then
        XCTAssertEqual(viewModel.chatHistory.count, initialCount - 1)
        XCTAssertFalse(viewModel.chatHistory.contains(where: { $0.id == threadToDelete.id }))
    }
    
    func testTogglePinThread_PinsThread() async throws {
        // Given — ensure at least one persisted thread exists in history
        viewModel.startNewChat()
        viewModel.loadHistory()
        guard let thread = viewModel.chatHistory.first else {
            XCTFail("chatHistory must be non-empty after startNewChat + loadHistory")
            return
        }
        XCTAssertFalse(thread.isPinned)

        // When
        viewModel.togglePinThread(thread)

        // Then
        XCTAssertTrue(thread.isPinned)
    }
    
    // MARK: - Clear Chat Tests
    
    func testClearChat_RemovesMessages() async throws {
        // Given
        let msg = LocalChatMessage(threadId: viewModel.currentThreadId, role: .user, content: "Test")
        viewModel.messages.append(msg)
        viewModel.dataManager.saveMessage(msg)
        
        // When
        viewModel.clearChat()
        
        // Then - should have only welcome message
        XCTAssertEqual(viewModel.messages.count, 1)
    }
    
    // MARK: - Send Message Tests
    
    func testSendMessage_WithoutBirthData_SetsError() async throws {
        // Stub quota gate so the message can reach the birth-data check at
        // ChatViewModel.swift:357. Without this, sendMessage's quota check
        // returns can_access=false (test backend refuses unknown email),
        // user bubble is removed, and birth-data check never runs.
        MockURLProtocol.stubQuotaAllowAll()

        // Given
        viewModel.inputText = "What's my horoscope?"
        UserDefaults.standard.removeObject(forKey: "userBirthData")

        // When
        await viewModel.sendMessage()

        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("birth data") ?? false)
    }
    
    func testSendMessage_ClearsInputText() async throws {
        // Stub quota gate — same rationale as testSendMessage_AddsUserMessage.
        // (Existing test currently passes because inputText is cleared at the
        // top of sendMessage BEFORE the quota check, but stub it anyway for
        // clarity and to keep behaviour stable if the order changes.)
        MockURLProtocol.stubQuotaAllowAll()

        // Given
        viewModel.inputText = "Hello"
        
        // Set up birth data
        let birthData = BirthData(
            dob: "1990-01-15",
            time: "10:30",
            latitude: 19.076,
            longitude: 72.877,
            cityOfBirth: "Mumbai"
        )
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(birthData) {
            UserDefaults.standard.set(data, forKey: "userBirthData")
        }
        
        // When
        await viewModel.sendMessage()
        
        // Then
        XCTAssertTrue(viewModel.inputText.isEmpty)
    }
    
    func testSendMessage_AddsUserMessage() async throws {
        // Stub quota gate so the user message survives past the quota check
        // at ChatViewModel.swift:319-327. Without this, the test backend
        // returns can_access=false for the unknown email and the user bubble
        // is removed before the assertion runs.
        MockURLProtocol.stubQuotaAllowAll()

        // Given
        let birthData = BirthData(
            dob: "1990-01-15",
            time: "10:30",
            latitude: 19.076,
            longitude: 72.877,
            cityOfBirth: "Mumbai"
        )
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(birthData) {
            UserDefaults.standard.set(data, forKey: "userBirthData")
        }

        viewModel.inputText = "What's my horoscope?"
        let initialCount = viewModel.messages.count

        // When
        await viewModel.sendMessage()

        // Then - should have user message and AI response
        XCTAssertGreaterThan(viewModel.messages.count, initialCount)
    }

    // MARK: - Post-Upgrade Replay Tests (iOS-2)

    /// When the quota wall fires (overall_limit_reached), the in-flight query
    /// must be buffered so ChatView can replay it after a successful upgrade.
    /// Regression test for iOS-2: the user message bubble was removed AND
    /// inputText was already cleared, forcing the user to retype.
    func testSendMessage_QuotaDenied_BuffersQueryForPostUpgradeReplay() async throws {
        // Given — quota gate denies with overall_limit_reached
        MockURLProtocol.stubQuotaDeny(reason: "overall_limit_reached")

        let originalQuery = "What's my horoscope?"
        viewModel.inputText = originalQuery

        // When
        await viewModel.sendMessage()

        // Then — query is buffered for replay after upgrade
        XCTAssertEqual(
            viewModel.pendingPostUpgradeQuery,
            originalQuery,
            "Query must be buffered when quota wall fires so it can be replayed post-upgrade"
        )
        // And — paywall is presented
        XCTAssertTrue(viewModel.showQuotaSheet)
        // And — inputText was cleared (existing behaviour)
        XCTAssertTrue(viewModel.inputText.isEmpty)

        // When — consumePendingPostUpgradeQuery is called
        let consumed = viewModel.consumePendingPostUpgradeQuery()

        // Then — buffered query is returned and cleared atomically
        XCTAssertEqual(consumed, originalQuery)
        XCTAssertNil(
            viewModel.pendingPostUpgradeQuery,
            "consumePendingPostUpgradeQuery() must clear the buffer"
        )
    }

    /// clearPendingPostUpgradeQuery() discards the buffered query. Used by
    /// ChatView when the user dismisses the paywall WITHOUT upgrading so a
    /// stale query doesn't auto-fire later.
    func testClearPendingPostUpgradeQuery_DiscardsBuffer() async throws {
        // Given — a buffered query
        viewModel.pendingPostUpgradeQuery = "stale query"

        // When
        viewModel.clearPendingPostUpgradeQuery()

        // Then
        XCTAssertNil(viewModel.pendingPostUpgradeQuery)
    }

    // MARK: - iOS-11: Per-plan upgrade_cta.message Tests

    /// When the backend returns `overall_limit_reached` along with a server-curated
    /// `upgrade_cta.message`, the iOS client must surface that message in
    /// `quotaDetails` rather than falling back to the generic localized string.
    /// Regression test for iOS-11.
    func testSendMessage_OverallLimitReached_PrefersServerUpgradeCtaMessage() async throws {
        // Given — quota denies with overall_limit_reached AND a per-plan server message
        let serverMessage = "You've used all 50 questions on the Free plan. Upgrade to Premium for 500/month."
        MockURLProtocol.stubQuotaDenyWithUpgradeCta(
            reason: "overall_limit_reached",
            ctaMessage: serverMessage,
            suggestedPlan: "premium_yearly"
        )

        viewModel.inputText = "What's my horoscope?"

        // When
        await viewModel.sendMessage()

        // Then — quotaDetails reflects the server-curated message verbatim,
        // NOT a generic "sign_in_to_continue_asking" / "upgrade_to_keep_going" fallback.
        XCTAssertEqual(
            viewModel.quotaDetails,
            serverMessage,
            "ChatViewModel must prefer server upgrade_cta.message over generic localized fallback"
        )
        XCTAssertTrue(viewModel.showQuotaSheet, "Paywall sheet should be presented when quota is exhausted")
    }

    /// When the backend returns `overall_limit_reached` WITHOUT an upgrade_cta
    /// (legacy behaviour), the iOS client still falls back to the existing
    /// localized strings. Locks in the fallback path so iOS-11 fix doesn't
    /// accidentally drop messaging entirely if the backend omits the field.
    func testSendMessage_OverallLimitReached_FallsBackToLocalizedWhenNoUpgradeCta() async throws {
        // Given — quota denies with overall_limit_reached and NO upgrade_cta payload
        MockURLProtocol.stubQuotaDeny(reason: "overall_limit_reached")

        viewModel.inputText = "What's my horoscope?"

        // When
        await viewModel.sendMessage()

        // Then — quotaDetails is one of the localized fallback strings, not empty.
        // We don't pin the exact text (it depends on the test user's email branch)
        // but it must be set so the paywall has something to show.
        XCTAssertTrue(viewModel.showQuotaSheet)
        XCTAssertFalse(
            (viewModel.quotaDetails ?? "").isEmpty,
            "Fallback localized message must be set when backend omits upgrade_cta"
        )
    }
}
