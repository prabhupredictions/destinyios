import Foundation

/// Coordinates login sync to avoid duplicate thread list API calls.
/// Both ChatHistorySyncService and CompatibilityHistoryService need the same thread list
/// from `/chat-history/threads/{email}`. This coordinator fetches it once and dispatches.
@MainActor
final class LoginSyncCoordinator {
    static let shared = LoginSyncCoordinator()
    private init() {}
    
    /// Sync all history (chat + compatibility) from a single thread list fetch.
    /// Runs chat sync and compat sync concurrently after the shared fetch.
    func syncAll(userEmail: String, dataManager: DataManager) async {
        print("[LoginSyncCoordinator] Starting coordinated sync for \(userEmail)")
        
        // Fetch history settings from server first (ensures iOS toggle matches backend)
        await HistorySettingsManager.shared.fetchSettingsFromServer()
        
        do {
            // 1. Single thread list fetch (saves one duplicate API call)
            let allThreads = try await ChatHistorySyncService.shared.fetchThreads(userEmail: userEmail, profileId: nil)
            print("[LoginSyncCoordinator] Fetched \(allThreads.count) threads total")
            
            // 2. Separate compat threads from the rest
            let compatThreadIds = Set(allThreads.filter {
                ($0.primaryArea == "compatibility") || ($0.id.hasPrefix("compat_"))
            }.map { $0.id })
            
            print("[LoginSyncCoordinator] Chat: \(allThreads.count - compatThreadIds.count), Compat: \(compatThreadIds.count)")
            
            // 3. Run both syncs concurrently with the shared thread data
            //    ChatHistorySyncService gets ALL threads (it saves everything locally, including compat threads for history view)
            //    CompatibilityHistoryService gets only compat thread IDs (it fetches details independently)
            async let chatSync: () = ChatHistorySyncService.shared.syncFromServer(
                userEmail: userEmail,
                threads: allThreads,
                dataManager: dataManager
            )
            async let compatSync: () = CompatibilityHistoryService.shared.syncCompatThreads(
                userEmail: userEmail,
                compatThreadIds: Array(compatThreadIds)
            )
            _ = await (chatSync, compatSync)
            
            print("[LoginSyncCoordinator] Coordinated sync complete")
            
        } catch {
            print("[LoginSyncCoordinator] Thread list fetch failed: \(error)")
            // Fallback: run independent syncs (each fetches its own thread list)
            async let chatFallback: () = ChatHistorySyncService.shared.syncFromServer(userEmail: userEmail, dataManager: dataManager)
            async let compatFallback: () = CompatibilityHistoryService.shared.syncFromServer(userEmail: userEmail)
            _ = await (chatFallback, compatFallback)
        }
    }
}
