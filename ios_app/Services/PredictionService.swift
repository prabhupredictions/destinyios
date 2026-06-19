import Foundation

final class PredictionService: PredictionServiceProtocol {

    // MARK: - Properties
    private let networkClient: NetworkClientProtocol

    // MARK: - Init
    init(networkClient: NetworkClientProtocol = NetworkClient()) {
        self.networkClient = networkClient
    }

    /// W-fix: avoid Swift back-deploy main-actor teardown crash.
    /// When @MainActor HomeViewModel owns PredictionService which owns
    /// NetworkClient, Swift's swift_task_deinitOnExecutorMainActorBackDeploy
    /// shim corrupts libmalloc on dealloc:
    ///   ___BUG_IN_CLIENT_OF_LIBMALLOC_POINTER_BEING_FREED_WAS_NOT_ALLOCATED
    /// This is a known Swift Concurrency back-deploy bug on iOS 17+
    /// simulators with macOS 26 host. Marking deinit nonisolated bypasses
    /// the back-deploy shim. Same fix HomeViewModel already uses (line 7).
    nonisolated deinit {}

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
