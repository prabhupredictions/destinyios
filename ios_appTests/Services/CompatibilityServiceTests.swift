import XCTest
@testable import ios_app

final class CompatibilityServiceTests: XCTestCase {
    
    var mockNetworkClient: MockNetworkClient!
    var compatibilityService: CompatibilityService!
    
    override func setUp() {
        super.setUp()
        mockNetworkClient = MockNetworkClient()
        compatibilityService = CompatibilityService(networkClient: mockNetworkClient)
    }
    
    override func tearDown() {
        mockNetworkClient = nil
        compatibilityService = nil
        super.tearDown()
    }
    
    func testAnalyze_Success_ReturnsResponse() async throws {
        // Given
        let expectedResponse = CompatibilityResponse(sessionId: "sess_123", status: "success")
        mockNetworkClient.mockResponse = expectedResponse
        let request = CompatibilityRequest(
            boy: BirthDetails(dob: "1994-07-01", time: "00:15", lat: 18.4386, lon: 79.1288),
            girl: BirthDetails(dob: "1996-04-20", time: "04:45", lat: 34.0522, lon: -118.2437)
        )
        
        // When
        let response = try await compatibilityService.analyze(request: request)
        
        // Then
        XCTAssertEqual(response.status, "success")
    }
    
    func testAnalyze_CallsCorrectEndpoint() async throws {
        // Given
        mockNetworkClient.mockResponse = CompatibilityResponse(sessionId: nil, status: "success")
        
        // When
        _ = try await compatibilityService.analyze(request: CompatibilityRequest(
            boy: BirthDetails(dob: "1994-07-01", time: "00:15", lat: 18.4386, lon: 79.1288),
            girl: BirthDetails(dob: "1996-04-20", time: "04:45", lat: 34.0522, lon: -118.2437)
        ))
        
        // Then
        XCTAssertEqual(mockNetworkClient.requestHistory[0].endpoint, APIConfig.compatibility)
    }
    
    func testAnalyze_NetworkError_Throws() async {
        // Given
        mockNetworkClient.mockError = NetworkError.serverError("500")
        
        // When/Then
        do {
            _ = try await compatibilityService.analyze(request: CompatibilityRequest(
                boy: BirthDetails(dob: "1994-07-01", time: "00:15", lat: 18.4386, lon: 79.1288),
                girl: BirthDetails(dob: "1996-04-20", time: "04:45", lat: 34.0522, lon: -118.2437)
            ))
            XCTFail("Should throw")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    func testAnalyze_Unauthorized_Throws() async {
        // Given
        mockNetworkClient.mockError = NetworkError.unauthorized
        
        // When/Then
        do {
            _ = try await compatibilityService.analyze(request: CompatibilityRequest(
                boy: BirthDetails(dob: "1994-07-01", time: "00:15", lat: 18.4386, lon: 79.1288),
                girl: BirthDetails(dob: "1996-04-20", time: "04:45", lat: 34.0522, lon: -118.2437)
            ))
            XCTFail("Should throw")
        } catch NetworkError.unauthorized {
            // Expected
        } catch {
            XCTFail("Wrong error type")
        }
    }
}
