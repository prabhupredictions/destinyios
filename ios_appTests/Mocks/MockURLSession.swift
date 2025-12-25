import Foundation
@testable import ios_app

actor MockURLSession: URLSessionProtocol {
    
    // MARK: - Mock Data
    private var mockData: Data?
    private var mockStatusCode: Int = 200
    private var mockError: Error?
    private(set) var lastRequest: URLRequest?
    
    init() {}
    
    // MARK: - Setters for Tests
    func setMockData(_ data: Data?) {
        mockData = data
    }
    
    func setMockStatusCode(_ code: Int) {
        mockStatusCode = code
    }
    
    func setMockError(_ error: Error?) {
        mockError = error
    }
    
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
