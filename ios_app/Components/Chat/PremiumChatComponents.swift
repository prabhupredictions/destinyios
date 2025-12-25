import SwiftUI

// MARK: - Message Arrival Animation Wrapper
/// Wraps message bubbles with smooth entrance animations
struct AnimatedMessageBubble: View {
    let message: LocalChatMessage
    let index: Int
    var userQuery: String = ""  // For feedback
    var streamingContent: String? = nil  // Live streaming text
    
    @State private var appeared = false
    
    private var isUser: Bool {
        message.messageRole == .user
    }
    
    var body: some View {
        MessageBubble(message: message, userQuery: userQuery, streamingContent: streamingContent)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .offset(x: appeared ? 0 : (isUser ? 30 : -30))
            .scaleEffect(appeared ? 1 : 0.9)
            .onAppear {
                // Staggered animation for multiple messages
                let delay = Double(index % 3) * 0.05
                withAnimation(
                    .spring(response: 0.4, dampingFraction: 0.75)
                    .delay(delay)
                ) {
                    appeared = true
                }
            }
    }
}

// MARK: - Glassmorphism Card
/// Frosted glass effect card for premium sections
struct GlassmorphismCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20
    var blurRadius: CGFloat = 10
    
    init(cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .background(
                ZStack {
                    // Frosted glass effect
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    // Subtle gradient overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Border glow
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color("NavyPrimary").opacity(0.08), radius: 12, y: 4)
    }
}

// MARK: - Verdict Visual Card
/// Premium verdict display with probability gauge
struct VerdictCard: View {
    let verdictText: String
    let probability: Double  // 0.0 to 1.0
    let sentiment: VerdictSentiment
    
    enum VerdictSentiment {
        case positive, neutral, negative
        
        var icon: String {
            switch self {
            case .positive: return "checkmark.circle.fill"
            case .neutral: return "minus.circle.fill"
            case .negative: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .positive: return Color("GoldAccent")
            case .neutral: return Color("NavyPrimary")
            case .negative: return Color.orange
            }
        }
        
        var label: String {
            switch self {
            case .positive: return "FAVORABLE"
            case .neutral: return "NEUTRAL"
            case .negative: return "CHALLENGING"
            }
        }
    }
    
    @State private var animatedProbability: Double = 0
    @State private var appeared = false
    
    var body: some View {
        GlassmorphismCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("GoldAccent"))
                    
                    Text("VERDICT")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(Color("GoldAccent"))
                    
                    Spacer()
                    
                    // Sentiment badge
                    HStack(spacing: 4) {
                        Image(systemName: sentiment.icon)
                            .font(.system(size: 12))
                        Text(sentiment.label)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(sentiment.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(sentiment.color.opacity(0.15))
                    )
                }
                
                // Verdict text
                Text(verdictText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("NavyPrimary"))
                    .lineSpacing(4)
                
                // Probability gauge
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Confidence")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color("NavyPrimary").opacity(0.6))
                        
                        Spacer()
                        
                        Text("\(Int(animatedProbability * 100))%")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color("GoldAccent"))
                    }
                    
                    // Gauge bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color("NavyPrimary").opacity(0.1))
                                .frame(height: 8)
                            
                            // Filled portion
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color("GoldAccent"),
                                            Color("GoldAccent").opacity(0.8)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * animatedProbability, height: 8)
                                .shadow(color: Color("GoldAccent").opacity(0.4), radius: 4)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding(20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animatedProbability = probability
                appeared = true
            }
        }
    }
}

// MARK: - Timing Visual Card
/// Visual timeline for timing predictions
struct TimingCard: View {
    let timingText: String
    let startMonth: String
    let endMonth: String
    
    var body: some View {
        GlassmorphismCard {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color("NavyPrimary"))
                    
                    Text("TIMING")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(Color("NavyPrimary"))
                }
                
                // Timing text
                Text(timingText)
                    .font(.system(size: 15))
                    .foregroundColor(Color("NavyPrimary").opacity(0.85))
                    .lineSpacing(3)
                
                // Visual timeline
                if !startMonth.isEmpty && !endMonth.isEmpty {
                    HStack(spacing: 0) {
                        // Start
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color("GoldAccent"))
                                .frame(width: 10, height: 10)
                            Text(startMonth)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color("NavyPrimary").opacity(0.6))
                        }
                        
                        // Line
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color("GoldAccent"),
                                        Color("GoldAccent").opacity(0.3)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 2)
                            .offset(y: -8)
                        
                        // End
                        VStack(spacing: 4) {
                            Circle()
                                .stroke(Color("GoldAccent"), lineWidth: 2)
                                .frame(width: 10, height: 10)
                            Text(endMonth)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color("NavyPrimary").opacity(0.6))
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(18)
        }
    }
}

// MARK: - Styled Section Card (Glassmorphism version)
struct StyledSectionCard: View {
    let section: ParsedSection
    
    @State private var appeared = false
    
    var body: some View {
        GlassmorphismCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 10) {
                // Header if present
                if let header = section.header {
                    HStack(spacing: 8) {
                        Text(header.icon)
                            .font(.system(size: 13))
                        
                        Text(header.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(header.color)
                    }
                }
                
                // Content
                if let attrString = try? AttributedString(
                    markdown: section.content,
                    options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
                ) {
                    Text(attrString)
                        .font(.system(size: 15))
                        .foregroundColor(Color("NavyPrimary"))
                        .lineSpacing(4)
                        .textSelection(.enabled)
                } else {
                    Text(section.content)
                        .font(.system(size: 15))
                        .foregroundColor(Color("NavyPrimary"))
                        .lineSpacing(4)
                        .textSelection(.enabled)
                }
            }
            .padding(16)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

// MARK: - Premium Message View
/// Replaces StyledMarkdownView with glassmorphism cards for each section
struct PremiumMarkdownView: View {
    let content: String
    let textColor: Color
    
    private var sections: [ParsedSection] {
        MarkdownParser.parse(content)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                // Check if this is a VERDICT section - use special card
                if section.header == .verdict {
                    let (sentiment, probability) = parseVerdict(section.content)
                    VerdictCard(
                        verdictText: section.content,
                        probability: probability,
                        sentiment: sentiment
                    )
                }
                // Check if this is a TIMING section - use timeline card
                else if section.header == .timing {
                    TimingCard(
                        timingText: section.content,
                        startMonth: parseStartMonth(section.content),
                        endMonth: parseEndMonth(section.content)
                    )
                }
                // Regular styled section with glassmorphism
                else if section.header != nil {
                    StyledSectionCard(section: section)
                }
                // Plain text without header
                else {
                    if let attrString = try? AttributedString(
                        markdown: section.content,
                        options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
                    ) {
                        Text(attrString)
                            .font(.system(size: 15))
                            .foregroundColor(textColor)
                            .lineSpacing(4)
                            .textSelection(.enabled)
                    } else {
                        Text(section.content)
                            .font(.system(size: 15))
                            .foregroundColor(textColor)
                            .lineSpacing(4)
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func parseVerdict(_ content: String) -> (VerdictCard.VerdictSentiment, Double) {
        let lowercased = content.lowercased()
        
        // Determine sentiment
        let sentiment: VerdictCard.VerdictSentiment
        if lowercased.contains("positive") || lowercased.contains("favorable") || 
           lowercased.contains("likely") || lowercased.contains("good") {
            sentiment = .positive
        } else if lowercased.contains("negative") || lowercased.contains("unlikely") ||
                  lowercased.contains("challenging") || lowercased.contains("difficult") {
            sentiment = .negative
        } else {
            sentiment = .neutral
        }
        
        // Extract probability
        var probability = 0.65 // Default
        if lowercased.contains("high") {
            probability = 0.85
        } else if lowercased.contains("medium-high") {
            probability = 0.75
        } else if lowercased.contains("medium") {
            probability = 0.60
        } else if lowercased.contains("low") {
            probability = 0.35
        }
        
        return (sentiment, probability)
    }
    
    private func parseStartMonth(_ content: String) -> String {
        // Try to extract start month from text like "July 2025 to early 2026"
        let months = ["January", "February", "March", "April", "May", "June", 
                      "July", "August", "September", "October", "November", "December"]
        let shortMonths = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        
        for (index, month) in months.enumerated() {
            if content.contains(month) {
                return shortMonths[index]
            }
        }
        return ""
    }
    
    private func parseEndMonth(_ content: String) -> String {
        // Look for patterns like "to [month]" or "- [month]"
        let months = ["January", "February", "March", "April", "May", "June", 
                      "July", "August", "September", "October", "November", "December"]
        let shortMonths = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        
        // Simple heuristic: if we find "2026", return the year
        if content.contains("2026") {
            return "2026"
        }
        if content.contains("2025") {
            // Find last month mentioned
            var lastMonth = ""
            for (index, month) in months.enumerated() {
                if content.contains(month) {
                    lastMonth = shortMonths[index]
                }
            }
            return lastMonth
        }
        return ""
    }
}

// MARK: - Enhanced Typing Indicator
struct PremiumTypingIndicator: View {
    @State private var animating = [false, false, false]
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color("GoldAccent"))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating[index] ? 1.2 : 0.8)
                    .opacity(animating[index] ? 1 : 0.4)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            GlassmorphismCard {
                Color.clear
            }
        )
        .onAppear {
            for index in 0..<3 {
                withAnimation(
                    Animation.easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.15)
                ) {
                    animating[index] = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Verdict Card") {
    VStack(spacing: 20) {
        VerdictCard(
            verdictText: "Likely to experience positive developments in various life areas",
            probability: 0.75,
            sentiment: .positive
        )
        
        TimingCard(
            timingText: "The most favorable time window is from July 2025 to early 2026",
            startMonth: "Jul",
            endMonth: "2026"
        )
    }
    .padding()
    .background(Color(red: 0.95, green: 0.94, blue: 0.96))
}

#Preview("Glassmorphism Card") {
    GlassmorphismCard {
        VStack(alignment: .leading, spacing: 8) {
            Text("✨ INSIGHT")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color("GoldAccent"))
            Text("Your Saturn return begins next month, marking a significant period of growth.")
                .font(.system(size: 15))
                .foregroundColor(Color("NavyPrimary"))
        }
        .padding(20)
    }
    .padding()
    .background(MinimalOrbitalBackground())
}
