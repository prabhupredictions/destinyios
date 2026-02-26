import SwiftUI

// MARK: - Compatibility History Sheet
/// Shows list of past compatibility matches with swipe-to-delete
/// Supports both single matches and multi-partner groups
struct CompatibilityHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var groups: [ComparisonGroup] = []
    @State private var groupToDelete: ComparisonGroup?
    @State private var showDeleteConfirmation = false
    @State private var searchText = ""
    
    var onSelect: ((CompatibilityHistoryItem) -> Void)?
    var onGroupSelect: ((ComparisonGroup) -> Void)?
    
    /// Filtered groups based on search text
    private var filteredGroups: [ComparisonGroup] {
        guard !searchText.isEmpty else { return groups }
        let query = searchText.lowercased()
        return groups.filter { group in
            group.userName.lowercased().contains(query) ||
            group.items.contains { $0.girlName.lowercased().contains(query) || $0.boyName.lowercased().contains(query) }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background - Dark Cosmic Theme
                CosmicBackgroundView()
                    .ignoresSafeArea()
                
                if groups.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        // Search bar
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .font(.system(size: 15))
                            
                            TextField("Search matches...", text: $searchText)
                                .font(AppTheme.Fonts.body(size: 15))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .autocorrectionDisabled()
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                        .font(.system(size: 15))
                                }
                            }
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                        
                        if filteredGroups.isEmpty {
                            Spacer()
                            Text("No results found")
                                .font(AppTheme.Fonts.body(size: 16))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Spacer()
                        } else {
                            historyList
                        }
                    }
                }
            }
            .navigationTitle("Match History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.Colors.gold)
                }
            }
            .alert("delete_match".localized, isPresented: $showDeleteConfirmation) {
                Button("cancel".localized, role: .cancel) {}
                Button("delete".localized, role: .destructive) {
                    if let group = groupToDelete {
                        deleteGroup(group)
                    }
                }
            } message: {
                if let group = groupToDelete {
                    Text("delete_match_confirmation".localized + " \(group.displayTitle)?")
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadHistory()
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(AppTheme.Fonts.display(size: 60))
                .foregroundColor(AppTheme.Colors.gold.opacity(0.3))
            
            Text("no_match_history".localized)
                .font(AppTheme.Fonts.title(size: 18))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("no_match_history_desc".localized)
                .font(AppTheme.Fonts.body(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - History List
    private var historyList: some View {
        List {
            ForEach(filteredGroups) { group in
                if group.items.count > 1 {
                    // Multi-partner group row
                    GroupHistoryRow(
                        group: group,
                        onTap: {
                            selectFullGroup(group)
                        }
                    )
                    .listRowBackground(AppTheme.Colors.cardBackground)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            groupToDelete = group
                            showDeleteConfirmation = true
                        } label: {
                            Label("delete".localized, systemImage: "trash")
                        }
                        
                        Button {
                            togglePinGroup(group)
                        } label: {
                            Label(
                                group.items.first?.isPinned == true ? "Unpin" : "Pin",
                                systemImage: group.items.first?.isPinned == true ? "pin.slash" : "pin"
                            )
                        }
                        .tint(AppTheme.Colors.gold)
                    }
                    .contextMenu {
                        Button {
                            togglePinGroup(group)
                        } label: {
                            Label(
                                group.items.first?.isPinned == true ? "Unpin" : "Pin",
                                systemImage: group.items.first?.isPinned == true ? "pin.slash" : "pin"
                            )
                        }
                        
                        Button(role: .destructive) {
                            groupToDelete = group
                            showDeleteConfirmation = true
                        } label: {
                            Label("delete".localized, systemImage: "trash")
                        }
                    }
                } else if let item = group.items.first {
                    // Single match row
                    HistoryItemRow(
                        item: item,
                        onTap: {
                            selectFullItem(item)
                        }
                    )
                    .listRowBackground(AppTheme.Colors.cardBackground)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            groupToDelete = group
                            showDeleteConfirmation = true
                        } label: {
                            Label("delete".localized, systemImage: "trash")
                        }
                        
                        Button {
                            togglePinItem(item)
                        } label: {
                            Label(
                                item.isPinned ? "Unpin" : "Pin",
                                systemImage: item.isPinned ? "pin.slash" : "pin"
                            )
                        }
                        .tint(AppTheme.Colors.gold)
                    }
                    .contextMenu {
                        Button {
                            togglePinItem(item)
                        } label: {
                            Label(
                                item.isPinned ? "Unpin" : "Pin",
                                systemImage: item.isPinned ? "pin.slash" : "pin"
                            )
                        }
                        
                        Button(role: .destructive) {
                            groupToDelete = group
                            showDeleteConfirmation = true
                        } label: {
                            Label("delete".localized, systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Actions
    private func loadHistory() {
        groups = CompatibilityHistoryService.shared.loadGroups(lightweight: true)
    }
    
    /// Load full data for a single item on-demand (result + chatMessages)
    private func selectFullItem(_ lightweightItem: CompatibilityHistoryItem) {
        if let fullItem = CompatibilityHistoryService.shared.get(sessionId: lightweightItem.sessionId) {
            onSelect?(fullItem)
        } else {
            onSelect?(lightweightItem)
        }
        dismiss()
    }
    
    /// Load full data for a group on-demand
    private func selectFullGroup(_ lightweightGroup: ComparisonGroup) {
        let fullItems = lightweightGroup.items.compactMap { lite in
            CompatibilityHistoryService.shared.get(sessionId: lite.sessionId) ?? lite
        }
        let fullGroup = ComparisonGroup(
            id: lightweightGroup.id,
            timestamp: lightweightGroup.timestamp,
            userName: lightweightGroup.userName,
            items: fullItems
        )
        onGroupSelect?(fullGroup)
        dismiss()
    }
    
    private func deleteGroup(_ group: ComparisonGroup) {
        withAnimation {
            CompatibilityHistoryService.shared.deleteGroup(groupId: group.id)
            groups.removeAll { $0.id == group.id }
        }
        HapticManager.shared.play(.heavy)
    }
    
    private func togglePinItem(_ item: CompatibilityHistoryItem) {
        CompatibilityHistoryService.shared.togglePin(sessionId: item.sessionId)
        loadHistory()
        HapticManager.shared.play(.light)
    }
    
    private func togglePinGroup(_ group: ComparisonGroup) {
        CompatibilityHistoryService.shared.togglePinGroup(groupId: group.id)
        loadHistory()
        HapticManager.shared.play(.light)
    }
}

// MARK: - Group History Row (multi-partner)
struct GroupHistoryRow: View {
    let group: ComparisonGroup
    let onTap: () -> Void
    
    private let accentPurple = Color(red: 0.75, green: 0.55, blue: 0.95)
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Pin indicator
                if group.items.first?.isPinned == true {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Colors.gold)
                        .frame(width: 12)
                }
                
                // Group icon badge
                ZStack {
                    Circle()
                        .fill(accentPurple.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    VStack(spacing: 0) {
                        Image(systemName: "person.3.fill")
                            .font(AppTheme.Fonts.title(size: 16))
                            .foregroundColor(accentPurple)
                        Text("\(group.items.count)")
                            .font(AppTheme.Fonts.caption(size: 10))
                            .foregroundColor(accentPurple)
                    }
                }
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    // Title: "UserName + Partner1, Partner2"
                    let partnerNames = group.items.map { $0.girlName }
                    Text("\(group.userName) + \(partnerNames.joined(separator: ", "))")
                        .font(AppTheme.Fonts.title(size: 15))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(group.displayDate)
                            .font(AppTheme.Fonts.caption(size: 12))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        // Best score indicator
                        if let best = group.bestMatch {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(AppTheme.Fonts.caption(size: 10))
                                Text("Best: \(best.totalScore)/\(best.maxScore)")
                                    .font(AppTheme.Fonts.caption(size: 11))
                            }
                            .foregroundColor(accentPurple)
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(AppTheme.Fonts.title(size: 14))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - History Item Row
struct HistoryItemRow: View {
    let item: CompatibilityHistoryItem
    let onTap: () -> Void
    
    private let accentGold = Color(red: 0.9, green: 0.7, blue: 0.3)
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Pin indicator
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Colors.gold)
                        .frame(width: 12)
                }
                
                // Score badge
                ZStack {
                    Circle()
                        .fill(scoreColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    VStack(spacing: 0) {
                        Text("\(item.totalScore)")
                            .font(AppTheme.Fonts.title(size: 18))
                            .foregroundColor(scoreColor)
                        Text("/\(item.maxScore)")
                            .font(AppTheme.Fonts.caption(size: 10))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayTitle)
                        .font(AppTheme.Fonts.title(size: 15))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    HStack(spacing: 8) {
                        Text(item.displayDate)
                            .font(AppTheme.Fonts.caption(size: 12))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        // User question count
                        let userQuestionCount = item.chatMessages.filter { $0.isUser }.count
                        if userQuestionCount > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "bubble.left.fill")
                                    .font(AppTheme.Fonts.caption(size: 10))
                                Text("\(userQuestionCount)")
                                    .font(AppTheme.Fonts.caption(size: 11))
                            }
                            .foregroundColor(accentGold)
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(AppTheme.Fonts.title(size: 14))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var scoreColor: Color {
        let percentage = item.scorePercentage
        if percentage >= 70 { return .green }
        if percentage >= 50 { return .orange }
        return .red
    }
}

// MARK: - Preview
#Preview {
    CompatibilityHistorySheet()
}
