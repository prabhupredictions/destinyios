import SwiftUI

// MARK: - Compatibility History Sheet
/// Shows list of past compatibility matches with swipe-to-delete
struct CompatibilityHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var historyItems: [CompatibilityHistoryItem] = []
    @State private var itemToDelete: CompatibilityHistoryItem?
    @State private var showDeleteConfirmation = false
    
    var onSelect: ((CompatibilityHistoryItem) -> Void)?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background - Dark Cosmic Theme
                CosmicBackgroundView()
                    .ignoresSafeArea()
                
                if historyItems.isEmpty {
                    emptyState
                } else {
                    historyList
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
                    if let item = itemToDelete {
                        deleteItem(item)
                    }
                }
            } message: {
                if let item = itemToDelete {
                    Text("delete_match_confirmation".localized + " \(item.displayTitle)?")
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
            ForEach(historyItems) { item in
                HistoryItemRow(
                    item: item,
                    onTap: {
                        onSelect?(item)
                        dismiss()
                    }
                )
                .listRowBackground(AppTheme.Colors.cardBackground)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        itemToDelete = item
                        showDeleteConfirmation = true
                    } label: {
                        Label("delete".localized, systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Actions
    private func loadHistory() {
        historyItems = CompatibilityHistoryService.shared.loadAll()
    }
    
    private func deleteItem(_ item: CompatibilityHistoryItem) {
        withAnimation {
            CompatibilityHistoryService.shared.delete(sessionId: item.sessionId)
            historyItems.removeAll { $0.sessionId == item.sessionId }
        }
        HapticManager.shared.play(.heavy)
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
