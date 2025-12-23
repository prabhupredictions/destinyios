import Foundation
@testable import ios_app

class MockPredictionService: PredictionServiceProtocol {
    
    // MARK: - Properties
    var mockResult: Result<PredictionResponse, Error>?
    var predictCallCount = 0
    var lastRequest: PredictionRequest?
    
    // MARK: - PredictionServiceProtocol
    func predict(request: PredictionRequest) async throws -> PredictionResponse {
        predictCallCount += 1
        lastRequest = request
        
        guard let result = mockResult else {
            throw NetworkError.noData
        }
        
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
    
    // MARK: - Test Helpers
    func reset() {
        mockResult = nil
        predictCallCount = 0
        lastRequest = nil
    }
}
