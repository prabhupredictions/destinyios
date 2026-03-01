import Foundation

// MARK: - Notification Names
extension Notification.Name {
    static let openProfileSettings = Notification.Name("openProfileSettings")
}

/// Manages the "Save conversation history" toggle and "Clear history" action.
/// Uses UserDefaults with a global key (not profile-scoped, since the setting
/// applies to the entire account — the user either wants history or doesn't).
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
        request.setValue(APIConfig.apiKey, forHTTPHeaderField: "X-API-Key")
        
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
