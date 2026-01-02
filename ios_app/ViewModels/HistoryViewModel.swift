import Foundation
import SwiftUI

/// Unified history item wrapper
enum UnifiedHistoryItem: Identifiable {
    case chat(LocalChatThread)
    case match(CompatibilityHistoryItem)
    
    var id: String {
        switch self {
        case .chat(let thread): return "chat_\(thread.id)"
        case .match(let item): return "match_\(item.sessionId)"
        }
    }
    
    var date: Date {
        switch self {
        case .chat(let thread): return thread.updatedAt
        case .match(let item): return item.timestamp
        }
    }
}

/// ViewModel for History screen
@Observable
@MainActor
class HistoryViewModel {
    // MARK: - State
    var items: [UnifiedHistoryItem] = []
    var isLoading = false
    var errorMessage: String?
    
    // Dependencies
    private let dataManager: DataManager
    // CompatibilityHistoryService is a singleton
    
    // MARK: - Init
    init(dataManager: DataManager = .shared) {
        self.dataManager = dataManager
    }
    
    // MARK: - Grouped Items by Date
    var groupedItems: [Date: [UnifiedHistoryItem]] {
        let calendar = Calendar.current
        var groups: [Date: [UnifiedHistoryItem]] = [:]
        
        for item in items {
            let startOfDay = calendar.startOfDay(for: item.date)
            if groups[startOfDay] == nil {
                groups[startOfDay] = []
            }
            groups[startOfDay]?.append(item)
        }
        
        return groups
    }
    
    // MARK: - Load History
    func loadHistory() async {
        isLoading = true
        errorMessage = nil
        
        // 1. Fetch Chat Threads
        let userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
        let threads = dataManager.fetchAllThreads(for: userEmail)
        let chatItems = threads.map { UnifiedHistoryItem.chat($0) }
        
        // 2. Fetch Match History
        let matches = CompatibilityHistoryService.shared.loadAll()
        let matchItems = matches.map { UnifiedHistoryItem.match($0) }
        
        // 3. Merge and Sort (Newest first)
        let allItems = chatItems + matchItems
        self.items = allItems.sorted { $0.date > $1.date }
        
        isLoading = false
    }
    
    // MARK: - Delete Logic
    func deleteItems(at indexSet: IndexSet, for date: Date) async {
        guard let itemsForDate = groupedItems[date] else { return }
        
        for index in indexSet {
            let item = itemsForDate[index]
            switch item {
            case .chat(let thread):
                dataManager.deleteThread(thread)
            case .match(let matchItem):
                CompatibilityHistoryService.shared.delete(sessionId: matchItem.sessionId)
            }
        }
        
        // Reload to refresh UI and master list
        await loadHistory()
    }
    
    // MARK: - Format Section Date
    func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return "This Week"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}
