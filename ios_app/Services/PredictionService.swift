import Foundation

final class PredictionService: PredictionServiceProtocol {
    
    // MARK: - Properties
    private let networkClient: NetworkClientProtocol
    
    // MARK: - Init
    init(networkClient: NetworkClientProtocol = NetworkClient()) {
        self.networkClient = networkClient
    }
    
    // MARK: - PredictionServiceProtocol
    func predict(request: PredictionRequest) async throws -> PredictionResponse {
        try await networkClient.request(
            endpoint: APIConfig.predict,
            method: "POST",
            body: request
        )
    }
    
    func getTodaysPrediction(request: UserAstroDataRequest) async throws -> TodaysPredictionResponse {
        try await networkClient.request(
            endpoint: APIConfig.todaysPrediction,
            method: "POST",
            body: request
        )
    }
}
