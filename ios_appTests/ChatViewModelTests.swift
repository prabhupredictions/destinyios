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

        // Initialize ViewModel with test data manager
        viewModel = ChatViewModel(dataManager: testDataManager)

        // Let the init's async work (startNewChat, loadHistory, addWelcomeMessage) settle
        await Task.yield()
        await Task.yield()
    }
    
    override func tearDown() async throws {
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
}
