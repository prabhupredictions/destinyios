import SwiftUI

// MARK: - Full Report Sheet
struct FullReportSheet: View {
    let result: CompatibilityResult
    let boyName: String
    let girlName: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    headerSection
                    kutasList
                    summarySection
                }
                .padding(14)
            }
            .background(AppTheme.Colors.mainBackground.ignoresSafeArea())
            .navigationTitle("Full Compatibility Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(AppTheme.Fonts.title(size: 17))
                        .foregroundColor(AppTheme.Colors.gold)
                }
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(boyName) & \(girlName)")
                    .font(AppTheme.Fonts.title(size: 14))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("\(result.totalScore)/\(result.maxScore) points")
                    .font(AppTheme.Fonts.caption(size: 11))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            Spacer()
            Text("\(Int(result.percentage * 100))%")
                .font(AppTheme.Fonts.title(size: 22))
                .foregroundColor(result.percentage >= 0.75 ? AppTheme.Colors.success : AppTheme.Colors.gold)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.Colors.gold.opacity(0.3)))
        )
    }
    
    private var kutasList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(result.kutas) { kuta in
                HStack {
                    Text(kuta.name)
                        .font(AppTheme.Fonts.body(size: 12))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                    Text("\(kuta.points)/\(kuta.maxPoints)")
                        .font(AppTheme.Fonts.body(size: 12).weight(.bold))
                        .foregroundColor(kutaColor(kuta.percentage))
                }
                Divider().background(AppTheme.Colors.gold.opacity(0.1))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.Colors.gold.opacity(0.15)))
        )
    }
     
    private var summarySection: some View {
        Group {
            if !result.summary.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                        .font(AppTheme.Fonts.caption(size: 12).weight(.semibold))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text(result.summary)
                        .font(AppTheme.Fonts.body(size: 13))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineSpacing(4)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.Colors.cardBackground)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.Colors.gold.opacity(0.15)))
                )
            }
        }
    }
    
    private func kutaColor(_ pct: Double) -> Color {
        if pct >= 0.75 { return AppTheme.Colors.success }
        else if pct >= 0.50 { return AppTheme.Colors.gold }
        else if pct >= 0.25 { return .orange }
        else { return AppTheme.Colors.error }
    }
}

// MARK: - Ask Destiny Sheet (Full Chat Implementation)
struct AskDestinySheet: View {
    let result: CompatibilityResult
    let boyName: String
    let girlName: String
    @Environment(\.dismiss) private var dismiss
    
    // Chat State
    @State private var messages: [CompatChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showQuotaSheet: Bool = false
    @State private var quotaMessage: String = ""
    @State private var showSubscription: Bool = false
    
    // Auth State (for sign-out flow)
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @AppStorage("hasBirthData") private var hasBirthData = false
    @AppStorage("isGuest") private var isGuest = false
    
    // Services
    private let compatibilityService = CompatibilityService()
    private let predictionService = PredictionService()
    private let historyService = CompatibilityHistoryService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Cosmic Background
                CosmicBackgroundView()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom transparent header
                    HStack {
                        Spacer()
                        Text("Ask Destiny")
                            .font(AppTheme.Fonts.title(size: 17))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Spacer()
                        Button("Done") { dismiss() }
                            .font(AppTheme.Fonts.title(size: 17))
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    // Messages List
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Welcome message
                                if messages.isEmpty && !isLoading {
                                    welcomeView
                                        .padding(.top, 20)
                                }
                                
                                ForEach(messages) { message in
                                    CompatChatBubble(message: message)
                                        .id(message.id)
                                }
                                
                                // Loading indicator
                                if isLoading {
                                    CompatTypingIndicator()
                                        .id("loading")
                                }
                            }
                            .padding(.horizontal, 12)  // Match ChatView padding
                            .padding(.vertical, 16)
                        }
                        .defaultScrollAnchor(.bottom)
                        .scrollDismissesKeyboard(.interactively)
                        .onChange(of: messages.count) { _, _ in
                            withAnimation {
                                if let lastId = messages.last?.id {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: isLoading) { _, _ in
                            withAnimation {
                                if isLoading {
                                    proxy.scrollTo("loading", anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Error Banner
                    if let error = errorMessage {
                        Text(error)
                            .font(AppTheme.Fonts.caption(size: 12))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppTheme.Colors.error.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                            .onTapGesture { errorMessage = nil }
                    }
                    
                    // Input Bar
                    inputBar
                }
            }
            .navigationBarHidden(true)  // Use custom header
        }
        .onAppear {
            loadStoredMessages()
        }
        .sheet(isPresented: $showQuotaSheet) {
            QuotaExhaustedView(
                isGuest: isGuest,
                customMessage: quotaMessage,
                onSignIn: { signOutAndReauth() },
                onUpgrade: {
                    if isGuest {
                        signOutAndReauth()
                    } else {
                        showQuotaSheet = false
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
    }
    
    // MARK: - Load Stored Messages
    private func loadStoredMessages() {
        print("[AskDestinySheet] loadStoredMessages called, result.sessionId = \(result.sessionId ?? "nil")")
        
        guard let sessionId = result.sessionId else {
            print("[AskDestinySheet] No sessionId available")
            return
        }
        
        // Try both with and without 'compat_' prefix (history stores with prefix)
        let prefixedSessionId = sessionId.hasPrefix("compat_") ? sessionId : "compat_\(sessionId)"
        
        // Try prefixed version first (how history is stored)
        var historyItem = historyService.get(sessionId: prefixedSessionId)
        
        // Fallback to original sessionId
        if historyItem == nil {
            historyItem = historyService.get(sessionId: sessionId)
        }
        
        guard let item = historyItem else {
            print("[AskDestinySheet] No history item found for sessionId: \(sessionId) or \(prefixedSessionId)")
            // Debug: show all stored sessionIds
            let allItems = historyService.loadAll()
            print("[AskDestinySheet] All stored sessionIds: \(allItems.map { $0.sessionId })")
            return
        }
        
        print("[AskDestinySheet] Found history item with \(item.chatMessages.count) messages")
        
        // Convert stored messages to CompatChatMessage
        // Filter out the initial compatibility report (contains markdown tables, very long)
        if !item.chatMessages.isEmpty {
            let filteredMessages = item.chatMessages.filter { msg in
                // Skip if:
                // 1. It's the first AI message with table markers (the initial report)
                // 2. Content contains markdown table separators
                // 3. Content is excessively long (full report typically > 2000 chars)
                let isReportMessage = msg.content.contains("---|") || 
                                     msg.content.contains("|---") ||
                                     msg.content.contains("KEY STRENGTHS") ||
                                     (msg.content.count > 2000 && !msg.isUser)
                return !isReportMessage
            }
            messages = filteredMessages.map { $0.toMessage() }
            print("[AskDestinySheet] Loaded \(messages.count) messages from history (filtered from \(item.chatMessages.count))")
        }
    }
    
    // MARK: - Save Messages to History
    private func saveMessagesToHistory() {
        guard let sessionId = result.sessionId else { return }
        
        // Use prefixed sessionId to match history storage format
        let prefixedSessionId = sessionId.hasPrefix("compat_") ? sessionId : "compat_\(sessionId)"
        
        // Try prefixed first, fallback to original
        let allItems = historyService.loadAll()
        let matchingSessionId = allItems.first(where: { $0.sessionId == prefixedSessionId || $0.sessionId == sessionId })?.sessionId ?? prefixedSessionId
        
        historyService.updateChatMessages(sessionId: matchingSessionId, messages: messages)
    }
    
    // MARK: - Sign Out and Re-auth (for guest → sign in flow)
    private func signOutAndReauth() {
        // PHASE 12: DO NOT clear guest data here!
        // Preserve guest birth data for carry-forward during sign-in.
        isAuthenticated = false
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        
        print("[AskDestiny] Navigating to Auth (guest data preserved for carry-forward)")
        dismiss()
    }
    
    // MARK: - Welcome View
    private var welcomeView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.gold.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundColor(AppTheme.Colors.gold)
            }
            
            Text("Ask about \(boyName) & \(girlName)")
                .font(AppTheme.Fonts.title(size: 18))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("I can answer questions about this compatibility match, their relationship dynamics, or individual insights.")
                .font(AppTheme.Fonts.body(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            // Quick Questions
            VStack(spacing: 8) {
                quickQuestionButton("What are the main challenges?")
                quickQuestionButton("How can they improve communication?")
                quickQuestionButton("What about \(boyName)'s career?")
            }
            .padding(.top, 8)
        }
        .padding(24)
    }
    
    private func quickQuestionButton(_ text: String) -> some View {
        Button {
            inputText = text
            Task { await sendMessage() }
        } label: {
            Text(text)
                .font(AppTheme.Fonts.caption(size: 13))
                .foregroundColor(AppTheme.Colors.gold)
                .padding(.horizontal, 16)
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
    }
    
    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask a question...", text: $inputText)
                .font(AppTheme.Fonts.body(size: 15))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.black.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
                .onSubmit {
                    Task { await sendMessage() }
                }
            
            Button {
                Task { await sendMessage() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(canSend ? AppTheme.Colors.gold : AppTheme.Colors.textTertiary)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(AppTheme.Colors.mainBackground.opacity(0.95))
                .overlay(
                    Rectangle()
                        .fill(LinearGradient(colors: [Color.white.opacity(0.05), Color.clear], startPoint: .top, endPoint: .bottom))
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }
    
    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
    
    // MARK: - Send Message
    private func sendMessage() async {
        let query = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        inputText = ""
        errorMessage = nil
        
        // Add user message
        let userMessage = CompatChatMessage(content: query, isUser: true, type: .user)
        messages.append(userMessage)
        
        // Check quota
        let email = UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
        
        do {
            let access = try await QuotaManager.shared.canAccessFeature(.aiQuestions, email: email)
            if !access.canAccess {
                messages.removeLast() // Remove user message
                if access.reason == "daily_limit_reached" {
                    errorMessage = "Daily limit reached. Resets tomorrow."
                } else {
                    showQuotaSheet = true
                }
                return
            }
        } catch {
            print("Quota check failed: \(error)")
        }
        
        isLoading = true
        
        // Get session ID
        guard let sessionId = result.sessionId else {
            isLoading = false
            errorMessage = "Session not found. Please run analysis again."
            return
        }
        
        do {
            // Call follow-up API
            let request = CompatibilityFollowUpRequest(
                query: query,
                sessionId: sessionId,
                userEmail: email
            )
            
            let response = try await compatibilityService.followUp(request: request)
            
            // Handle response
            if response.status == "redirect", let target = response.target {
                // Individual question - redirect to predict API
                await handleRedirect(query: query, target: target, response: response)
            } else if let answer = response.answer {
                // Normal compatibility answer
                let aiMessage = CompatChatMessage(content: answer, isUser: false, type: .ai)
                messages.append(aiMessage)
                saveMessagesToHistory()  // Persist messages
            } else if let message = response.message {
                // Info/error message
                let aiMessage = CompatChatMessage(content: message, isUser: false, type: .info)
                messages.append(aiMessage)
            }
            
        } catch {
            errorMessage = "Failed to get response. Please try again."
            print("Follow-up error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Handle Redirect to Individual Analysis
    private func handleRedirect(query: String, target: String, response: CompatibilityFollowUpResponse) async {
        // Show redirect message (temporary - will be removed when result arrives)
        let redirectMsg = CompatChatMessage(
            content: "🔄 Redirecting to \(target)'s individual analysis...",
            isUser: false,
            type: .info
        )
        messages.append(redirectMsg)
        let redirectMsgId = redirectMsg.id
        
        // Get birth data for target
        let birthDetails: BirthDetails?
        if target.lowercased().contains("boy") || target.lowercased() == boyName.lowercased() {
            birthDetails = response.birthData ?? result.analysisData?.boy?.details
        } else {
            birthDetails = response.birthData ?? result.analysisData?.girl?.details
        }
        
        guard let details = birthDetails else {
            // Remove redirect message and show error
            messages.removeAll { $0.id == redirectMsgId }
            let errorMsg = CompatChatMessage(
                content: "Could not retrieve \(target)'s birth data for individual analysis.",
                isUser: false,
                type: .error
            )
            messages.append(errorMsg)
            return
        }
        
        // Call predict API
        do {
            let birthData = BirthData(
                dob: details.dob,
                time: details.time,
                latitude: details.lat,
                longitude: details.lon,
                cityOfBirth: details.place,
                ayanamsa: "lahiri",
                houseSystem: "whole_sign"
            )
            
            let email = UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
            // Ensure conversationId matches the compatibility thread ID (compat_sess_...)
            let compatThreadId = result.sessionId.map { "compat_\($0)" }
            
            let predictRequest = PredictionRequest(
                query: query,
                birthData: birthData,
                sessionId: nil,
                conversationId: compatThreadId,
                userEmail: email,
                quotaContext: "compatibility"  // Marks this as coming from compatibility
            )
            
            let predictResponse = try await predictionService.predict(request: predictRequest)
            
            // Remove redirect message and display individual analysis
            messages.removeAll { $0.id == redirectMsgId }
            let analysisContent = "**Individual Analysis (\(target)):**\n\n\(predictResponse.answer)"
            let aiMessage = CompatChatMessage(content: analysisContent, isUser: false, type: .ai)
            messages.append(aiMessage)
            saveMessagesToHistory()  // Persist messages
            
        } catch let error as NetworkError {
            // Remove redirect message
            messages.removeAll { $0.id == redirectMsgId }
            
            // Check if it's a quota error
            let errorString = String(describing: error)
            if errorString.contains("maximum free questions") || errorString.contains("quota") || errorString.contains("limit") {
                // Show quota sheet with sign-in/upgrade options
                let email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
                if email.contains("guest") || email.contains("@gen.com") || isGuest {
                    quotaMessage = "Free questions used. Sign In or Subscribe to continue."
                } else {
                    quotaMessage = "You've reached your question limit. Subscribe for unlimited access."
                }
                showQuotaSheet = true
            } else {
                let errorMsg = CompatChatMessage(
                    content: "Failed to get individual analysis: \(error.localizedDescription)",
                    isUser: false,
                    type: .error
                )
                messages.append(errorMsg)
            }
        } catch {
            // Remove redirect message
            messages.removeAll { $0.id == redirectMsgId }
            
            // Check for quota-related errors in the error message
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("maximum free") || errorString.contains("quota") || errorString.contains("limit") {
                let email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
                if email.contains("guest") || email.contains("@gen.com") || isGuest {
                    quotaMessage = "Free questions used. Sign In or Subscribe to continue."
                } else {
                    quotaMessage = "You've reached your question limit. Subscribe for unlimited access."
                }
                showQuotaSheet = true
            } else {
                let errorMsg = CompatChatMessage(
                    content: "Failed to get individual analysis: \(error.localizedDescription)",
                    isUser: false,
                    type: .error
                )
                messages.append(errorMsg)
            }
        }
    }
}

// MARK: - Chat Bubble View (Follows ChatView Pattern)
private struct CompatChatBubble: View {
    let message: CompatChatMessage
    
    private var isUser: Bool { message.isUser }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if isUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                messageContent
            }
            
            if !isUser {
                Spacer(minLength: 16)  // Modern full-width AI messages
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
    
    @ViewBuilder
    private var messageContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isUser {
                // User message - plain text in bubble
                Text(message.content)
                    .font(AppTheme.Fonts.body(size: 16))
                    .foregroundColor(AppTheme.Colors.mainBackground)
            } else if message.type == .info {
                // Info message - styled text
                HStack(spacing: 8) {
                    if message.content.contains("Redirecting") {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.gold))
                            .scaleEffect(0.8)
                    }
                    Text(message.content)
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundColor(AppTheme.Colors.gold)
                        .italic()
                }
            } else if message.type == .error {
                // Error message
                Text(message.content)
                    .font(AppTheme.Fonts.body(size: 14))
                    .foregroundColor(AppTheme.Colors.error)
            } else {
                // AI message - use MarkdownTextView for proper rendering
                MarkdownTextView(
                    content: message.content,
                    textColor: AppTheme.Colors.textPrimary,
                    fontSize: 16
                )
            }
        }
        .padding(.horizontal, isUser ? 14 : 4)  // Less padding for AI (no bubble)
        .padding(.vertical, isUser ? 10 : 4)
        .background(userBubbleBackground)
    }
    
    @ViewBuilder
    private var userBubbleBackground: some View {
        if isUser {
            AppTheme.Colors.premiumGradient
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: AppTheme.Colors.gold.opacity(0.3), radius: 5, y: 2)
        } else {
            Color.clear  // Modern: no bubble for AI messages
        }
    }
}

// MARK: - Typing Indicator (Matches ChatView Style)
private struct CompatTypingIndicator: View {
    @State private var animateFirst = false
    @State private var animateSecond = false
    @State private var animateThird = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(spacing: 10) {
                // Animated dots
                HStack(spacing: 4) {
                    Circle()
                        .fill(AppTheme.Colors.gold)
                        .frame(width: 6, height: 6)
                        .offset(y: animateFirst ? -4 : 0)
                    Circle()
                        .fill(AppTheme.Colors.gold)
                        .frame(width: 6, height: 6)
                        .offset(y: animateSecond ? -4 : 0)
                    Circle()
                        .fill(AppTheme.Colors.gold)
                        .frame(width: 6, height: 6)
                        .offset(y: animateThird ? -4 : 0)
                }
                
                Text("Thinking...")
                    .font(AppTheme.Fonts.body(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
            )
            
            Spacer()
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
            animateFirst = true
        }
        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true).delay(0.15)) {
            animateSecond = true
        }
        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true).delay(0.3)) {
            animateThird = true
        }
    }
}

// MARK: - Chat Message Type (Required by CompatibilityHistoryItem)
struct CompatChatMessage: Identifiable {
    let id: UUID = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date = Date()
    let type: MessageType
    
    enum MessageType: String, Codable {
        case user
        case ai
        case info
        case error
    }
    
    init(content: String, isUser: Bool, type: MessageType = .ai) {
        self.content = content
        self.isUser = isUser
        self.type = type
    }
}
