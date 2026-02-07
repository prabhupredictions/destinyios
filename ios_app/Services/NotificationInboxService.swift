import Foundation
import Combine
import SwiftUI

/// Service for managing in-app notification inbox
/// Handles fetching, reading, and tracking notifications from backend
final class NotificationInboxService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = NotificationInboxService()
    
    // MARK: - Published Properties
    @Published var notifications: [NotificationItem] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var hasMore: Bool = false
    
    // MARK: - Private Properties
    private var currentPage: Int = 1
    private let pageSize: Int = 20
    private let networkClient: NetworkClientProtocol
    
    // MARK: - Init
    private init(networkClient: NetworkClientProtocol = NetworkClient()) {
        self.networkClient = networkClient
    }
    
    // MARK: - Public Methods
    
    /// Fetch notifications for current user
    /// - Parameters:
    ///   - refresh: If true, resets pagination and fetches from page 1
    func fetchNotifications(refresh: Bool = false) async {
        guard let userEmail = UserDefaults.standard.string(forKey: "userEmail") else {
            await MainActor.run { self.error = "User not authenticated" }
            return
        }
        
        if refresh {
            await MainActor.run {
                self.currentPage = 1
                self.notifications = []
            }
        }
        
        await MainActor.run { self.isLoading = true }
        
        do {
            let endpoint = "\(APIConfig.baseURL)/notifications?user_email=\(userEmail)&page=\(currentPage)&page_size=\(pageSize)"
            
            guard let url = URL(string: endpoint) else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let decoded = try JSONDecoder().decode(NotificationListResponse.self, from: data)
            
            await MainActor.run {
                if refresh {
                    self.notifications = decoded.notifications
                } else {
                    self.notifications.append(contentsOf: decoded.notifications)
                }
                self.hasMore = decoded.hasMore
                self.isLoading = false
                self.error = nil
            }
            
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
            print("❌ Failed to fetch notifications: \(error)")
        }
    }
    
    /// Load more notifications (pagination)
    func loadMore() async {
        guard !isLoading && hasMore else { return }
        currentPage += 1
        await fetchNotifications(refresh: false)
    }
    
    /// Fetch unread count for badge
    func fetchUnreadCount() async {
        guard let userEmail = UserDefaults.standard.string(forKey: "userEmail") else { return }
        
        do {
            let endpoint = "\(APIConfig.baseURL)/notifications/unread-count?user_email=\(userEmail)"
            
            guard let url = URL(string: endpoint) else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            
            let decoded = try JSONDecoder().decode(UnreadCountResponse.self, from: data)
            
            await MainActor.run {
                self.unreadCount = decoded.count
            }
            
        } catch {
            print("❌ Failed to fetch unread count: \(error)")
        }
    }
    
    /// Mark a single notification as read
    func markAsRead(_ notificationId: String) async {
        do {
            let endpoint = "\(APIConfig.baseURL)/notifications/\(notificationId)/read"
            
            guard let url = URL(string: endpoint) else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            
            let decoded = try JSONDecoder().decode(MarkReadResponse.self, from: data)
            
            if decoded.success {
                await MainActor.run {
                    // Update local state
                    if let index = self.notifications.firstIndex(where: { $0.id == notificationId }) {
                        var updated = self.notifications[index]
                        // Create new item with read = true
                        let readItem = NotificationItem(
                            id: updated.id,
                            type: updated.type,
                            channel: updated.channel,
                            subject: updated.subject,
                            preview: updated.preview,
                            status: "READ",
                            read: true,
                            createdAt: updated.createdAt,
                            readAt: ISO8601DateFormatter().string(from: Date())
                        )
                        self.notifications[index] = readItem
                    }
                    self.unreadCount = max(0, self.unreadCount - 1)
                }
            }
            
        } catch {
            print("❌ Failed to mark as read: \(error)")
        }
    }
    
    /// Mark all notifications as read
    func markAllAsRead() async {
        guard let userEmail = UserDefaults.standard.string(forKey: "userEmail") else { return }
        
        do {
            let endpoint = "\(APIConfig.baseURL)/notifications/read-all?user_email=\(userEmail)"
            
            guard let url = URL(string: endpoint) else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            
            await MainActor.run {
                // Update all local notifications to read
                self.notifications = self.notifications.map { item in
                    NotificationItem(
                        id: item.id,
                        type: item.type,
                        channel: item.channel,
                        subject: item.subject,
                        preview: item.preview,
                        status: "READ",
                        read: true,
                        createdAt: item.createdAt,
                        readAt: ISO8601DateFormatter().string(from: Date())
                    )
                }
                self.unreadCount = 0
            }
            
        } catch {
            print("❌ Failed to mark all as read: \(error)")
        }
    }
}
