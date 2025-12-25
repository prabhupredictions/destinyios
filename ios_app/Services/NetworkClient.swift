import Foundation

final class NetworkClient: NetworkClientProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    private let session: URLSessionProtocol
    private let baseURL: String
    private let apiKey: String
    
    // MARK: - Init
    init(
        session: URLSessionProtocol = URLSession.shared,
        baseURL: String = APIConfig.baseURL,
        apiKey: String = APIConfig.apiKey
    ) {
        self.session = session
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
    
    // MARK: - NetworkClientProtocol
    func request<T: Decodable>(
        endpoint: String,
        method: String,
        body: Encodable?
    ) async throws -> T {
        
        // Build URL
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        // Build Request
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Encode body (models have CodingKeys for snake_case)
        if let body = body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        }
        
        // Execute request
        let (data, response) = try await session.data(for: request)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        // Handle status codes
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw NetworkError.unauthorized
        case 400...499:
            throw NetworkError.serverError("Client Error: \(httpResponse.statusCode)")
        case 500...599:
            throw NetworkError.serverError("Server Error: \(httpResponse.statusCode)")
        default:
            throw NetworkError.serverError("Unknown Error: \(httpResponse.statusCode)")
        }
        
        // Check data
        guard !data.isEmpty else {
            throw NetworkError.noData
        }
        
        // Decode response (models have CodingKeys for snake_case)
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}
