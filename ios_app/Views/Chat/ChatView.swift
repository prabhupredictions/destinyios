import SwiftUI

/// Main chat view with messages, input, and history sidebar
struct ChatView: View {
    // Navigation callback for back button
    var onBack: (() -> Void)? = nil
    
    // Initial question passed from HomeView
    var initialQuestion: String? = nil

    // Short label to show in the user bubble instead of the raw contextual query
    var initialDisplayLabel: String? = nil
    
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
                    isStreaming: viewModel.isStreaming,
                    isTyping: viewModel.typewriterMessageId != nil
                ) {
                    // Check quota before sending
                    if viewModel.canAskQuestion {
                        isInputFocused = false  // Dismiss keyboard on send
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                viewModel.pendingDisplayLabel = initialDisplayLabel
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
            // onChange(of:) with the iOS 17 API does NOT fire on initial creation —
            // only when the value changes while the view is already in the hierarchy.
            // Handle the initial question here so a home-screen card tap always opens a fresh chat.
            if let question = initialQuestion, !question.isEmpty, !hasHandledInitialQuestion {
                hasHandledInitialQuestion = true
                viewModel.startNewChat()
                viewModel.pendingDisplayLabel = initialDisplayLabel
                viewModel.inputText = question
                Task { await viewModel.sendMessage() }
            } else if let threadId = initialThreadId, !threadId.isEmpty, !hasHandledInitialThread {
                hasHandledInitialThread = true
                if let thread = viewModel.dataManager.fetchThread(id: threadId) {
                    viewModel.loadThread(thread)
                }
            } else {
                // Normal open — load latest thread or start new
                viewModel.loadDefaultState()
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
        // Switch Profile: reset chat to new profile's latest thread or new chat
        .onReceive(NotificationCenter.default.publisher(for: .activeProfileChanged)) { _ in
            viewModel.handleProfileSwitch()
        }
        // Dismiss keyboard when leaving the view (fixes keyboard persistence bug)
        .onDisappear {
            isInputFocused = false
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
            Text("ask_destiny".localized)
                .font(AppTheme.Fonts.title(size: 20))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            // Subtitle
            Text("chat_welcome_subtitle".localized)
                .font(AppTheme.Fonts.body(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            // Pill questions
            VStack(spacing: 10) {
                ForEach(activeStarterQuestions, id: \.self) { question in
                    Button(action: {
                        HapticManager.shared.play(.light)
                        isInputFocused = false  // Dismiss keyboard
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
    
    // MARK: - Inline Suggested Questions (vertical full-width rows)
    private var inlineSuggestedQuestionsView: some View {
        FollowUpSuggestionsView(
            questions: viewModel.suggestedQuestions
        ) { question in
            HapticManager.shared.play(.light)
            isInputFocused = false
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            viewModel.inputText = question
            viewModel.suggestedQuestions = []
            if viewModel.canAskQuestion {
                Task { await viewModel.sendMessage() }
            } else {
                showQuotaExhausted = true
            }
        }
    }
    
    // MARK: - Visible Messages (from window manager, filtered for non-empty)
    private var visibleMessages: [LocalChatMessage] {
        viewModel.windowManager.visibleMessages.filter { !$0.content.isEmpty || $0.isStreaming }
    }
    
    // MARK: - User Query Lookup (pre-computed, avoids O(n²) per-message scan)
    private var userQueryLookup: [String: String] {
        var lookup: [String: String] = [:]
        var lastUserQuery = "General question"
        for msg in viewModel.windowManager.visibleMessages {
            if msg.messageRole == .user {
                lastUserQuery = msg.content
            } else {
                lookup[msg.id] = lastUserQuery
            }
        }
        return lookup
    }
    
    // MARK: - Scroll State (single debounced trigger replaces 5 competing handlers)
    @State private var scrollTrigger = UUID()
    
    // MARK: - Messages View (matches compat chat scroll pattern exactly)
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if isNewChat && !viewModel.isLoading {
                    starterQuestionsView
                } else {
                    VStack(spacing: 24) {
                        if viewModel.windowManager.hasOlderMessages {
                            Button("Load earlier messages") {
                                // Pagination: future implementation
                            }
                            .accessibilityIdentifier("load_older_button")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.Colors.gold)
                            .padding(.bottom, 8)
                        }
                        ForEach(visibleMessages) { message in
                            MessageBubble(
                                message: message,
                                userQuery: userQueryLookup[message.id] ?? "",
                                streamingContent: nil,
                                thinkingSteps: [],
                                enableTypewriter: false,
                                cosmicProgressSteps: message.isStreaming ? viewModel.cosmicProgressSteps : []
                            )
                            .id(message.id)
                        }
                        
                        // Inline suggested questions — only after streaming finishes
                        if !viewModel.suggestedQuestions.isEmpty && !viewModel.isLoading && !viewModel.isStreaming {
                            inlineSuggestedQuestionsView
                                .id("suggestions")
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
                
                Color.clear
                    .frame(height: 1)
                    .id("bottomAnchor")
            }
            .scrollDismissesKeyboard(.interactively)
            // Single consolidated scroll handler — debounced to prevent racing animations
            .onChange(of: scrollTrigger) { _, _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo("bottomAnchor", anchor: .bottom)
                }
            }
            // Coalesce all state changes into one scroll trigger
            .onChange(of: viewModel.messages.count) { _, _ in
                requestScrollToBottom()
            }
            .onChange(of: viewModel.isLoading) { _, loading in
                if loading { requestScrollToBottom() }
            }
            .onChange(of: viewModel.suggestedQuestions) { _, q in
                if !q.isEmpty { requestScrollToBottom() }
            }
            .onChange(of: viewModel.typewriterMessageId) { _, newId in
                if newId == nil { requestScrollToBottom() }
            }
            .onChange(of: isInputFocused) { _, focused in
                if focused { requestScrollToBottom(delay: 0.3) }
            }
        }
    }
    
    /// Debounced scroll request — coalesces rapid state changes into a single scroll
    private func requestScrollToBottom(delay: Double = 0.1) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            scrollTrigger = UUID()
        }
    }
    
    // MARK: - Thinking Indicator (lean pill, reuses AnimatedDots from MessageBubble)
    private var thinkingIndicator: some View {
        HStack(spacing: 10) {
            AnimatedDots()
            
            Text("thinking".localized)
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
    
    // getUserQuery replaced by pre-computed userQueryLookup dictionary above
    
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
    
    // Search
    @State private var searchText = ""
    
    // Delete confirmation
    @State private var threadToDelete: LocalChatThread?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackgroundView().ignoresSafeArea()
                
                if !HistorySettingsManager.shared.isHistoryEnabled {
                    chatHistoryDisabledView
                } else {
                    historyList
                }
            }
            .navigationTitle("chat_history_title".localized)
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
                    Button("done_action".localized) { onDismiss() }
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
                    Button("done_action".localized) { onDismiss() }
                        .foregroundColor(AppTheme.Colors.gold)
                }
                #endif
            }
            .onAppear {
                loadFirstPage()
            }
            .alert("Delete", isPresented: $showDeleteConfirmation) {
                Button("cancel_action".localized, role: .cancel) { threadToDelete = nil }
                Button("delete_action".localized, role: .destructive) {
                    if let thread = threadToDelete {
                        viewModel.deleteThread(thread)
                        loadedThreads.removeAll { $0.id == thread.id }
                        threadToDelete = nil
                    }
                }
            } message: {
                Text(String(format: "chat_delete_thread_confirm".localized, threadToDelete?.title ?? ""))
            }
        }
    }
    
    // MARK: - History Disabled View
    private var chatHistoryDisabledView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.xmark")
                .font(AppTheme.Fonts.display(size: 48))
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.4))
            
            Text("history_turned_off".localized)
                .font(AppTheme.Fonts.title(size: 20))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("conversations_not_saved".localized)
                .font(AppTheme.Fonts.body(size: 15))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                onDismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(name: .openProfileSettings, object: nil)
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape")
                    Text("open_settings".localized)
                }
                .font(AppTheme.Fonts.title(size: 15))
                .foregroundColor(AppTheme.Colors.mainBackground)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(AppTheme.Colors.gold)
                .cornerRadius(12)
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
        
        let filtered = searchText.isEmpty ? loadedThreads : loadedThreads.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.preview.localizedCaseInsensitiveContains(searchText)
        }
        
        for thread in filtered {
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
        
        return VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .font(.system(size: 15))
                
                TextField("search_chats_placeholder".localized, text: $searchText)
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
            
            if grouped.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(AppTheme.Fonts.display(size: 48))
                        .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.2))
                    
                    Text(searchText.isEmpty ? "no_chat_history".localized : "no_results_found".localized)
                        .font(AppTheme.Fonts.body(size: 16))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                                        threadToDelete = thread
                                        showDeleteConfirmation = true
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
                Label("delete_action".localized, systemImage: "trash")
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
                Label("delete_action".localized, systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ChatView()
}
