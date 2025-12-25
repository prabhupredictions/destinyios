import Foundation
import SwiftUI

/// ViewModel for History screen
@Observable
@MainActor
class HistoryViewModel {
    // MARK: - State
    var threads: [LocalChatThread] = []
    var isLoading = false
    var errorMessage: String?
    
    private let dataManager: DataManager
    
    // MARK: - Init
    init(dataManager: DataManager = .shared) {
        self.dataManager = dataManager
    }
    
    // MARK: - Grouped Threads by Date
    var groupedThreads: [Date: [LocalChatThread]] {
        let calendar = Calendar.current
        var groups: [Date: [LocalChatThread]] = [:]
        
        for thread in threads {
            let startOfDay = calendar.startOfDay(for: thread.updatedAt)
            if groups[startOfDay] == nil {
                groups[startOfDay] = []
            }
            groups[startOfDay]?.append(thread)
        }
        
        return groups
    }
    
    // MARK: - Load Threads
    func loadThreads() async {
        isLoading = true
        errorMessage = nil
        
        // Get user email from UserDefaults
        let userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
        
        // Fetch from DataManager
        threads = dataManager.fetchAllThreads(for: userEmail)
        
        isLoading = false
    }
    
    // MARK: - Delete Threads
    func deleteThreads(at indexSet: IndexSet, for date: Date) async {
        guard let threadsForDate = groupedThreads[date] else { return }
        
        for index in indexSet {
            let thread = threadsForDate[index]
            dataManager.deleteThread(thread)
        }
        
        // Reload
        await loadThreads()
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
