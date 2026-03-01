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
    func clearAllHistory(dataManager: DataManager) {
        let userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
        
        // 1. Clear all chat threads and messages
        dataManager.deleteAllThreads(for: userEmail)
        
        // 2. Clear all compatibility history
        CompatibilityHistoryService.shared.clearAll()
        
        print("[HistorySettingsManager] Cleared all history for \(userEmail)")
    }
}
