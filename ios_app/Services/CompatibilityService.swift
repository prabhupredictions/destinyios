import Foundation

final class CompatibilityService: CompatibilityServiceProtocol {
    
    private let networkClient: NetworkClientProtocol
    
    init(networkClient: NetworkClientProtocol = NetworkClient()) {
        self.networkClient = networkClient
    }
    
    func analyze(request: CompatibilityRequest) async throws -> CompatibilityResponse {
        try await networkClient.request(
            endpoint: APIConfig.compatibility,
            method: "POST",
            body: request
        )
    }
}
