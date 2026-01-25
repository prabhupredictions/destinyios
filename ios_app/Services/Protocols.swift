import Foundation

// MARK: - Network Client Protocol
protocol NetworkClientProtocol {
    func request<T: Decodable>(
        endpoint: String,
        method: String,
        body: Encodable?
    ) async throws -> T
}

// MARK: - Prediction Service Protocol
protocol PredictionServiceProtocol {
    func predict(request: PredictionRequest) async throws -> PredictionResponse
    func getTodaysPrediction(request: UserAstroDataRequest) async throws -> TodaysPredictionResponse
}

// MARK: - Compatibility Service Protocol
protocol CompatibilityServiceProtocol {
    func analyze(request: CompatibilityRequest) async throws -> CompatibilityResponse
    func analyzeStream(request: CompatibilityRequest) async throws -> CompatibilityResponse
    func followUp(request: CompatibilityFollowUpRequest) async throws -> CompatibilityFollowUpResponse
}

// MARK: - Chat History Service Protocol
protocol ChatHistoryServiceProtocol {
    func getThreads(userID: String) async throws -> [ChatThread]
    func getThread(userID: String, threadID: String) async throws -> ChatThread
    func deleteThread(userID: String, threadID: String) async throws
}

// MARK: - Feedback Service Protocol
protocol FeedbackServiceProtocol {
    func submit(request: FeedbackRequest) async throws
}

// MARK: - Auth Service Protocol
protocol AuthServiceProtocol {
    func signInWithApple() async throws -> User
    @MainActor func signInWithGoogle() async throws -> User
    func signInAsGuest() async -> User
    func signOut() async
}

// MARK: - URLSession Protocol (for testing)
protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}
