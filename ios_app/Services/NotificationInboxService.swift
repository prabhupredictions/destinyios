import Foundation
import Combine
import SwiftUI

/// Service for managing in-app notification inbox
/// Handles fetching, reading, and tracking notifications from backend
///
/// F2 (1.7) — class is now @MainActor isolated. Pre-fix this was a plain
/// final class : ObservableObject with state mutation split across multiple
/// `await MainActor.run` blocks, which left races on @Published properties
/// during refresh-while-loadMore (and contributed to the wishva.shah crash
/// repro: 5 chat deletes → inbox loaded twice → 2-min silence → crash). With
/// @MainActor isolation, all property reads/writes are serialized by Swift
/// and the redundant MainActor.run wrappers are removed.
@MainActor
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

    /// F2 — page number of the LAST successfully fetched page. Starts at 0
    /// (no pages fetched). Only advances after a successful append; cancellation
    /// or error never advances it, so a refresh-during-loadMore can't skip a page.
    private var currentPage: Int = 0
    private let pageSize: Int = 20
    private let networkClient: NetworkClientProtocol

    /// F2 — single in-flight fetch task. @MainActor isolation guarantees no
    /// races on this property.
    private var inflightFetchTask: Task<Void, Never>?

    // MARK: - Init
    private init(networkClient: NetworkClientProtocol = NetworkClient()) {
        self.networkClient = networkClient
    }

    // MARK: - Public Methods

    /// Fetch notifications for current user.
    /// - Parameters:
    ///   - refresh: If true, cancels any in-flight fetch and re-fetches from page 1.
    ///             If false and a fetch is already in flight, awaits its completion (dedup).
    func fetchNotifications(refresh: Bool = false) async {
        if refresh {
            // Refresh preempts any current fetch — cancel and start fresh.
            inflightFetchTask?.cancel()
            inflightFetchTask = nil
        } else if let inflight = inflightFetchTask {
            // Non-refresh call while a fetch is in flight — dedup by awaiting it.
            _ = await inflight.value
            return
        }

        let task = Task<Void, Never> { [weak self] in
            await self?.performFetch(refresh: refresh)
        }
        inflightFetchTask = task
        _ = await task.value
        // Clear slot only if it's still our task (a refresh may have replaced it).
        if inflightFetchTask == task {
            inflightFetchTask = nil
        }
    }

    /// F2 — performs the actual network fetch. Always runs on the main actor.
    /// currentPage is advanced ONLY on successful decode + append.
    private func performFetch(refresh: Bool) async {
        guard let userEmail = UserDefaults.standard.string(forKey: "userEmail") else {
            self.error = "User not authenticated"
            return
        }

        // Compute the page to request locally — do NOT mutate currentPage yet.
        let pageToRequest = refresh ? 1 : currentPage + 1

        self.isLoading = true

        do {
            let endpoint = "\(APIConfig.baseURL)/notifications?user_email=\(userEmail)&page=\(pageToRequest)&page_size=\(pageSize)"

            guard let url = URL(string: endpoint) else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(NetworkClient.authBearer(), forHTTPHeaderField: "Authorization")
            request.setValue(APIConfig.apiKey, forHTTPHeaderField: "X-API-Key")

            let (data, response) = try await URLSession.shared.data(for: request)

            // Honor cancellation observed during the await.
            try Task.checkCancellation()

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            let decoded = try JSONDecoder().decode(NotificationListResponse.self, from: data)

            // SUCCESS — mutate state and advance page atomically (single main-actor section).
            if refresh {
                self.notifications = decoded.notifications
            } else {
                self.notifications.append(contentsOf: decoded.notifications)
            }
            self.currentPage = pageToRequest // advance ONLY on success
            self.hasMore = decoded.hasMore
            self.isLoading = false
            self.error = nil

        } catch is CancellationError {
            // Swift's structured-concurrency cancellation. Don't surface as user error.
            self.isLoading = false
        } catch let urlError as URLError where urlError.code == .cancelled {
            // F2 (round-3 verifier fix) — URLSession.data(for:) throws URLError(.cancelled)
            // (code -999), NOT Swift's CancellationError, when the surrounding Task is
            // cancelled. Catch this explicitly so cancellation is invisible to the user.
            self.isLoading = false
        } catch {
            // Real failure — surface to UI.
            self.error = error.localizedDescription
            self.isLoading = false
            print("❌ Failed to fetch notifications: \(error)")
        }
    }

    /// Load more notifications (pagination)
    func loadMore() async {
        guard inflightFetchTask == nil, hasMore else { return }
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
            request.setValue(NetworkClient.authBearer(), forHTTPHeaderField: "Authorization")
            request.setValue(APIConfig.apiKey, forHTTPHeaderField: "X-API-Key")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            
            let decoded = try JSONDecoder().decode(UnreadCountResponse.self, from: data)

            // F2 (1.7) — class is @MainActor, no need for MainActor.run.
            self.unreadCount = decoded.count

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
            request.setValue(NetworkClient.authBearer(), forHTTPHeaderField: "Authorization")
            request.setValue(APIConfig.apiKey, forHTTPHeaderField: "X-API-Key")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            
            let decoded = try JSONDecoder().decode(MarkReadResponse.self, from: data)
            
            if decoded.success {
                // F4b (1.7) + F2 (@MainActor) — atomic single main-actor section.
                // Lookup index, mutate, and assign all happen synchronously here.
                // Guards against double-decrement on replay (e.g. server returns
                // success a second time).
                guard let index = self.notifications.firstIndex(where: { $0.id == notificationId }) else {
                    return
                }
                let updated = self.notifications[index]
                guard !updated.read else { return }
                let readItem = NotificationItem(
                    id: updated.id,
                    type: updated.type,
                    channel: updated.channel,
                    subject: updated.subject,
                    preview: updated.preview,
                    status: "READ",
                    read: true,
                    createdAt: updated.createdAt,
                    readAt: ISO8601DateFormatter().string(from: Date()),
                    actionUrl: updated.actionUrl,
                    imageUrl: updated.imageUrl,
                    chatPrompt: updated.chatPrompt,
                    topic: updated.topic,
                    overallTone: updated.overallTone
                )
                self.notifications[index] = readItem
                self.unreadCount = max(0, self.unreadCount - 1)
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
            request.setValue(NetworkClient.authBearer(), forHTTPHeaderField: "Authorization")
            request.setValue(APIConfig.apiKey, forHTTPHeaderField: "X-API-Key")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }

            // F2 (1.7) — class is @MainActor, no need for MainActor.run.
            // Update all local notifications to read.
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
                    readAt: ISO8601DateFormatter().string(from: Date()),
                    actionUrl: item.actionUrl,
                    imageUrl: item.imageUrl,
                    chatPrompt: item.chatPrompt,
                    topic: item.topic,
                    overallTone: item.overallTone
                )
            }
            self.unreadCount = 0

        } catch {
            print("❌ Failed to mark all as read: \(error)")
        }
    }
}
