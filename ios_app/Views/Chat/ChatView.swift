import SwiftUI

/// Main chat view with messages, input, and history sidebar
struct ChatView: View {
    // Navigation callback for back button
    var onBack: (() -> Void)? = nil
    
    // Initial question passed from HomeView
    var initialQuestion: String? = nil
    
    // Initial thread ID passed from History
    var initialThreadId: String? = nil
    
    // Starter questions from HomeViewModel ("What's in my mind?")
    var starterQuestions: [String] = []
    
    @State private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var showHistory = false
    @State private var showChart = false
    @State private var showQuotaExhausted = false
    @State private var showSubscription = false
    @State private var hasHandledInitialQuestion = false
    @State private var hasHandledInitialThread = false
    @State private var chatTransitionOpacity: Double = 1.0
    
    // For sign out flow
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @AppStorage("hasBirthData") private var hasBirthData = false
    @AppStorage("isGuest") private var isGuest = false
    
    var body: some View {
        ZStack {
            // Cosmic Background (Soul of the App)
            CosmicBackgroundView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                ChatHeader(
                    onBackTap: { onBack?() },
                    onHistoryTap: { showHistory.toggle() },
                    onNewChatTap: { startNewChatWithTransition() },
                    onChartTap: { showChart.toggle() }
                )
                
                // Messages
                messagesView
                    .opacity(chatTransitionOpacity)
                
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
            }
        }
        .navigationBarHidden(true)
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
                customMessage: viewModel.quotaDetails,
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
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
        }
        .onChange(of: initialQuestion) { oldValue, newValue in
            // Every new question from Home always starts a fresh chat
            if let question = newValue, !question.isEmpty, question != oldValue {
                hasHandledInitialQuestion = true
                viewModel.startNewChat()
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
            // Handle initial question on first appear — always in a NEW chat
            if let question = initialQuestion, !question.isEmpty, !hasHandledInitialQuestion {
                hasHandledInitialQuestion = true
                viewModel.startNewChat()
                viewModel.inputText = question
                Task {
                    await viewModel.sendMessage()
                }
            }
            
            if let threadId = initialThreadId, !threadId.isEmpty, !hasHandledInitialThread {
                hasHandledInitialThread = true
                if let thread = viewModel.dataManager.fetchThread(id: threadId) {
                    viewModel.loadThread(thread)
                }
            }
        }
        // Sync ViewModel quota state to View
        .onChange(of: viewModel.showQuotaSheet) { oldValue, newValue in
            showQuotaExhausted = newValue
        }
        .onChange(of: showQuotaExhausted) { oldValue, newValue in
             if !newValue {
                 viewModel.showQuotaSheet = false
             }
        }
    }
    
    // MARK: - Sign Out and Re-auth (for guest → sign in flow)
    private func signOutAndReauth() {
        // PHASE 12: DO NOT clear guest data here!
        // We want to preserve guest birth data so performSignIn can carry it forward.
        // Just set isAuthenticated = false to trigger navigation to AuthView.
        // performSignIn will capture guestBirthData and save it to the new registered user.
        
        // Only clear auth flag to show AuthView
        isAuthenticated = false
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        
        print("[SignOut] Navigating to Auth (guest data preserved for carry-forward)")
    }
    
    // MARK: - New Chat Transition (ChatGPT-like)
    private func startNewChatWithTransition() {
        HapticManager.shared.play(.medium)
        isInputFocused = false
        
        // Fade out current messages
        withAnimation(.easeOut(duration: 0.2)) {
            chatTransitionOpacity = 0.0
        }
        
        // After fade-out completes, create new chat and fade back in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            viewModel.startNewChat()
            withAnimation(.easeIn(duration: 0.25)) {
                chatTransitionOpacity = 1.0
            }
        }
    }
    
    // MARK: - Starter Questions ("What's in my mind?" from Home)
    private static let fallbackQuestions = [
        "When will I get married?",
        "Best career direction?",
        "Financial outlook?",
        "Health check"
    ]
    
    private var activeStarterQuestions: [String] {
        let questions = starterQuestions.isEmpty ? Self.fallbackQuestions : Array(starterQuestions.prefix(4))
        return questions
    }
    
    private var isNewChat: Bool {
        let nonStreamingMessages = viewModel.messages.filter { !$0.isStreaming }
        return nonStreamingMessages.count <= 1
    }
    
    private var starterQuestionsView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // Sparkle icon (matches compat chat welcomeView)
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.gold.opacity(0.1))
                    .frame(width: 72, height: 72)
                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundColor(AppTheme.Colors.gold)
            }
            
            // Title
            Text("Ask Destiny")
                .font(AppTheme.Fonts.title(size: 20))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            // Subtitle
            Text("Your personal astrology guide. Ask about your day, relationships, career, or path ahead.")
                .font(AppTheme.Fonts.body(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            // Pill questions
            VStack(spacing: 10) {
                ForEach(activeStarterQuestions, id: \.self) { question in
                    Button(action: {
                        HapticManager.shared.play(.light)
                        viewModel.inputText = question
                        if viewModel.canAskQuestion {
                            Task { await viewModel.sendMessage() }
                        } else {
                            showQuotaExhausted = true
                        }
                    }) {
                        Text(question)
                            .font(AppTheme.Fonts.caption(size: 13))
                            .foregroundColor(AppTheme.Colors.gold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(AppTheme.Colors.gold.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
    
    // MARK: - Inline Suggested Questions (horizontal scrollable pills)
    private var inlineSuggestedQuestionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("suggested_questions".localized)
                .font(AppTheme.Fonts.caption())
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.suggestedQuestions, id: \.self) { question in
                        Button(action: {
                            HapticManager.shared.play(.light)
                            viewModel.inputText = question
                            viewModel.suggestedQuestions = []
                            if viewModel.canAskQuestion {
                                Task { await viewModel.sendMessage() }
                            } else {
                                showQuotaExhausted = true
                            }
                        }) {
                            Text(question)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppTheme.Colors.gold)
                                .lineLimit(1)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.Colors.gold.opacity(0.1))
                                        .overlay(
                                            Capsule()
                                                .stroke(AppTheme.Colors.gold.opacity(0.35), lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Messages View (matches compat chat scroll pattern exactly)
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if isNewChat && !viewModel.isLoading {
                    starterQuestionsView
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.messages.filter { !$0.content.isEmpty }) { message in
                            MessageBubble(
                                message: message,
                                userQuery: getUserQuery(for: message),
                                streamingContent: nil,
                                thinkingSteps: [],
                                enableTypewriter: message.id == viewModel.typewriterMessageId,
                                onTypewriterFinished: {
                                    viewModel.typewriterMessageId = nil
                                }
                            )
                            .id(message.id)
                        }
                        
                        // Loading indicator (matches compat chat's CompatTypingIndicator)
                        if viewModel.isLoading {
                            thinkingIndicator
                                .id("loading")
                        }
                        
                        // Inline suggested questions — only after typewriter finishes
                        if !viewModel.suggestedQuestions.isEmpty && !viewModel.isLoading && viewModel.typewriterMessageId == nil {
                            inlineSuggestedQuestionsView
                                .id("suggestions")
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                }
                
                Color.clear
                    .frame(height: 1)
                    .id("bottomAnchor")
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            // Scroll when a new message is added (user msg or AI response)
            .onChange(of: viewModel.messages.count) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("bottomAnchor", anchor: .bottom)
                    }
                }
            }
            // Scroll when loading starts (show thinking indicator)
            .onChange(of: viewModel.isLoading) { _, isLoading in
                withAnimation {
                    if isLoading {
                        proxy.scrollTo("loading", anchor: .bottom)
                    }
                }
            }
            // Scroll smoothly when suggested questions appear
            .onChange(of: viewModel.suggestedQuestions) { _, newQuestions in
                if !newQuestions.isEmpty && viewModel.typewriterMessageId == nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("suggestions", anchor: .bottom)
                        }
                    }
                }
            }
            // Scroll when typewriter finishes (suggestions may already be loaded)
            .onChange(of: viewModel.typewriterMessageId) { _, newId in
                if newId == nil && !viewModel.suggestedQuestions.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("suggestions", anchor: .bottom)
                        }
                    }
                }
            }
            // Scroll when keyboard appears
            .onChange(of: isInputFocused) { _, focused in
                if focused {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            proxy.scrollTo("bottomAnchor", anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Thinking Indicator (lean pill, reuses AnimatedDots from MessageBubble)
    private var thinkingIndicator: some View {
        HStack(spacing: 10) {
            AnimatedDots()
            
            Text("Thinking...")
                .font(AppTheme.Fonts.body(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
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
                .font(AppTheme.Fonts.body(size: 14))
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
    
}

// MARK: - Chat History Sidebar
struct ChatHistorySidebar: View {
    let viewModel: ChatViewModel
    let onDismiss: () -> Void
    
    // Pagination state
    @State private var loadedThreads: [LocalChatThread] = []
    @State private var hasMore = false
    @State private var isLoadingMore = false
    private let pageSize = 20
    @State private var currentOffset = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackgroundView().ignoresSafeArea()
                
                historyList
            }
            .navigationTitle("Chat History")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { viewModel.startNewChat(); onDismiss() }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onDismiss() }
                        .foregroundColor(AppTheme.Colors.gold)
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                     Button(action: { viewModel.startNewChat(); onDismiss() }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDismiss() }
                        .foregroundColor(AppTheme.Colors.gold)
                }
                #endif
            }
            .onAppear {
                loadFirstPage()
            }
        }
    }
    
    // MARK: - Pagination
    private func loadFirstPage() {
        let userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
        let activeProfileId = ProfileContextManager.shared.activeProfileId
        let result = viewModel.dataManager.fetchChatThreadsPaginated(for: userEmail, profileId: activeProfileId, limit: pageSize, offset: 0)
        loadedThreads = result.threads
        hasMore = result.hasMore
        currentOffset = result.threads.count
    }
    
    private func loadMore() {
        guard hasMore, !isLoadingMore else { return }
        isLoadingMore = true
        let userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
        let activeProfileId = ProfileContextManager.shared.activeProfileId
        let result = viewModel.dataManager.fetchChatThreadsPaginated(for: userEmail, profileId: activeProfileId, limit: pageSize, offset: currentOffset)
        loadedThreads.append(contentsOf: result.threads)
        hasMore = result.hasMore
        currentOffset += result.threads.count
        isLoadingMore = false
    }
    
    // MARK: - Group threads by date (operates on loaded page only)
    private var groupedThreads: [(String, [LocalChatThread])] {
        let calendar = Calendar.current
        let now = Date()
        var grouped: [String: [LocalChatThread]] = [:]
        
        for thread in loadedThreads {
            let key: String
            if calendar.isDateInToday(thread.updatedAt) {
                key = "Today"
            } else if calendar.isDateInYesterday(thread.updatedAt) {
                key = "Yesterday"
            } else if let daysAgo = calendar.dateComponents([.day], from: thread.updatedAt, to: now).day, daysAgo < 7 {
                key = "Last 7 Days"
            } else if let daysAgo = calendar.dateComponents([.day], from: thread.updatedAt, to: now).day, daysAgo < 30 {
                key = "Last 30 Days"
            } else {
                key = "Older"
            }
            grouped[key, default: []].append(thread)
        }
        
        let order = ["Today", "Yesterday", "Last 7 Days", "Last 30 Days", "Older"]
        return order.compactMap { key in
            if let threads = grouped[key], !threads.isEmpty {
                return (key, threads)
            }
            return nil
        }
    }
    
    // MARK: - History List with Swipe Actions
    private var historyList: some View {
        let grouped = groupedThreads
        
        return Group {
            if grouped.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(AppTheme.Fonts.display(size: 48))
                        .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.2))
                    
                    Text("no_chat_history".localized)
                        .font(AppTheme.Fonts.body(size: 16))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else {
                List {
                    ForEach(grouped, id: \.0) { group in
                        Section(header:
                            Text(group.0)
                                .font(AppTheme.Fonts.caption())
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .textCase(.uppercase)
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
                                        loadedThreads.removeAll { $0.id == thread.id }
                                    },
                                    onPin: {
                                        viewModel.togglePinThread(thread)
                                    }
                                )
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                                .onAppear {
                                    // Load more when near the end
                                    if thread.id == loadedThreads.last?.id {
                                        loadMore()
                                    }
                                }
                            }
                        }
                    }
                    
                    // Loading more indicator
                    if isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                                .tint(AppTheme.Colors.gold)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
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
                        .font(AppTheme.Fonts.caption(size: 12))
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
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            .tint(AppTheme.Colors.error)
            
            Button(action: onPin) {
                Label(
                    thread.isPinned ? "Unpin" : "Pin",
                    systemImage: thread.isPinned ? "pin.slash" : "pin"
                )
            }
            .tint(AppTheme.Colors.gold)
        }
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
