import XCTest
@testable import ios_app

final class PredictionServiceTests: XCTestCase {
    
    var mockNetworkClient: MockNetworkClient!
    var predictionService: PredictionService!
    
    override func setUp() {
        super.setUp()
        mockNetworkClient = MockNetworkClient()
        predictionService = PredictionService(networkClient: mockNetworkClient)
    }
    
    override func tearDown() {
        mockNetworkClient = nil
        predictionService = nil
        super.tearDown()
    }
    
    // MARK: - Success Cases
    
    func testPredict_Success_ReturnsPredictionResponse() async throws {
        // Given
        let expectedResponse = MockDataFactory.mockPredictionResponse()
        mockNetworkClient.mockResponse = expectedResponse
        let request = MockDataFactory.validPredictionRequest()
        
        // When
        let response = try await predictionService.predict(request: request)
        
        // Then
        XCTAssertEqual(response.predictionId, expectedResponse.predictionId)
        XCTAssertEqual(response.answer, expectedResponse.answer)
    }
    
    func testPredict_CallsCorrectEndpoint() async throws {
        // Given
        mockNetworkClient.mockResponse = MockDataFactory.mockPredictionResponse()
        
        // When
        _ = try await predictionService.predict(request: MockDataFactory.validPredictionRequest())
        
        // Then
        XCTAssertEqual(mockNetworkClient.requestHistory.count, 1)
        XCTAssertEqual(mockNetworkClient.requestHistory[0].endpoint, APIConfig.predict)
        XCTAssertEqual(mockNetworkClient.requestHistory[0].method, "POST")
    }
    
    func testPredict_PassesRequestBody() async throws {
        // Given
        mockNetworkClient.mockResponse = MockDataFactory.mockPredictionResponse()
        let request = MockDataFactory.validPredictionRequest()
        
        // When
        _ = try await predictionService.predict(request: request)
        
        // Then
        XCTAssertNotNil(mockNetworkClient.requestHistory[0].body)
    }
    
    // MARK: - Error Cases
    
    func testPredict_NetworkError_Throws() async {
        // Given
        mockNetworkClient.mockError = NetworkError.serverError("500")
        
        // When/Then
        do {
            _ = try await predictionService.predict(request: MockDataFactory.validPredictionRequest())
            XCTFail("Should throw")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    func testPredict_Unauthorized_Throws() async {
        // Given
        mockNetworkClient.mockError = NetworkError.unauthorized
        
        // When/Then
        do {
            _ = try await predictionService.predict(request: MockDataFactory.validPredictionRequest())
            XCTFail("Should throw")
        } catch NetworkError.unauthorized {
            // Expected
        } catch {
            XCTFail("Wrong error type")
        }
    }
    
    func testPredict_NoData_Throws() async {
        // Given
        mockNetworkClient.mockError = NetworkError.noData
        
        // When/Then
        do {
            _ = try await predictionService.predict(request: MockDataFactory.validPredictionRequest())
            XCTFail("Should throw")
        } catch NetworkError.noData {
            // Expected
        } catch {
            XCTFail("Wrong error type")
        }
    }
}
