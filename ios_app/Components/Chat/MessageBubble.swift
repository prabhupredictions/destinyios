import SwiftUI

/// Message bubble for chat conversations (WhatsApp/iMessage style)
struct MessageBubble: View {
    let message: LocalChatMessage
    var userQuery: String = ""  // The user's question (for feedback)
    var streamingContent: String? = nil  // Live streaming text from ViewModel
    
    private var isUser: Bool {
        message.messageRole == .user
    }
    
    /// Content to display - streaming content if available, otherwise message content
    private var displayContent: String {
        streamingContent ?? message.content
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if isUser {
                // Push user message to the right
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                // Message content
                messageContent
                
                // Metadata row (confidence, area, time)
                if !isUser && !message.isStreaming {
                    metadataRow
                }
                
                // Star rating for completed AI messages
                if !isUser && !message.isStreaming && message.content.count > 50 {
                    MessageRating(
                        messageId: message.id,
                        query: userQuery.isEmpty ? "General question" : userQuery,
                        responseText: String(message.content.prefix(500)), // Limit for API
                        predictionId: message.traceId
                    )
                    .padding(.top, 4)
                }
            }
            
            if !isUser {
                // Push AI message content with spacer on right
                Spacer(minLength: 60)
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
    
    // MARK: - Message Content
    @ViewBuilder
    private var messageContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Text content with styled markdown support
            HStack(alignment: .top, spacing: 0) {
                // Render styled markdown for AI messages, plain text for user
                if isUser {
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                } else {
                    // Premium glassmorphism cards for AI responses
                    PremiumMarkdownView(
                        content: message.content,
                        textColor: Color("NavyPrimary")
                    )
                }
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isUser ? Color("NavyPrimary") : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
        )
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
                .foregroundColor(Color("GoldAccent"))
            
            ForEach(tools, id: \.self) { tool in
                Text(tool)
                    .font(.system(size: 11))
                    .foregroundColor(Color("NavyPrimary").opacity(0.7))
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
                .foregroundColor(Color("GoldAccent"))
            
            ForEach(sources, id: \.self) { source in
                Text(source)
                    .font(.system(size: 11))
                    .foregroundColor(Color("NavyPrimary").opacity(0.7))
            }
        }
    }
    
    // MARK: - Metadata Row
    @ViewBuilder
    private var metadataRow: some View {
        HStack(spacing: 12) {
            // Confidence badge
            if let confidence = message.confidence {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 10))
                    Text(confidence)
                        .font(.system(size: 11))
                }
                .foregroundColor(Color("GoldAccent"))
            }
            
            // Life area
            if let area = message.area {
                Text(area.capitalized)
                    .font(.system(size: 11))
                    .foregroundColor(Color("TextDark").opacity(0.5))
            }
            
            // Timestamp
            Text(formatTime(message.createdAt))
                .font(.system(size: 11))
                .foregroundColor(Color("TextDark").opacity(0.4))
        }
    }
    
    // MARK: - Helpers
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
                        colors: [Color("GoldAccent"), Color("GoldAccent").opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: Color("GoldAccent").opacity(0.3), radius: 4, y: 2)
            
            Text("D")
                .font(.system(size: size * 0.45, weight: .medium, design: .serif))
                .foregroundColor(Color("NavyPrimary"))
        }
    }
}

// MARK: - Blinking Cursor
struct BlinkingCursor: View {
    @State private var isVisible = true
    
    var body: some View {
        Rectangle()
            .fill(Color("NavyPrimary"))
            .frame(width: 2, height: 16)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                    isVisible.toggle()
                }
            }
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
    .background(Color(red: 0.96, green: 0.95, blue: 0.98))
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
    .background(Color(red: 0.96, green: 0.95, blue: 0.98))
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
    .background(Color(red: 0.96, green: 0.95, blue: 0.98))
}
