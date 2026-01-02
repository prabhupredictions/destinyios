import SwiftUI

// MARK: - Compatibility History Sheet
/// Shows list of past compatibility matches with delete functionality
struct CompatibilityHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var historyItems: [CompatibilityHistoryItem] = []
    @State private var selectedItems: Set<String> = []
    @State private var isEditMode = false
    @State private var itemToDelete: CompatibilityHistoryItem?
    @State private var showDeleteConfirmation = false
    @State private var showClearAllConfirmation = false
    
    var onSelect: ((CompatibilityHistoryItem) -> Void)?
    
    // Colors
    private let accentGold = Color(red: 0.9, green: 0.7, blue: 0.3)
    private let navyPrimary = Color(red: 0.1, green: 0.1, blue: 0.2)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(red: 0.96, green: 0.95, blue: 0.97)
                    .ignoresSafeArea()
                
                if historyItems.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle("match_history".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !historyItems.isEmpty {
                        Button(isEditMode ? "done".localized : "edit".localized) {
                            withAnimation {
                                isEditMode.toggle()
                                if !isEditMode {
                                    selectedItems.removeAll()
                                }
                            }
                        }
                    }
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
            .alert("clear_all_history".localized, isPresented: $showClearAllConfirmation) {
                Button("cancel".localized, role: .cancel) {}
                Button("clear_all".localized, role: .destructive) {
                    clearAll()
                }
            } message: {
                Text("clear_all_history_confirmation".localized)
            }
        }
        .onAppear {
            loadHistory()
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("no_match_history".localized)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.gray)
            
            Text("no_match_history_desc".localized)
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - History List
    private var historyList: some View {
        VStack(spacing: 0) {
            List {
                ForEach(historyItems) { item in
                    HistoryItemRow(
                        item: item,
                        isEditMode: isEditMode,
                        isSelected: selectedItems.contains(item.sessionId),
                        onTap: {
                            if isEditMode {
                                toggleSelection(item)
                            } else {
                                onSelect?(item)
                                dismiss()
                            }
                        }
                    )
                    .listRowBackground(Color.white)
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
            
            // Bottom bar for edit mode
            if isEditMode && !selectedItems.isEmpty {
                deleteSelectedBar
            }
        }
    }
    
    // MARK: - Delete Selected Bar
    private var deleteSelectedBar: some View {
        HStack {
            Text("\(selectedItems.count) " + "selected".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            Spacer()
            
            Button(action: {
                deleteSelected()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("delete".localized)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.red)
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white)
        .shadow(color: .black.opacity(0.05), radius: 5, y: -2)
    }
    
    // MARK: - Actions
    private func loadHistory() {
        historyItems = CompatibilityHistoryService.shared.loadAll()
    }
    
    private func toggleSelection(_ item: CompatibilityHistoryItem) {
        if selectedItems.contains(item.sessionId) {
            selectedItems.remove(item.sessionId)
        } else {
            selectedItems.insert(item.sessionId)
        }
    }
    
    private func deleteItem(_ item: CompatibilityHistoryItem) {
        withAnimation {
            CompatibilityHistoryService.shared.delete(sessionId: item.sessionId)
            historyItems.removeAll { $0.sessionId == item.sessionId }
        }
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func deleteSelected() {
        withAnimation {
            CompatibilityHistoryService.shared.delete(sessionIds: selectedItems)
            historyItems.removeAll { selectedItems.contains($0.sessionId) }
            selectedItems.removeAll()
            isEditMode = false
        }
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func clearAll() {
        withAnimation {
            CompatibilityHistoryService.shared.clearAll()
            historyItems.removeAll()
            isEditMode = false
        }
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - History Item Row
struct HistoryItemRow: View {
    let item: CompatibilityHistoryItem
    let isEditMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    
    private let accentGold = Color(red: 0.9, green: 0.7, blue: 0.3)
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Selection circle in edit mode
                if isEditMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .blue : .gray.opacity(0.4))
                }
                
                // Score badge
                ZStack {
                    Circle()
                        .fill(scoreColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    VStack(spacing: 0) {
                        Text("\(item.totalScore)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(scoreColor)
                        Text("/\(item.maxScore)")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.2))
                    
                    HStack(spacing: 8) {
                        Text(item.displayDate)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        if item.chatMessages.count > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "bubble.left.fill")
                                    .font(.system(size: 10))
                                Text("\(item.chatMessages.count)")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(accentGold)
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                if !isEditMode {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray.opacity(0.4))
                }
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
