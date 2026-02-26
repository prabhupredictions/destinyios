import SwiftUI

/// History screen showing past chat threads
struct HistoryView: View {
// MARK: - Callbacks
    var onChatSelected: ((String) -> Void)? = nil
    var onMatchSelected: ((CompatibilityHistoryItem) -> Void)? = nil
    var onMatchGroupSelected: ((ComparisonGroup) -> Void)? = nil
    
    // MARK: - State
    @State private var viewModel = HistoryViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackgroundView()
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(AppTheme.Colors.gold)
                } else if viewModel.items.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .navigationTitle("History")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.Colors.gold)
                }
                #else
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.Colors.gold)
                }
                #endif
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Delete", isPresented: $viewModel.showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { viewModel.itemToDelete = nil }
                Button("Delete", role: .destructive) { viewModel.confirmDelete() }
            } message: {
                Text("Are you sure you want to delete \"\(viewModel.deleteItemTitle)\"?")
            }
            .task {
                await viewModel.loadHistory()
            }
            .onChange(of: ProfileContextManager.shared.activeProfileId) { _, _ in
                Task {
                    await viewModel.loadHistory()
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(AppTheme.Fonts.display(size: 48))
                .foregroundColor(AppTheme.Colors.gold.opacity(0.3))
            
            Text("No History Yet")
                .font(AppTheme.Fonts.title(size: 22))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Your chats and matches will appear here.")
                .font(AppTheme.Fonts.body(size: 16))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - History List
    private var historyListView: some View {
        let displayItems = viewModel.filteredGroupedItems
        
        return VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .font(.system(size: 15))
                
                TextField("Search history...", text: $viewModel.searchText)
                    .font(AppTheme.Fonts.body(size: 15))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .autocorrectionDisabled()
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
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
            
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(displayItems.keys.sorted(by: >), id: \.self) { date in
                        Section(header: sectionHeader(for: date)) {
                            VStack(spacing: 12) {
                                ForEach(displayItems[date] ?? []) { item in
                                    HistoryRowView(
                                        item: item,
                                        onTap: { handleSelection(item) },
                                        onDelete: { viewModel.requestDelete(item) },
                                        onPin: { viewModel.togglePin(item) }
                                    )
                                    .onAppear {
                                        Task {
                                            await viewModel.loadMoreIfNeeded(currentItem: item)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Loading more indicator
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .tint(AppTheme.Colors.gold)
                            .padding(.vertical, 16)
                    }
                }
                .padding(16)
            }
        }
    }
    
    private func sectionHeader(for date: Date) -> some View {
        HStack {
            Text(viewModel.formatSectionDate(date))
                .font(AppTheme.Fonts.title(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .textCase(nil)
            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    // MARK: - Selection Handler
    private func handleSelection(_ item: UnifiedHistoryItem) {
        dismiss()
        
        // Small delay to allow sheet dismissal before navigation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch item {
            case .chat(let thread):
                onChatSelected?(thread.id)
            case .match(let matchItem):
                // Load full data on-demand (lightweight items have result stripped)
                let fullItem = CompatibilityHistoryService.shared.get(sessionId: matchItem.sessionId) ?? matchItem
                onMatchSelected?(fullItem)
            case .matchGroup(let group):
                // Load full data for each item in the group
                let fullItems = group.items.compactMap { lite in
                    CompatibilityHistoryService.shared.get(sessionId: lite.sessionId) ?? lite
                }
                let fullGroup = ComparisonGroup(
                    id: group.id,
                    timestamp: group.timestamp,
                    userName: group.userName,
                    items: fullItems
                )
                onMatchGroupSelected?(fullGroup)
            }
        }
    }
}

// MARK: - History Row View
struct HistoryRowView: View {
    let item: UnifiedHistoryItem
    let onTap: () -> Void
    let onDelete: () -> Void
    let onPin: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.play(.light)
            onTap()
        }) {
            HStack(spacing: 16) {
                // Pin indicator
                if isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Colors.gold)
                        .frame(width: 12)
                } else {
                    Color.clear.frame(width: 12)
                }
                
                // Icon
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: iconName)
                        .font(AppTheme.Fonts.title(size: 20))
                        .foregroundColor(iconColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTheme.Fonts.title(size: 16))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(AppTheme.Fonts.caption(size: 13))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Time / Extra Info
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatTime(item.date))
                        .font(AppTheme.Fonts.caption(size: 12))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    extraInfoView
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isPinned ? AppTheme.Colors.gold.opacity(0.3) : AppTheme.Colors.separator, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
        .contextMenu {
            Button(action: onPin) {
                Label(
                    isPinned ? "Unpin" : "Pin",
                    systemImage: isPinned ? "pin.slash" : "pin"
                )
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var isPinned: Bool {
        switch item {
        case .chat(let thread): return thread.isPinned
        case .match(let m): return m.isPinned
        case .matchGroup(let g): return g.isPinned || g.items.first?.isPinned == true
        }
    }
    
    // MARK: - Helpers determining content
    
    private var title: String {
        switch item {
        case .chat(let thread): return thread.title
        case .match(let match): return match.displayTitle
        case .matchGroup(let group):
            let partnerNames = group.items.map { $0.girlName }
            return "\(group.userName) + \(partnerNames.joined(separator: ", "))"
        }
    }
    
    private var subtitle: String {
        switch item {
        case .chat(let thread): return thread.preview
        case .match(_): return "compatibility_match_subtitle".localized
        case .matchGroup(let group):
            return "Multi-match · \(group.items.count) partners compared"
        }
    }
    
    private var iconName: String {
        switch item {
        case .chat(let thread):
            return iconForArea(thread.primaryArea ?? "general")
        case .match:
            return "heart.fill"
        case .matchGroup:
            return "person.3.fill"
        }
    }
    
    private var iconColor: Color {
        switch item {
        case .chat: return AppTheme.Colors.gold
        case .match: return Color(red: 0.96, green: 0.52, blue: 0.65) // Rose Gold equivalent
        case .matchGroup: return Color(red: 0.75, green: 0.55, blue: 0.95) // Purple for groups
        }
    }
    
    private var iconBackgroundColor: Color {
        iconColor.opacity(0.15)
    }
    
    @ViewBuilder
    private var extraInfoView: some View {
        switch item {
        case .chat(let thread):
            VStack(alignment: .trailing, spacing: 2) {
                // Message count
                if thread.messageCount > 0 {
                    Text("\(thread.messageCount)")
                        .font(AppTheme.Fonts.title(size: 14))
                        .foregroundColor(AppTheme.Colors.gold)
                }
                
                Text("Messages")
                    .font(AppTheme.Fonts.caption(size: 10))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        case .match(let match):
            // Display score clearly with context
            VStack(alignment: .trailing, spacing: 2) {
                // Raw score (e.g., "15/36")
                Text("\(match.totalScore)/\(match.maxScore)")
                    .font(AppTheme.Fonts.title(size: 14))
                    .foregroundColor(matchScoreColor(match.scorePercentage / 100))
                
                // User question count if any chats exist
                let userQuestionCount = match.chatMessages.filter { $0.isUser }.count
                if userQuestionCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "bubble.left.fill")
                            .font(AppTheme.Fonts.caption(size: 9))
                        Text("\(userQuestionCount)")
                            .font(AppTheme.Fonts.caption(size: 10))
                    }
                    .foregroundColor(AppTheme.Colors.gold)
                } else {
                    Text("Match")
                        .font(AppTheme.Fonts.caption(size: 10))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
        case .matchGroup(let group):
            // Display best score and partner count for groups
            VStack(alignment: .trailing, spacing: 2) {
                // Best score in the group
                let bestItem = group.items.max(by: { $0.totalScore < $1.totalScore })
                if let best = bestItem {
                    Text("Best: \(best.totalScore)/\(best.maxScore)")
                        .font(AppTheme.Fonts.title(size: 13))
                        .foregroundColor(matchScoreColor(best.scorePercentage / 100))
                }
                
                // Partner count badge
                HStack(spacing: 3) {
                    Image(systemName: "person.2.fill")
                        .font(AppTheme.Fonts.caption(size: 9))
                    Text("\(group.items.count)")
                        .font(AppTheme.Fonts.caption(size: 10))
                }
                .foregroundColor(Color(red: 0.75, green: 0.55, blue: 0.95))
            }
        }
    }
    
    private func iconForArea(_ area: String) -> String {
        switch area.lowercased() {
        case "marriage": return "heart.fill"
        case "career": return "briefcase.fill"
        case "health": return "heart.text.square.fill"
        case "finance": return "dollarsign.circle.fill"
        case "compatibility": return "person.2.fill"
        default: return "sparkles"
        }
    }
    
    private func matchScoreColor(_ score: Double) -> Color {
        if score >= 0.7 { return .green }
        if score >= 0.5 { return .yellow }
        return .orange
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview
#Preview {
    HistoryView()
}
