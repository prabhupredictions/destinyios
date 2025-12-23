import Foundation
@testable import ios_app

final class MockURLSession: URLSessionProtocol {
    
    // MARK: - Mock Data
    var mockData: Data?
    var mockStatusCode: Int = 200
    var mockError: Error?
    var lastRequest: URLRequest?
    
    // MARK: - URLSessionProtocol
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        
        if let error = mockError {
            throw error
        }
        
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: mockStatusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        
        return (mockData ?? Data(), response)
    }
    
    // MARK: - Helpers
    func reset() {
        mockData = nil
        mockStatusCode = 200
        mockError = nil
        lastRequest = nil
    }
}
