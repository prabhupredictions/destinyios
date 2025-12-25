import SwiftUI

/// Main chat view with messages, input, and history sidebar
struct ChatView: View {
    // Navigation callback for back button
    var onBack: (() -> Void)? = nil
    
    @State private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var showHistory = false
    @State private var showChart = false
    @State private var showQuotaExhausted = false
    @State private var showSubscription = false
    
    // For sign out flow
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @AppStorage("hasBirthData") private var hasBirthData = false
    @AppStorage("isGuest") private var isGuest = false
    
    var body: some View {
        ZStack {
            // Animated orbital background with rotating planets
            MinimalOrbitalBackground()
            
            VStack(spacing: 0) {
                // Header
                ChatHeader(
                    onBackTap: { onBack?() },
                    onHistoryTap: { showHistory.toggle() },
                    onNewChatTap: { viewModel.startNewChat() },
                    onChartTap: { showChart.toggle() }
                )
                
                // Messages
                messagesView
                
                // Error message
                if let error = viewModel.errorMessage {
                    errorBanner(error)
                }
                
                // Input bar
                ChatInputBar(
                    text: $viewModel.inputText,
                    isFocused: $isInputFocused,
                    isLoading: viewModel.isLoading,
                    isStreaming: viewModel.isStreaming
                ) {
                    // Check quota before sending
                    if viewModel.canAskQuestion {
                        Task { await viewModel.sendMessage() }
                    } else {
                        showQuotaExhausted = true
                    }
                }
                
                // Note: Bottom spacer removed - tab bar is hidden on chat screen
            }
        }
        .sheet(isPresented: $showHistory) {
            ChatHistorySidebar(viewModel: viewModel) {
                showHistory = false
            }
        }
        .sheet(isPresented: $showChart) {
            PlanetaryPositionsSheet()
        }
        .sheet(isPresented: $showQuotaExhausted) {
            QuotaExhaustedView(
                isGuest: isGuest,
                onSignIn: { signOutAndReauth() },
                onUpgrade: { showSubscription = true }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
        }
    }
    
    // MARK: - Sign Out and Re-auth (for guest → sign in flow)
    private func signOutAndReauth() {
        isGuest = false
        isAuthenticated = false
        hasBirthData = false
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "quotaUsed")
    }
    
    // MARK: - Messages View (Optimized for smooth scrolling)
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Simple ForEach using direct id (no Array enumeration)
                    ForEach(viewModel.messages) { message in
                        MessageBubble(
                            message: message,
                            userQuery: getUserQuery(for: message)
                        )
                        .id(message.id)
                    }
                    
                    // Typing indicator while waiting for API response
                    if viewModel.isLoading {
                        PremiumTypingIndicator()
                            .id("typing")
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    
                    // Bottom anchor for reliable scrolling
                    Color.clear
                        .frame(height: 1)
                        .id("bottomAnchor")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .defaultScrollAnchor(.bottom)  // iOS 17+ - start at bottom
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: viewModel.isLoading) { oldValue, newValue in
                // Scroll when loading starts or ends
                scrollToBottom(proxy)
            }
        }
    }
    
    // Pre-compute user query outside of ForEach body
    private func getUserQuery(for message: LocalChatMessage) -> String {
        guard message.messageRole != .user else { return "" }
        
        // Find the previous user message
        guard let index = viewModel.messages.firstIndex(where: { $0.id == message.id }) else {
            return ""
        }
        return findPreviousUserQuery(before: index)
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        // Use spring animation for smooth, natural feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                proxy.scrollTo("bottomAnchor", anchor: .bottom)
            }
        }
    }
    
    /// Find the user's question that precedes an AI message (for feedback)
    private func findPreviousUserQuery(before index: Int) -> String {
        for i in stride(from: index - 1, through: 0, by: -1) {
            if viewModel.messages[i].messageRole == .user {
                return viewModel.messages[i].content
            }
        }
        return "General question"
    }
    
    // MARK: - Error Banner
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
            Text(message)
                .font(.system(size: 14))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.85))
        )
        .padding(.horizontal, 16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Chat History Sidebar
struct ChatHistorySidebar: View {
    let viewModel: ChatViewModel
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Group threads by date
                    let grouped = viewModel.dataManager.fetchThreadsGroupedByDate(for: viewModel.currentSessionId)
                    
                    ForEach(grouped, id: \.0) { group in
                        Section {
                            ForEach(group.1, id: \.id) { thread in
                                HistoryRow(
                                    thread: thread,
                                    isSelected: thread.id == viewModel.currentThreadId
                                ) {
                                    viewModel.loadThread(thread)
                                    onDismiss()
                                } onDelete: {
                                    viewModel.deleteThread(thread)
                                } onPin: {
                                    viewModel.togglePinThread(thread)
                                }
                            }
                        } header: {
                            HStack {
                                Text(group.0)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color("TextDark").opacity(0.5))
                                    .textCase(.uppercase)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 8)
                        }
                    }
                    
                    if grouped.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 48))
                                .foregroundColor(Color("NavyPrimary").opacity(0.2))
                            
                            Text("No chat history yet")
                                .font(.system(size: 16))
                                .foregroundColor(Color("TextDark").opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    }
                }
            }
            .background(Color(red: 0.96, green: 0.95, blue: 0.98))
            .navigationTitle("Chat History")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { onDismiss() }
                        .foregroundColor(Color("NavyPrimary"))
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { viewModel.startNewChat(); onDismiss() }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(Color("NavyPrimary"))
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onDismiss() }
                        .foregroundColor(Color("NavyPrimary"))
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { viewModel.startNewChat(); onDismiss() }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(Color("NavyPrimary"))
                    }
                }
                #endif
            }
        }
    }
}

// MARK: - History Row
struct HistoryRow: View {
    let thread: LocalChatThread
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onPin: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Pin indicator
                if thread.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color("GoldAccent"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(thread.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color("NavyPrimary"))
                        .lineLimit(1)
                    
                    Text(thread.preview)
                        .font(.system(size: 13))
                        .foregroundColor(Color("TextDark").opacity(0.5))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Message count
                Text("\(thread.messageCount)")
                    .font(.system(size: 12))
                    .foregroundColor(Color("TextDark").opacity(0.4))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color("NavyPrimary").opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: onPin) {
                Label(
                    thread.isPinned ? "Unpin" : "Pin",
                    systemImage: thread.isPinned ? "pin.slash" : "pin"
                )
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ChatView()
}
