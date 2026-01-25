import SwiftUI

/// Message bubble for chat conversations - ChatGPT-style streaming support
struct MessageBubble: View {
    let message: LocalChatMessage
    var userQuery: String = ""
    var streamingContent: String? = nil
    var thinkingSteps: [ThinkingStep] = []  // For streaming progress
    
    private var isUser: Bool {
        message.messageRole == .user
    }
    
    private var displayContent: String {
        streamingContent ?? message.content
    }
    
    private var isWelcomeMessage: Bool {
        message.content.contains("I'm Destiny, your personal astrology guide")
    }
    
    // Check if we're in loading/streaming state
    private var isLoadingState: Bool {
        message.isStreaming && displayContent.isEmpty
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if isUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                // Message content
                messageContent
                
                // Metadata row with inline rating (timestamp + time + rating stars)
                if !isUser && !message.isStreaming {
                    metadataRowWithRating
                }
            }
            
            if !isUser {
                Spacer(minLength: 16) // Modern full-width AI messages
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
    
    // MARK: - Message Content
    @ViewBuilder
    private var messageContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isUser {
                // User message - plain text
                Text(message.content)
                    .font(AppTheme.Fonts.body(size: 16)) // HIG standard body text
                    .foregroundColor(AppTheme.Colors.mainBackground) // Dark text on gold gradient
            } else if isLoadingState {
                // AI loading state - show progress inside bubble
                streamingProgressView
            } else if !displayContent.isEmpty {
                // AI message with content
                MarkdownTextView(
                    content: displayContent,
                    textColor: AppTheme.Colors.textPrimary,
                    fontSize: 16 // HIG standard body text
                )
            }
            
            // Tool calls chips (if any)
            if !message.toolCalls.isEmpty {
                toolCallsView(message.toolCalls)
            }
            
            // Sources chips (if any)
            if !message.sources.isEmpty {
                sourcesView(message.sources)
            }
        }
        .padding(.horizontal, 12) // Optimized per HIG (less visual padding)
        .padding(.vertical, 10)
        .background(
            Group {
                if isUser {
                    AppTheme.Colors.premiumGradient
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: AppTheme.Colors.gold.opacity(0.3), radius: 5, y: 2)
                } else {
                    Color.clear // Modern: no bubble for AI messages
                }
            }
        )
    }
    
    // MARK: - Streaming Progress View (Claude-style collapsible)
    @ViewBuilder
    private var streamingProgressView: some View {
        CollapsibleProgressView(thinkingSteps: thinkingSteps)
    }
    
    // Fallback parser for **bold** syntax
    private func parseSimpleMarkdown(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        
        // Find and style **bold** text
        let pattern = "\\*\\*(.+?)\\*\\*"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: text),
                   let attrRange = result.range(of: String(text[range])) {
                    // Get the content without asterisks
                    if let innerRange = Range(match.range(at: 1), in: text) {
                        let boldText = String(text[innerRange])
                        var boldAttr = AttributedString(boldText)
                        boldAttr.font = .system(size: 15, weight: .bold)
                        result.replaceSubrange(attrRange, with: boldAttr)
                    }
                }
            }
        }
        
        return result
    }
    
    // MARK: - Tool Calls
    @ViewBuilder
    private func toolCallsView(_ tools: [String]) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 10))
                .foregroundColor(AppTheme.Colors.gold)
            
            ForEach(tools, id: \.self) { tool in
                Text(tool)
                    .font(AppTheme.Fonts.caption())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Sources
    @ViewBuilder
    private func sourcesView(_ sources: [String]) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "book.closed")
                .font(.system(size: 10))
                .foregroundColor(AppTheme.Colors.gold)
            
            ForEach(sources, id: \.self) { source in
                Text(source)
                    .font(AppTheme.Fonts.caption())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    // MARK: - Metadata Row with Inline Rating
    @ViewBuilder
    private var metadataRowWithRating: some View {
        HStack(spacing: 6) {
            // Timestamp
            Text(formatTime(message.createdAt))
                .font(AppTheme.Fonts.caption(size: 10))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            // Execution time (if available from API response)
            if message.executionTimeMs > 0 {
                Text("•")
                    .font(AppTheme.Fonts.caption(size: 10))
                    .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.6))
                
                Text(formatExecutionTime(message.executionTimeMs))
                    .font(AppTheme.Fonts.caption(size: 10))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            
            Spacer()
            
            // Inline rating (only for substantial AI messages)
            if !isWelcomeMessage && message.content.count > 50 {
                InlineMessageRating(
                    message: message,
                    query: userQuery.isEmpty ? "General question" : userQuery,
                    responseText: String(message.content.prefix(500)),
                    predictionId: message.traceId
                )
            }
        }
    }
    
    // MARK: - Helpers
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatExecutionTime(_ ms: Double) -> String {
        let seconds = ms / 1000
        if seconds < 1 {
            return String(format: "%.0fms", ms)
        } else if seconds < 60 {
            return String(format: "%.1fs", seconds)
        } else {
            let mins = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return "\(mins)m \(secs)s"
        }
    }
}

// MARK: - Avatar View
struct AvatarView: View {
    var size: CGFloat = 32
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.Colors.gold, AppTheme.Colors.gold.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: AppTheme.Colors.gold.opacity(0.3), radius: 4, y: 2)
            
            Text("D")
                .font(.system(size: size * 0.45, weight: .medium, design: .serif))
                .foregroundColor(AppTheme.Colors.mainBackground)
        }
    }
}

// MARK: - Blinking Cursor
struct BlinkingCursor: View {
    @State private var isVisible = true
    
    var body: some View {
        Rectangle()
            .fill(AppTheme.Colors.gold)
            .frame(width: 2, height: 16)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                    isVisible.toggle()
                }
            }
    }
}

// MARK: - Animated Dots Component
struct AnimatedDots: View {
    @State private var animateFirst = false
    @State private var animateSecond = false
    @State private var animateThird = false
    
    var body: some View {
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

// MARK: - Collapsible Progress View (Claude-style)
struct CollapsibleProgressView: View {
    let thinkingSteps: [ThinkingStep]
    @State private var isExpanded = false
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - always visible, tappable
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 10) {
                    // Animated spinner
                    AnimatedDots()
                    
                    // Status text
                    Text("Analyzing your chart")
                        .font(AppTheme.Fonts.body(size: 14).weight(.medium))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    // Elapsed time
                    Text(formatTime(elapsedSeconds))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(AppTheme.Colors.gold)
                    
                    // Expand/collapse chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable details
            if isExpanded && !thinkingSteps.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Divider()
                        .background(AppTheme.Colors.separator)
                        .padding(.vertical, 8)
                    
                    ForEach(Array(thinkingSteps.suffix(8))) { step in
                        HStack(alignment: .top, spacing: 8) {
                            Text(step.type.icon)
                                .font(.system(size: 12))
                            
                            Text(step.content ?? step.display)
                                .font(AppTheme.Fonts.caption())
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .lineLimit(2)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(minWidth: 220, alignment: .leading)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Preview
#Preview("User Message") {
    MessageBubble(
        message: LocalChatMessage(
            threadId: "1",
            role: .user,
            content: "What's my career outlook for 2024?"
        )
    )
    .padding()
    .background(AppTheme.Colors.mainBackground)
}

#Preview("AI Message") {
    MessageBubble(
        message: LocalChatMessage(
            threadId: "1",
            role: .assistant,
            content: "Based on your chart, Saturn's transit through your 10th house suggests a period of significant professional growth. You may face some challenges, but they will ultimately lead to greater stability.",
            area: "career",
            confidence: "High",
            toolCalls: ["10th house", "Saturn transit"],
            sources: ["BPHS Ch.12"]
        )
    )
    .padding()
    .background(AppTheme.Colors.mainBackground)
}

#Preview("Streaming") {
    MessageBubble(
        message: LocalChatMessage(
            threadId: "1",
            role: .assistant,
            content: "Based on your chart, Saturn's",
            isStreaming: true
        )
    )
    .padding()
    .background(AppTheme.Colors.mainBackground)
}

#Preview("Loading State") {
    MessageBubble(
        message: LocalChatMessage(
            threadId: "1",
            role: .assistant,
            content: "",
            isStreaming: true
        ),
        thinkingSteps: [
            ThinkingStep(step: 1, type: .thought, display: "Examining birth chart...", content: "Analyzing Saturn's position in the 10th house..."),
            ThinkingStep(step: 2, type: .action, display: "Running Dasha", content: "Calculating Moon-Saturn-Rahu dasha period...")
        ]
    )
    .padding()
    .background(Color(red: 0.96, green: 0.95, blue: 0.98))
}
