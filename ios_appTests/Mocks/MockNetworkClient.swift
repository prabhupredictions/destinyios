import Foundation
@testable import ios_app

class MockNetworkClient: NetworkClientProtocol {
    
    // MARK: - Properties
    var mockResponse: Any?
    var mockError: Error?
    var requestHistory: [(endpoint: String, method: String, body: Any?)] = []
    
    // MARK: - NetworkClientProtocol
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        
        // Record request
        requestHistory.append((endpoint, method, body))
        
        // Throw error if set
        if let error = mockError {
            throw error
        }
        
        // Return mock response
        guard let response = mockResponse as? T else {
            throw NetworkError.noData
        }
        
        return response
    }
    
    // MARK: - Test Helpers
    func reset() {
        mockResponse = nil
        mockError = nil
        requestHistory.removeAll()
    }
}
