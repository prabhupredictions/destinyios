import SwiftUI

/// History screen showing past chat threads
struct HistoryView: View {
// MARK: - Callbacks
    var onChatSelected: ((String) -> Void)? = nil
    var onMatchSelected: ((CompatibilityHistoryItem) -> Void)? = nil
    
    // MARK: - State
    @State private var viewModel = HistoryViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.mainBackground
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
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                await viewModel.loadHistory()
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
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(viewModel.groupedItems.keys.sorted(by: >), id: \.self) { date in
                    Section(header: sectionHeader(for: date)) {
                        VStack(spacing: 12) {
                            ForEach(viewModel.groupedItems[date] ?? []) { item in
                                HistoryRowView(item: item) {
                                    handleSelection(item)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
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
                onMatchSelected?(matchItem)
            }
        }
    }
}

// MARK: - History Row View
struct HistoryRowView: View {
    let item: UnifiedHistoryItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.play(.light)
            onTap()
        }) {
            HStack(spacing: 16) {
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
            .padding(16)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.Colors.separator, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Helpers determining content
    
    private var title: String {
        switch item {
        case .chat(let thread): return thread.title
        case .match(let match): return match.displayTitle
        }
    }
    
    private var subtitle: String {
        switch item {
        case .chat(let thread): return thread.preview
        case .match(_): return "compatibility_match_subtitle".localized
        }
    }
    
    private var iconName: String {
        switch item {
        case .chat(let thread):
            return iconForArea(thread.primaryArea ?? "general")
        case .match:
            return "heart.fill"
        }
    }
    
    private var iconColor: Color {
        switch item {
        case .chat: return AppTheme.Colors.gold
        case .match: return Color(red: 0.96, green: 0.52, blue: 0.65) // Rose Gold equivalent
        }
    }
    
    private var iconBackgroundColor: Color {
        iconColor.opacity(0.15)
    }
    
    @ViewBuilder
    private var extraInfoView: some View {
        switch item {
        case .chat(let thread):
            if thread.isPinned {
                Image(systemName: "pin.fill")
                    .font(AppTheme.Fonts.caption(size: 10))
                    .foregroundColor(AppTheme.Colors.gold)
            }
        case .match(let match):
            // scorePercentage is non-optional
            let score = match.scorePercentage
            if score > 0 {
                Text("\(Int(score * 100))%")
                    .font(AppTheme.Fonts.title(size: 12))
                    .foregroundColor(matchScoreColor(score))
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
