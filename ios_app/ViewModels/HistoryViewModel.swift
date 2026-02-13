import Foundation
import SwiftUI

/// Unified history item wrapper
enum UnifiedHistoryItem: Identifiable {
    case chat(LocalChatThread)
    case match(CompatibilityHistoryItem)
    case matchGroup(ComparisonGroup)
    
    var id: String {
        switch self {
        case .chat(let thread): return "chat_\(thread.id)"
        case .match(let item): return "match_\(item.sessionId)"
        case .matchGroup(let group): return "group_\(group.id)"
        }
    }
    
    var date: Date {
        switch self {
        case .chat(let thread): return thread.updatedAt
        case .match(let item): return item.timestamp
        case .matchGroup(let group): return group.timestamp
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
    init(dataManager: DataManager? = nil) {
        self.dataManager = dataManager ?? DataManager.shared
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
        let activeProfileId = ProfileContextManager.shared.activeProfileId
        
        print("[HistoryViewModel] Loading history for profileId: \(activeProfileId)")
        
        // Fetch threads filtered by profile (Switch Profile feature)
        let allThreads = dataManager.fetchAllThreads(for: userEmail, profileId: activeProfileId)
        
        // Separate regular chat threads from compatibility threads
        var chatItems: [UnifiedHistoryItem] = []
        var compatThreadIds: Set<String> = []
        
        for thread in allThreads where thread.messageCount > 0 {
            let id = thread.id.lowercased()
            let title = thread.title.lowercased()
            
            // DEBUG: Log all threads
            print("[HistoryViewModel] Thread: '\(thread.title)' | id: \(thread.id.prefix(30)) | area: \(thread.primaryArea ?? "nil")")
            
            // Detect compatibility-related threads
            let isCompatSession = id.hasPrefix("compat_sess_")  // Main match result
            let isCompatFollowUp = id.hasPrefix("compat_") && !isCompatSession  // e.g., compat_followup_, compat_conv_
            let isConvPrefix = id.hasPrefix("conv_")  // Follow-up conversation
            let isCompatArea = thread.primaryArea?.lowercased() == "compatibility"
            let hasCompatInAreas = thread.areasDiscussed.contains { $0.lowercased() == "compatibility" }
            let isMainMatch = title.hasPrefix("match:")
            
            // Track all compatibility-related thread IDs to avoid duplicates with local matches
            if isCompatSession || isCompatFollowUp || isConvPrefix {
                compatThreadIds.insert(thread.id)
            }
            
            // Decision logic:
            // INCLUDE: Main match results (compat_sess_* with "Match:" title), regular general chats
            // EXCLUDE: Compatibility follow-ups (compat_* but not compat_sess_, conv_*, compatArea without Match:)
            let isExcludedCompatFollowUp = (isCompatFollowUp || isConvPrefix) ||  // ID-based follow-up
                                           (isCompatArea && !isMainMatch && !isCompatSession) ||  // Area-based follow-up
                                           (hasCompatInAreas && !isMainMatch && !isCompatSession)  // AreasDiscussed-based
            
            print("[HistoryViewModel]   isCompatSession:\(isCompatSession) isMainMatch:\(isMainMatch) isExcluded:\(isExcludedCompatFollowUp)")
            
            if !isExcludedCompatFollowUp {
                chatItems.append(.chat(thread))
            } else {
                print("[HistoryViewModel] Excluding compat follow-up: '\(thread.title)'")
            }
        }
        
        // 2. Fetch Local Match History GROUPED (multi-partner support)
        let localGroups = CompatibilityHistoryService.shared.loadGroups()
        let localMatchSessionIds = Set(localGroups.flatMap { $0.items.map { $0.sessionId } })
        
        // 3. For compat_sess_ threads, PREFER local match items (they have full results + proper navigation)
        // Remove server chat items that have a matching local match item
        let filteredChatItems = chatItems.filter { item in
            if case .chat(let thread) = item {
                // If this is a compat session AND we have a local match with the same sessionId,
                // use the local match instead (it has full CompatibilityResult data)
                if thread.id.lowercased().hasPrefix("compat_sess_") {
                    let hasLocalMatch = localMatchSessionIds.contains(thread.id) || 
                                        localMatchSessionIds.contains("compat_\(thread.id)") ||
                                        localMatchSessionIds.contains(thread.id.replacingOccurrences(of: "compat_", with: ""))
                    if hasLocalMatch {
                        print("[HistoryViewModel] Preferring local match over server thread: \(thread.id)")
                        return false  // Use local match instead
                    }
                }
                return true
            }
            return true
        }
        
        // 4. Convert groups to UnifiedHistoryItems
        // Single-item groups → .match (unchanged behavior)
        // Multi-item groups → .matchGroup (new grouped entry)
        var matchItems: [UnifiedHistoryItem] = []
        for group in localGroups {
            if group.items.count > 1 {
                matchItems.append(.matchGroup(group))
            } else if let singleItem = group.items.first {
                matchItems.append(.match(singleItem))
            }
        }
        
        print("[HistoryViewModel] Chat items: \(filteredChatItems.count), Local match items: \(matchItems.count)")
        
        // 5. Merge and Sort (Newest first)
        let allItems = filteredChatItems + matchItems
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
            case .matchGroup(let group):
                CompatibilityHistoryService.shared.deleteGroup(groupId: group.id)
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
