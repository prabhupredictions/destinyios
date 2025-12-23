import Foundation

struct ChatHistoryResponse: Codable {
    let threads: [ChatThread]
}

struct EmptyResponse: Codable {}

final class ChatHistoryService: ChatHistoryServiceProtocol {
    
    private let networkClient: NetworkClientProtocol
    
    init(networkClient: NetworkClientProtocol = NetworkClient()) {
        self.networkClient = networkClient
    }
    
    func getThreads(userID: String) async throws -> [ChatThread] {
        let response: ChatHistoryResponse = try await networkClient.request(
            endpoint: "\(APIConfig.chatHistory)/threads/\(userID)",
            method: "GET",
            body: nil
        )
        return response.threads
    }
    
    func getThread(userID: String, threadID: String) async throws -> ChatThread {
        try await networkClient.request(
            endpoint: "\(APIConfig.chatHistory)/threads/\(userID)/\(threadID)",
            method: "GET",
            body: nil
        )
    }
    
    func deleteThread(userID: String, threadID: String) async throws {
        let _: EmptyResponse = try await networkClient.request(
            endpoint: "\(APIConfig.chatHistory)/threads/\(userID)/\(threadID)",
            method: "DELETE",
            body: nil
        )
    }
}
