import SwiftUI

/// History screen showing past chat threads
struct HistoryView: View {
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
                } else if viewModel.threads.isEmpty {
                    emptyStateView
                } else {
                    threadListView
                }
            }
            .navigationTitle("Chat History")
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
                await viewModel.loadThreads()
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(Color("NavyPrimary").opacity(0.3))
            
            Text("No conversations yet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color("NavyPrimary"))
            
            Text("Start asking questions and your\nhistory will appear here.")
                .font(.system(size: 14))
                .foregroundColor(Color("TextDark").opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Thread List
    private var threadListView: some View {
        List {
            ForEach(viewModel.groupedThreads.keys.sorted(by: >), id: \.self) { date in
                Section(header: sectionHeader(for: date)) {
                    ForEach(viewModel.groupedThreads[date] ?? []) { thread in
                        ThreadRowView(thread: thread)
                            .listRowBackground(Color.white)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .onDelete { indexSet in
                        Task {
                            await viewModel.deleteThreads(at: indexSet, for: date)
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
}

// MARK: - Thread Row View
struct ThreadRowView: View {
    let thread: LocalChatThread
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color("GoldAccent").opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconForArea(thread.primaryArea ?? "general"))
                    .font(.system(size: 16))
                    .foregroundColor(Color("GoldAccent"))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(thread.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color("NavyPrimary"))
                    .lineLimit(1)
                
                Text(thread.preview)
                    .font(.system(size: 13))
                    .foregroundColor(Color("TextDark").opacity(0.6))
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Time
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatTime(thread.updatedAt))
                    .font(.system(size: 12))
                    .foregroundColor(Color("TextDark").opacity(0.5))
                
                if thread.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color("GoldAccent"))
                }
            }
        }
        .padding(.vertical, 4)
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
