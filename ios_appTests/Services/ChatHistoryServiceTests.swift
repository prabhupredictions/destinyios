import XCTest
@testable import ios_app

final class ChatHistoryServiceTests: XCTestCase {
    
    var mockNetworkClient: MockNetworkClient!
    var chatHistoryService: ChatHistoryService!
    
    override func setUp() {
        super.setUp()
        mockNetworkClient = MockNetworkClient()
        chatHistoryService = ChatHistoryService(networkClient: mockNetworkClient)
    }
    
    override func tearDown() {
        mockNetworkClient = nil
        chatHistoryService = nil
        super.tearDown()
    }
    
    func testGetThreads_Success_ReturnsThreads() async throws {
        // Given
        let response = ChatHistoryResponse(threads: [MockDataFactory.mockChatThread()])
        mockNetworkClient.mockResponse = response
        
        // When
        let threads = try await chatHistoryService.getThreads(userID: "test@example.com")
        
        // Then
        XCTAssertEqual(threads.count, 1)
        XCTAssertEqual(threads[0].title, "Career question")
    }
    
    func testGetThreads_CallsCorrectEndpoint() async throws {
        // Given
        mockNetworkClient.mockResponse = ChatHistoryResponse(threads: [])
        let userID = "test@example.com"
        
        // When
        _ = try await chatHistoryService.getThreads(userID: userID)
        
        // Then
        let endpoint = mockNetworkClient.requestHistory[0].endpoint
        XCTAssertTrue(endpoint.contains(APIConfig.chatHistory))
        XCTAssertTrue(endpoint.contains(userID))
    }
    
    func testGetThreads_NetworkError_Throws() async {
        // Given
        mockNetworkClient.mockError = NetworkError.serverError("500")
        
        // When/Then
        do {
            _ = try await chatHistoryService.getThreads(userID: "test@example.com")
            XCTFail("Should throw")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    func testDeleteThread_Success_NoError() async throws {
        // Given
        mockNetworkClient.mockResponse = EmptyResponse()
        
        // When/Then - should not throw
        try await chatHistoryService.deleteThread(userID: "test@example.com", threadID: "thread_123")
        
        // Verify endpoint
        let endpoint = mockNetworkClient.requestHistory[0].endpoint
        XCTAssertTrue(endpoint.contains("thread_123"))
        XCTAssertEqual(mockNetworkClient.requestHistory[0].method, "DELETE")
    }
}
