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
    var isLoadingMore = false
    var hasMoreChats = false
    var errorMessage: String?
    
    // Pagination
    private let pageSize = 20
    private var chatOffset = 0
    private var loadedMatchItems: [UnifiedHistoryItem] = []
    
    // Pre-computed grouped items (avoids O(n) recomputation per render)
    var groupedItems: [Date: [UnifiedHistoryItem]] = [:]
    
    // Dependencies
    private let dataManager: DataManager
    // CompatibilityHistoryService is a singleton
    
    // MARK: - Init
    init(dataManager: DataManager? = nil) {
        self.dataManager = dataManager ?? DataManager.shared
    }
    
    // MARK: - Recompute Grouped Items
    private func recomputeGroupedItems() {
        let calendar = Calendar.current
        var groups: [Date: [UnifiedHistoryItem]] = [:]
        
        for item in items {
            let startOfDay = calendar.startOfDay(for: item.date)
            groups[startOfDay, default: []].append(item)
        }
        
        groupedItems = groups
    }
    
    // MARK: - Load History (First Page)
    func loadHistory() async {
        isLoading = true
        errorMessage = nil
        chatOffset = 0
        items = []
        loadedMatchItems = []
        
        let userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
        let activeProfileId = ProfileContextManager.shared.activeProfileId
        
        print("[HistoryViewModel] Loading history page 1 for profileId: \(activeProfileId)")
        
        // 1. Fetch first page of chat threads
        let chatPage = fetchChatItemsPage(userEmail: userEmail, profileId: activeProfileId, offset: 0)
        chatOffset = chatPage.items.count
        hasMoreChats = chatPage.hasMore
        
        // 2. Fetch ALL local match history (small set, currently max 50)
        let localGroups = CompatibilityHistoryService.shared.loadGroups(lightweight: true)
        let localMatchSessionIds = Set(localGroups.flatMap { $0.items.map { $0.sessionId } })
        
        // 3. Filter out chat items that duplicate local matches
        let filteredChatItems = deduplicateChatItems(chatPage.items, localMatchSessionIds: localMatchSessionIds)
        
        // 4. Convert groups to UnifiedHistoryItems
        loadedMatchItems = convertGroupsToItems(localGroups)
        
        print("[HistoryViewModel] Chat items: \(filteredChatItems.count), Local match items: \(loadedMatchItems.count), hasMore: \(hasMoreChats)")
        
        // 5. Merge and Sort (Newest first)
        self.items = (filteredChatItems + loadedMatchItems).sorted { $0.date > $1.date }
        recomputeGroupedItems()
        
        isLoading = false
    }
    
    // MARK: - Load More (Next Page)
    func loadMoreIfNeeded(currentItem: UnifiedHistoryItem) async {
        // Trigger when user scrolls to last 3 items
        guard hasMoreChats, !isLoadingMore else { return }
        let thresholdIndex = max(items.count - 3, 0)
        guard let itemIndex = items.firstIndex(where: { $0.id == currentItem.id }),
              itemIndex >= thresholdIndex else { return }
        
        isLoadingMore = true
        
        let userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
        let activeProfileId = ProfileContextManager.shared.activeProfileId
        let localMatchSessionIds = Set(loadedMatchItems.compactMap { item -> String? in
            switch item {
            case .match(let m): return m.sessionId
            case .matchGroup(let g): return g.id
            default: return nil
            }
        })
        
        print("[HistoryViewModel] Loading more chats from offset \(chatOffset)")
        
        let chatPage = fetchChatItemsPage(userEmail: userEmail, profileId: activeProfileId, offset: chatOffset)
        let filteredNewItems = deduplicateChatItems(chatPage.items, localMatchSessionIds: localMatchSessionIds)
        
        chatOffset += chatPage.items.count
        hasMoreChats = chatPage.hasMore
        
        // Append new items and re-sort
        self.items = (self.items + filteredNewItems).sorted { $0.date > $1.date }
        recomputeGroupedItems()
        
        isLoadingMore = false
        print("[HistoryViewModel] Loaded \(filteredNewItems.count) more items, total: \(items.count), hasMore: \(hasMoreChats)")
    }
    
    // MARK: - Private Helpers
    
    /// Fetch one page of chat thread items with filtering logic
    private func fetchChatItemsPage(userEmail: String, profileId: String?, offset: Int) -> (items: [UnifiedHistoryItem], hasMore: Bool) {
        let threads = dataManager.fetchThreadsPaginated(for: userEmail, profileId: profileId, limit: pageSize, offset: offset)
        let totalCount = dataManager.countThreads(for: userEmail, profileId: profileId)
        let hasMore = (offset + threads.count) < totalCount
        
        var chatItems: [UnifiedHistoryItem] = []
        
        for thread in threads where thread.messageCount > 0 {
            let id = thread.id.lowercased()
            let title = thread.title.lowercased()
            
            let isCompatSession = id.hasPrefix("compat_sess_")
            let isCompatFollowUp = id.hasPrefix("compat_") && !isCompatSession
            let isConvPrefix = id.hasPrefix("conv_")
            let isCompatArea = thread.primaryArea?.lowercased() == "compatibility"
            let hasCompatInAreas = thread.areasDiscussed.contains { $0.lowercased() == "compatibility" }
            let isMainMatch = title.hasPrefix("match:")
            
            let isExcludedCompatFollowUp = (isCompatFollowUp || isConvPrefix) ||
                                           (isCompatArea && !isMainMatch && !isCompatSession) ||
                                           (hasCompatInAreas && !isMainMatch && !isCompatSession)
            
            if !isExcludedCompatFollowUp {
                chatItems.append(.chat(thread))
            }
        }
        
        return (chatItems, hasMore)
    }
    
    /// Remove chat items that duplicate local match items
    private func deduplicateChatItems(_ chatItems: [UnifiedHistoryItem], localMatchSessionIds: Set<String>) -> [UnifiedHistoryItem] {
        return chatItems.filter { item in
            if case .chat(let thread) = item {
                if thread.id.lowercased().hasPrefix("compat_sess_") {
                    let hasLocalMatch = localMatchSessionIds.contains(thread.id) ||
                                        localMatchSessionIds.contains("compat_\(thread.id)") ||
                                        localMatchSessionIds.contains(thread.id.replacingOccurrences(of: "compat_", with: ""))
                    if hasLocalMatch { return false }
                }
                return true
            }
            return true
        }
    }
    
    /// Convert ComparisonGroups to UnifiedHistoryItems
    private func convertGroupsToItems(_ groups: [ComparisonGroup]) -> [UnifiedHistoryItem] {
        var matchItems: [UnifiedHistoryItem] = []
        for group in groups {
            if group.items.count > 1 {
                matchItems.append(.matchGroup(group))
            } else if let singleItem = group.items.first {
                matchItems.append(.match(singleItem))
            }
        }
        return matchItems
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
        
        // Remove deleted items locally and recompute groups
        let deletedIds = Set(indexSet.compactMap { index -> String? in
            guard index < itemsForDate.count else { return nil }
            return itemsForDate[index].id
        })
        items.removeAll { deletedIds.contains($0.id) }
        loadedMatchItems.removeAll { deletedIds.contains($0.id) }
        recomputeGroupedItems()
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
