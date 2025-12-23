import XCTest
@testable import ios_app

final class NetworkClientTests: XCTestCase {
    
    var networkClient: NetworkClient!
    var mockURLSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        mockURLSession = MockURLSession()
        networkClient = NetworkClient(
            session: mockURLSession,
            baseURL: "http://localhost:8000",
            apiKey: "test_key"
        )
    }
    
    override func tearDown() {
        networkClient = nil
        mockURLSession = nil
        super.tearDown()
    }
    
    // MARK: - Success Cases
    
    func testRequest_Success_ReturnsDecodedResponse() async throws {
        // Given
        let expectedResponse = MockDataFactory.mockPredictionResponse()
        let jsonData = try JSONEncoder().encode(expectedResponse)
        mockURLSession.mockData = jsonData
        mockURLSession.mockStatusCode = 200
        
        // When
        let response: PredictionResponse = try await networkClient.request(
            endpoint: APIConfig.predict,
            method: "POST",
            body: MockDataFactory.validPredictionRequest()
        )
        
        // Then
        XCTAssertEqual(response.predictionId, expectedResponse.predictionId)
    }
    
    func testRequest_SetsCorrectHeaders() async throws {
        // Given
        let jsonData = try JSONEncoder().encode(MockDataFactory.mockPredictionResponse())
        mockURLSession.mockData = jsonData
        mockURLSession.mockStatusCode = 200
        
        // When
        let _: PredictionResponse = try await networkClient.request(
            endpoint: APIConfig.predict,
            method: "POST",
            body: MockDataFactory.validPredictionRequest()
        )
        
        // Then
        let request = mockURLSession.lastRequest
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "X-API-KEY"), "test_key")
    }
    
    func testRequest_EncodesBodyCorrectly() async throws {
        // Given
        let jsonData = try JSONEncoder().encode(MockDataFactory.mockPredictionResponse())
        mockURLSession.mockData = jsonData
        mockURLSession.mockStatusCode = 200
        let requestBody = MockDataFactory.validPredictionRequest()
        
        // When
        let _: PredictionResponse = try await networkClient.request(
            endpoint: APIConfig.predict,
            method: "POST",
            body: requestBody
        )
        
        // Then
        let sentData = mockURLSession.lastRequest?.httpBody
        XCTAssertNotNil(sentData)
    }
    
    // MARK: - Error Cases
    
    func testRequest_Unauthorized_ThrowsUnauthorizedError() async {
        // Given
        mockURLSession.mockStatusCode = 401
        mockURLSession.mockData = "{}".data(using: .utf8)!
        
        // When/Then
        do {
            let _: PredictionResponse = try await networkClient.request(
                endpoint: APIConfig.predict,
                method: "POST",
                body: MockDataFactory.validPredictionRequest()
            )
            XCTFail("Should throw unauthorized error")
        } catch NetworkError.unauthorized {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testRequest_ServerError_ThrowsServerError() async {
        // Given
        mockURLSession.mockStatusCode = 500
        mockURLSession.mockData = "{\"error\": \"Internal Server Error\"}".data(using: .utf8)!
        
        // When/Then
        do {
            let _: PredictionResponse = try await networkClient.request(
                endpoint: APIConfig.predict,
                method: "POST",
                body: nil
            )
            XCTFail("Should throw server error")
        } catch NetworkError.serverError(let message) {
            XCTAssertTrue(message.contains("500"))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testRequest_InvalidJSON_ThrowsDecodingError() async {
        // Given
        mockURLSession.mockStatusCode = 200
        mockURLSession.mockData = "Not valid JSON".data(using: .utf8)!
        
        // When/Then
        do {
            let _: PredictionResponse = try await networkClient.request(
                endpoint: APIConfig.predict,
                method: "POST",
                body: nil
            )
            XCTFail("Should throw decoding error")
        } catch NetworkError.decodingError {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testRequest_NoData_ThrowsNoDataError() async {
        // Given
        mockURLSession.mockStatusCode = 200
        mockURLSession.mockData = Data() // Empty data
        
        // When/Then
        do {
            let _: PredictionResponse = try await networkClient.request(
                endpoint: APIConfig.predict,
                method: "POST",
                body: nil
            )
            XCTFail("Should throw no data error")
        } catch NetworkError.noData {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testRequest_NetworkFailure_ThrowsError() async {
        // Given
        mockURLSession.mockError = URLError(.notConnectedToInternet)
        
        // When/Then
        do {
            let _: PredictionResponse = try await networkClient.request(
                endpoint: APIConfig.predict,
                method: "POST",
                body: nil
            )
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
}
