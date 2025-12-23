import XCTest
@testable import ios_app

// MARK: - Mock Data Factory
struct MockDataFactory {
    
    // MARK: Birth Data
    static func validBirthData() -> BirthData {
        BirthData(
            dob: "1994-07-01",
            time: "00:15",
            latitude: 18.4386,
            longitude: 79.1288,
            cityOfBirth: "Karimnagar"
        )
    }
    
    static func invalidBirthData() -> BirthData {
        BirthData(
            dob: "invalid-date",
            time: "99:99",
            latitude: 200.0,  // Invalid latitude
            longitude: -200.0, // Invalid longitude
            cityOfBirth: nil
        )
    }
    
    // MARK: Prediction Request
    static func validPredictionRequest() -> PredictionRequest {
        PredictionRequest(
            query: "How is my career in 2025?",
            birthData: validBirthData(),
            platform: "ios",
            includeReasoningTrace: false
        )
    }
    
    // MARK: Prediction Response (Matches verified API output)
    static func mockPredictionResponse() -> PredictionResponse {
        PredictionResponse(
            predictionId: "pred_test123",
            sessionId: "sess_test456",
            conversationId: "conv_test789",
            status: "completed",
            answer: "Based on your chart analysis...",
            answerSummary: "**VERDICT:** Likely High Probability (High)",
            timing: TimingPrediction(
                period: "2025, 2026, 2025",
                dasha: nil,
                transit: nil,
                confidence: "MEDIUM"
            ),
            confidence: 0.5,
            confidenceLabel: "MEDIUM",
            supportingFactors: ["Strong planetary placements indicated", "Benefic influences present"],
            challengingFactors: ["Malefic influences affect the area"],
            followUpSuggestions: [
                "Tell me more about my chart",
                "What are the positive aspects of my chart?",
                "What should I focus on this year?"
            ],
            lifeArea: "general",
            executionTimeMs: 8991,
            createdAt: "2025-12-23T08:34:54.327489"
        )
    }
    
    // MARK: Chat Thread (Matches verified API output)
    static func mockChatThread() -> ChatThread {
        ChatThread(
            id: "conv_test123",
            title: "Career question",
            preview: "Based on your chart...",
            area: "career",
            messageCount: 2,
            updatedAt: "2025-12-23T08:38:11.570933"
        )
    }
}

// MARK: - XCTestCase Extensions
extension XCTestCase {
    
    /// Wait for async operation with timeout
    func waitForAsync(
        timeout: TimeInterval = 5.0,
        description: String = "Async operation",
        operation: @escaping () async throws -> Void
    ) {
        let expectation = expectation(description: description)
        
        Task {
            do {
                try await operation()
                expectation.fulfill()
            } catch {
                XCTFail("Async operation failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: timeout)
    }
}
