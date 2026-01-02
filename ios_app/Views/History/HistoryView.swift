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
                Color(red: 0.95, green: 0.94, blue: 0.96)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
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
                        .foregroundColor(Color("NavyPrimary"))
                }
                #else
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color("NavyPrimary"))
                }
                #endif
            }
            .task {
                await viewModel.loadHistory()
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(Color("NavyPrimary").opacity(0.3))
            
            Text("No History Yet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color("NavyPrimary"))
            
            Text("Your chats and matches will appear here.")
                .font(.system(size: 14))
                .foregroundColor(Color("TextDark").opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - History List
    private var historyListView: some View {
        List {
            ForEach(viewModel.groupedItems.keys.sorted(by: >), id: \.self) { date in
                Section(header: sectionHeader(for: date)) {
                    ForEach(viewModel.groupedItems[date] ?? []) { item in
                        HistoryRowView(item: item) {
                            // Handle selection
                            handleSelection(item)
                        }
                        .listRowBackground(Color.white)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .onDelete { indexSet in
                        Task {
                            await viewModel.deleteItems(at: indexSet, for: date)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    private func sectionHeader(for date: Date) -> some View {
        Text(viewModel.formatSectionDate(date))
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color("TextDark").opacity(0.6))
            .textCase(nil)
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
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color("NavyPrimary"))
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color("TextDark").opacity(0.6))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Time / Extra Info
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatTime(item.date))
                        .font(.system(size: 12))
                        .foregroundColor(Color("TextDark").opacity(0.5))
                    
                    extraInfoView
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
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
        case .match(_): return "Compatibility Match"
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
        case .chat: return Color("GoldAccent")
        case .match: return Color(red: 0.91, green: 0.71, blue: 0.72) // Rose Gold
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
                    .font(.system(size: 10))
                    .foregroundColor(Color("GoldAccent"))
            }
        case .match(let match):
            // scorePercentage is non-optional
            let score = match.scorePercentage
            if score > 0 {
                Text("\(Int(score * 100))%")
                    .font(.system(size: 12, weight: .bold))
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
