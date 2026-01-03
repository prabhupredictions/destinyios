import SwiftUI

/// Main chat view with messages, input, and history sidebar
struct ChatView: View {
    // Navigation callback for back button
    var onBack: (() -> Void)? = nil
    
    // Initial question passed from HomeView
    var initialQuestion: String? = nil
    
    // Initial thread ID passed from History
    var initialThreadId: String? = nil
    
    @State private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var showHistory = false
    @State private var showChart = false
    @State private var showQuotaExhausted = false
    @State private var showSubscription = false
    @State private var hasHandledInitialQuestion = false
    @State private var hasHandledInitialThread = false
    
    // For sign out flow
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @AppStorage("hasBirthData") private var hasBirthData = false
    @AppStorage("isGuest") private var isGuest = false
    
    var body: some View {
        ZStack {
            // Dark Background
            AppTheme.Colors.mainBackground.ignoresSafeArea()
            
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
                
                // Suggested follow-up questions (after last response)
                if !viewModel.suggestedQuestions.isEmpty && !viewModel.isLoading {
                    suggestedQuestionsView
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
                onUpgrade: { 
                    // For guests: require sign-in first, then they can upgrade
                    if isGuest {
                        signOutAndReauth()
                    } else {
                        showSubscription = true 
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
        }
        .onChange(of: initialQuestion) { oldValue, newValue in
            // When we receive an initial question, send it immediately
            if let question = newValue, !question.isEmpty, !hasHandledInitialQuestion {
                hasHandledInitialQuestion = true
                viewModel.inputText = question
                Task {
                    await viewModel.sendMessage()
                }
            }
        }
        // Handle initial thread ID change
        .onChange(of: initialThreadId) { oldValue, newValue in
            if let threadId = newValue, !threadId.isEmpty {
                // Find thread in history - need to load history first if not ready
                if let thread = viewModel.chatHistory.first(where: { $0.id == threadId }) {
                    viewModel.loadThread(thread)
                } else {
                    // Try to fetch specific thread
                    if let thread = viewModel.dataManager.fetchThread(id: threadId) {
                        viewModel.loadThread(thread)
                    }
                }
            }
        }
        .onAppear {
            // Handle initial question on first appear
            if let question = initialQuestion, !question.isEmpty, !hasHandledInitialQuestion {
                hasHandledInitialQuestion = true
                viewModel.inputText = question
                Task {
                    await viewModel.sendMessage()
                }
            }
            
            // Handle initial thread ID
            if let threadId = initialThreadId, !threadId.isEmpty, !hasHandledInitialThread {
                hasHandledInitialThread = true
                if let thread = viewModel.dataManager.fetchThread(id: threadId) {
                    viewModel.loadThread(thread)
                }
            }
        }
    }
    
    // MARK: - Sign Out and Re-auth (for guest → sign in flow)
    private func signOutAndReauth() {
        // Clear all guest data so user starts fresh with Apple Sign-In
        
        // 1. Clear auth state
        isGuest = false
        isAuthenticated = false
        hasBirthData = false
        
        // 2. Clear UserDefaults
        let keysToRemove = [
            "userEmail", "userName", "quotaUsed", "userBirthData",
            "hasBirthData", "userGender", "birthTimeUnknown", "isGuest"
        ]
        keysToRemove.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        
        // 3. Clear keychain
        let keychain = KeychainService.shared
        keychain.delete(forKey: KeychainService.Keys.userId)
        keychain.delete(forKey: KeychainService.Keys.authToken)
        
        print("[SignOut] Guest data cleared for fresh sign-in")
    }
    
    // MARK: - Messages View (Optimized for smooth scrolling)
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Show all messages including streaming ones
                    ForEach(viewModel.messages.filter { 
                        !$0.content.isEmpty || 
                        $0.isStreaming  // Show streaming placeholder for loading state
                    }) { message in
                        MessageBubble(
                            message: message,
                            userQuery: getUserQuery(for: message),
                            streamingContent: message.isStreaming ? viewModel.streamingContent : nil,
                            thinkingSteps: message.isStreaming ? viewModel.thinkingSteps : []
                        )
                        .id(message.id)
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
        // Scroll to last visible content, not invisible anchor
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                // If loading, scroll to typing indicator
                if viewModel.isLoading {
                    proxy.scrollTo("typing", anchor: .bottom)
                } 
                // Otherwise scroll to last message
                else if let lastMessage = viewModel.messages.last(where: { !$0.content.isEmpty }) {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
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
                .font(AppTheme.Fonts.body(size: 14))
        }
        .foregroundColor(AppTheme.Colors.textPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.error.opacity(0.85))
        )
        .padding(.horizontal, 16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Suggested Questions
    private var suggestedQuestionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("suggested_questions".localized)
                .font(AppTheme.Fonts.caption())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.suggestedQuestions, id: \.self) { question in
                        Button(action: {
                            // Clear suggestions and send as new message
                            viewModel.inputText = question
                            viewModel.suggestedQuestions = []
                            if viewModel.canAskQuestion {
                                Task { await viewModel.sendMessage() }
                            } else {
                                showQuotaExhausted = true
                            }
                        }) {
                            Text(question)
                                .font(AppTheme.Fonts.body(size: 13))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(AppTheme.Colors.cardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 8)
        .background(AppTheme.Colors.mainBackground)
    }
}

// MARK: - Chat History Sidebar
struct ChatHistorySidebar: View {
    let viewModel: ChatViewModel
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.mainBackground.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Group threads by date
                        let grouped = viewModel.dataManager.fetchThreadsGroupedByDate(for: viewModel.currentSessionId)
                        
                        ForEach(grouped, id: \.0) { group in
                            Section(header: 
                                HStack {
                                    Text(group.0)
                                        .font(AppTheme.Fonts.caption())
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                        .textCase(.uppercase)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                .padding(.bottom, 8)
                            ) {
                                ForEach(group.1, id: \.id) { thread in
                                    HistoryRow(
                                        thread: thread,
                                        isSelected: thread.id == viewModel.currentThreadId,
                                        onTap: {
                                            viewModel.loadThread(thread)
                                            onDismiss()
                                        },
                                        onDelete: {
                                            viewModel.deleteThread(thread)
                                        },
                                        onPin: {
                                            viewModel.togglePinThread(thread)
                                        }
                                    )
                                }
                            }
                        }
                        
                        if grouped.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 48))
                                    .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.2))
                                
                                Text("no_chat_history".localized)
                                    .font(AppTheme.Fonts.body(size: 16))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                        }
                    }
                }
            }
            .navigationTitle("Chat History")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbarBackground(AppTheme.Colors.mainBackground, for: .navigationBar)
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { onDismiss() }
                        .foregroundColor(AppTheme.Colors.gold)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { viewModel.startNewChat(); onDismiss() }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onDismiss() }
                        .foregroundColor(AppTheme.Colors.gold)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { viewModel.startNewChat(); onDismiss() }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(AppTheme.Colors.gold)
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
                        .foregroundColor(AppTheme.Colors.gold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(thread.title)
                        .font(AppTheme.Fonts.body(size: 15))
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Text(thread.preview)
                        .font(AppTheme.Fonts.body(size: 13))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text("\(thread.messageCount)")
                    .font(AppTheme.Fonts.caption())
                    .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppTheme.Colors.cardBackground : Color.clear)
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
