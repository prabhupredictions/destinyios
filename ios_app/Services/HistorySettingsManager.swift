import Foundation

// MARK: - Notification Names
extension Notification.Name {
    static let openProfileSettings = Notification.Name("openProfileSettings")
}

/// Manages the "Save conversation history" toggle and "Clear history" action.
/// Syncs the toggle to the backend so the predict API also respects it.
@Observable
final class HistorySettingsManager {
    
    // MARK: - Singleton
    static let shared = HistorySettingsManager()
    
    // MARK: - Keys
    private static let isHistoryEnabledKey = "isHistoryEnabled"
    
    // MARK: - State
    
    /// Whether history saving is enabled (default: true)
    var isHistoryEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isHistoryEnabled, forKey: Self.isHistoryEnabledKey)
            // Sync to backend so predict API also respects the setting
            syncSettingToServer(enabled: isHistoryEnabled)
        }
    }
    
    private init() {
        // Default to true if key has never been set
        if UserDefaults.standard.object(forKey: Self.isHistoryEnabledKey) == nil {
            self.isHistoryEnabled = true
        } else {
            self.isHistoryEnabled = UserDefaults.standard.bool(forKey: Self.isHistoryEnabledKey)
        }
    }
    
    // MARK: - Fetch Settings from Server (on login)
    
    /// Fetches history setting from server and updates local state.
    /// Call this after login to ensure iOS and backend are in sync.
    func fetchSettingsFromServer() async {
        let userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
        guard !userEmail.isEmpty, !userEmail.contains("guest") else { return }
        
        let urlString = "\(APIConfig.baseURL)/chat-history/settings/\(userEmail)"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let historyEnabled = json["history_enabled"] as? Bool {
                    await MainActor.run {
                        // Update local state without triggering didSet server sync
                        UserDefaults.standard.set(historyEnabled, forKey: Self.isHistoryEnabledKey)
                        self.isHistoryEnabled = historyEnabled
                    }
                    print("[HistorySettingsManager] Fetched server setting: history_enabled=\(historyEnabled)")
                }
            }
        } catch {
            print("[HistorySettingsManager] Failed to fetch settings from server: \(error)")
        }
    }
    
    // MARK: - Sync Toggle to Server
    
    /// Syncs the history_enabled setting to the backend.
    /// The predict API checks this before saving chat history.
    private func syncSettingToServer(enabled: Bool) {
        let userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
        guard !userEmail.isEmpty, !userEmail.contains("guest") else { return }
        
        let urlString = "\(APIConfig.baseURL)/chat-history/settings/\(userEmail)?history_enabled=\(enabled)&save_conversations=\(enabled)"
        guard let url = URL(string: urlString) else {
            print("[HistorySettingsManager] Invalid URL for settings sync")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        Task {
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("[HistorySettingsManager] Synced history_enabled=\(enabled) to server")
                    } else {
                        print("[HistorySettingsManager] Server settings sync failed: HTTP \(httpResponse.statusCode)")
                    }
                }
            } catch {
                print("[HistorySettingsManager] Failed to sync settings to server: \(error)")
            }
        }
    }
    
    // MARK: - Clear All History
    
    /// Clears all chat threads + messages (SwiftData) and all compatibility history (UserDefaults)
    /// for the current user. This is irreversible.
    /// Also deletes all history from the backend server.
    func clearAllHistory(dataManager: DataManager) async {
        let userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
        
        // 1. Delete from server first (includes both chat and compatibility threads)
        await deleteAllHistoryFromServer(userEmail: userEmail)
        
        // 2. Clear local chat threads and messages
        dataManager.deleteAllThreads(for: userEmail)
        
        // 3. Clear local compatibility history
        CompatibilityHistoryService.shared.clearAll()
        
        print("[HistorySettingsManager] Cleared all history (local + server) for \(userEmail)")
    }
    
    /// Deletes all chat history from the server (GDPR endpoint)
    private func deleteAllHistoryFromServer(userEmail: String) async {
        guard !userEmail.isEmpty else { return }
        
        let urlString = "\(APIConfig.baseURL)/chat-history/all/\(userEmail)"
        guard let url = URL(string: urlString) else {
            print("[HistorySettingsManager] Invalid URL for delete all")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let deletedCount = json["deleted_count"] as? Int {
                        print("[HistorySettingsManager] Deleted \(deletedCount) threads from server")
                    }
                } else {
                    print("[HistorySettingsManager] Server delete failed with status \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("[HistorySettingsManager] Failed to delete history from server: \(error)")
        }
    }
}
