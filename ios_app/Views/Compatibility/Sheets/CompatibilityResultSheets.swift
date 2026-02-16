import SwiftUI

// MARK: - Full Report Sheet (Premium Branded Report)
struct FullReportSheet: View {
    let result: CompatibilityResult
    let boyName: String
    let girlName: String
    let boyDob: String?
    let girlDob: String?
    @Environment(\.dismiss) private var dismiss
    @State private var isGeneratingPDF = false
    @State private var showShareOptions = false
    
    // Parse summary into sections by ### headers
    private var sections: [(emoji: String, title: String, content: String)] {
        parseSections(from: result.summary)
    }
    
    private var ratingText: String {
        let pct = result.percentage * 100
        if pct >= 90 { return "Excellent" }
        else if pct >= 75 { return "Very Good" }
        else if pct >= 60 { return "Good" }
        else if pct >= 50 { return "Average" }
        else { return "Needs Attention" }
    }
    
    private var starCount: Int {
        let pct = result.percentage * 100
        if pct >= 90 { return 5 }
        else if pct >= 75 { return 4 }
        else if pct >= 60 { return 3 }
        else if pct >= 50 { return 2 }
        else { return 1 }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Colors.mainBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 1. Action Bar
                        actionBar
                        
                        // 2. Branded Header
                        brandedHeader
                        
                        // 3. Section Cards (parsed from LLM output)
                        if sections.isEmpty {
                            // Fallback: render full summary as markdown
                            sectionCard(emoji: "📋", title: "Analysis", content: result.summary)
                        } else {
                            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                                sectionCard(emoji: section.emoji, title: section.title, content: section.content)
                            }
                        }
                        
                        // 4. AI Disclaimer Footer
                        disclaimerFooter
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
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
        .confirmationDialog("Share Report", isPresented: $showShareOptions) {
            Button("Share as PDF") {
                generateAndSharePDF()
            }
            Button("Share Score Card") {
                shareScoreCard()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    // MARK: - Action Bar
    
    private var actionBar: some View {
        HStack(spacing: 12) {
            // Download PDF Button
            Button {
                generateAndSharePDF()
            } label: {
                HStack(spacing: 6) {
                    if isGeneratingPDF {
                        ProgressView()
                            .tint(AppTheme.Colors.gold)
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.down.doc.fill")
                    }
                    Text("Download PDF")
                        .font(AppTheme.Fonts.caption(size: 13).weight(.semibold))
                }
                .foregroundColor(AppTheme.Colors.mainBackground)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.gold, AppTheme.Colors.gold.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .disabled(isGeneratingPDF)
            
            // Share Button
            Button {
                showShareOptions = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                        .font(AppTheme.Fonts.caption(size: 13).weight(.semibold))
                }
                .foregroundColor(AppTheme.Colors.gold)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .stroke(AppTheme.Colors.gold.opacity(0.5), lineWidth: 1)
                )
            }
            
            Spacer()
        }
        .padding(.top, 8)
    }
    
    // MARK: - Branded Header
    
    private var brandedHeader: some View {
        VStack(spacing: 16) {
            // Logo
            Image("logo_gold")
                .resizable()
                .scaledToFit()
                .frame(height: 44)
            
            Text("DESTINY AI ASTROLOGY")
                .font(.system(size: 10, weight: .medium, design: .serif))
                .foregroundColor(AppTheme.Colors.gold.opacity(0.6))
                .tracking(4)
            
            // Gold divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.gold.opacity(0),
                            AppTheme.Colors.gold.opacity(0.5),
                            AppTheme.Colors.gold.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 40)
            
            // Names
            Text("\(boyName) & \(girlName)")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            // Date info
            if let bDob = boyDob, let gDob = girlDob {
                Text("Born: \(bDob) · \(gDob)")
                    .font(AppTheme.Fonts.caption(size: 11))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            // Score Ring
            ZStack {
                Circle()
                    .stroke(AppTheme.Colors.gold.opacity(0.15), lineWidth: 3)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: result.percentage)
                    .stroke(
                        LinearGradient(
                            colors: [AppTheme.Colors.gold, AppTheme.Colors.gold.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(result.totalScore)")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("/ \(result.maxScore)")
                        .font(AppTheme.Fonts.caption(size: 11))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .padding(.top, 4)
            
            // Star rating
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    Image(systemName: index < starCount ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.gold)
                }
            }
            
            Text(ratingText.uppercased())
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundColor(AppTheme.Colors.gold)
                .tracking(3)
            
            // Report date
            Text("Report generated: \(formattedDate)")
                .font(AppTheme.Fonts.caption(size: 10))
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.6))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppTheme.Colors.gold.opacity(0.3),
                                    AppTheme.Colors.gold.opacity(0.1),
                                    AppTheme.Colors.gold.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Section Card
    
    // SF Symbol mapping for section emojis
    private func sfSymbol(for emoji: String) -> String? {
        switch emoji {
        case "🎯": return "target"                    // COMPATIBILITY VERDICT
        case "🌟", "⭐": return "star.fill"          // KEY STRENGTHS
        case "ⓘ", "ℹ️": return "info.circle.fill"    // KEY CHALLENGES
        case "🔮": return "wand.and.stars"          // FINAL RECOMMENDATION
        case "📋": return "doc.text"                // Default/Analysis
        default: return nil
        }
    }
    
    private func sectionCard(emoji: String, title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                // Use SF Symbol if mapped, otherwise use emoji
                if let symbolName = sfSymbol(for: emoji) {
                    Image(systemName: symbolName)
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                } else {
                    Text(emoji)
                        .font(.system(size: 18))
                }
                
                Text(title.uppercased())
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundColor(AppTheme.Colors.gold)
                    .tracking(1.5)
                
                Spacer()
            }
            
            // Gold underline
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.Colors.gold.opacity(0.4), AppTheme.Colors.gold.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
            
            // Markdown content — replace generic "Boy"/"Girl" with actual names
            MarkdownTextView(
                content: replaceGenericLabels(in: content),
                textColor: AppTheme.Colors.textPrimary,
                fontSize: 14
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.Colors.cardBackground.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.Colors.gold.opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    // MARK: - AI Disclaimer Footer
    
    private var disclaimerFooter: some View {
        VStack(spacing: 12) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.gold.opacity(0),
                            AppTheme.Colors.gold.opacity(0.3),
                            AppTheme.Colors.gold.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
            
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.Colors.gold.opacity(0.6))
                Text("AI-Generated Analysis")
                    .font(AppTheme.Fonts.caption(size: 11).weight(.semibold))
                    .foregroundColor(AppTheme.Colors.gold.opacity(0.6))
            }
            
            Text("This report is generated using AI based on vedic astrology principles. Results are for informational and entertainment purposes only. Consider multiple factors when making important relationship or marriage decisions.")
                .font(AppTheme.Fonts.caption(size: 10))
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
                .lineSpacing(3)
                .multilineTextAlignment(.center)
            
            Text("© 2026 Destiny AI Astrology · destinyaiastrology.com")
                .font(AppTheme.Fonts.caption(size: 9))
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.4))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
    }
    
    // MARK: - Section Parser
    
    /// Parse LLM summary into sections by ### emoji TITLE headers
    private func parseSections(from summary: String) -> [(emoji: String, title: String, content: String)] {
        guard !summary.isEmpty else { return [] }
        
        var result: [(emoji: String, title: String, content: String)] = []
        let lines = summary.components(separatedBy: "\n")
        
        var currentEmoji = ""
        var currentTitle = ""
        var currentContent: [String] = []
        var inSection = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Check if this is a section header (### emoji TITLE)
            if trimmed.hasPrefix("### ") {
                // Save previous section
                if inSection && !currentTitle.isEmpty {
                    let content = currentContent.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                    if !content.isEmpty {
                        result.append((emoji: currentEmoji, title: currentTitle, content: content))
                    }
                }
                
                // Parse new section header
                let headerText = String(trimmed.dropFirst(4))
                let parsed = extractEmojiAndTitle(from: headerText)
                currentEmoji = parsed.emoji
                currentTitle = parsed.title
                currentContent = []
                inSection = true
            } else if trimmed == "---" {
                // Skip dividers (they mark section boundaries)
                continue
            } else if inSection {
                currentContent.append(line)
            }
        }
        
        // Save last section
        if inSection && !currentTitle.isEmpty {
            let content = currentContent.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty {
                result.append((emoji: currentEmoji, title: currentTitle, content: content))
            }
        }
        
        return result
    }
    
    /// Extract emoji and title from header like "🎯 COMPATIBILITY VERDICT"
    private func extractEmojiAndTitle(from text: String) -> (emoji: String, title: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        
        // Handle special case for circled characters (ⓘ, ⓒ, etc.) that don't have isEmoji property
        if let first = trimmed.unicodeScalars.first {
            let firstScalar = first.value
            // Check for circled letters (ⓘ = U+24D8, etc.)
            if (firstScalar >= 0x24B6 && firstScalar <= 0x24E9) || // Circled Latin
               (firstScalar >= 0x24EA && firstScalar <= 0x24FF) || // Circled numbers
               (first.properties.isEmoji && firstScalar > 0x238) {
                var emojiEnd = trimmed.index(trimmed.startIndex, offsetBy: 1)
                // Walk forward while still in emoji territory (for multi-scalar emojis)
                while emojiEnd < trimmed.endIndex {
                    let scalarIndex = trimmed.unicodeScalars.index(trimmed.unicodeScalars.startIndex, offsetBy: trimmed.distance(from: trimmed.startIndex, to: emojiEnd))
                    let scalar = trimmed.unicodeScalars[scalarIndex]
                    if scalar.properties.isEmoji || scalar.value == 0xFE0F || scalar.value == 0x200D {
                        emojiEnd = trimmed.index(after: emojiEnd)
                    } else {
                        break
                    }
                }
                let emoji = String(trimmed[trimmed.startIndex..<emojiEnd])
                let title = String(trimmed[emojiEnd...]).trimmingCharacters(in: .whitespaces)
                return (emoji: emoji, title: title)
            }
        }
        
        return (emoji: "📋", title: trimmed)
    }
    
    // MARK: - Date Formatting
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }
    
    // MARK: - Name Substitution
    
    /// Replace generic "Boy"/"Girl" labels from LLM output with actual partner names
    private func replaceGenericLabels(in text: String) -> String {
        var result = text
        
        // Replace common patterns where LLM uses "Boy" and "Girl"
        // Order matters: longer patterns first to avoid partial replacement
        let boyPatterns: [(String, String)] = [
            ("**Boy's ", "**\(boyName)'s "),
            ("**Boy (", "**\(boyName) ("),
            ("**Boy:**", "**\(boyName):**"),
            ("**Boy:", "**\(boyName):"),
            ("Boy's Key", "\(boyName)'s Key"),
            ("Boy's Yogas", "\(boyName)'s Yogas"),
            ("Boy's Dasha", "\(boyName)'s Dasha"),
            ("Boy (Lagna", "\(boyName) (Lagna"),
            ("Boy:", "\(boyName):"),
            ("Boy's ", "\(boyName)'s "),
        ]
        
        let girlPatterns: [(String, String)] = [
            ("**Girl's ", "**\(girlName)'s "),
            ("**Girl (", "**\(girlName) ("),
            ("**Girl:**", "**\(girlName):**"),
            ("**Girl:", "**\(girlName):"),
            ("Girl's Key", "\(girlName)'s Key"),
            ("Girl's Yogas", "\(girlName)'s Yogas"),
            ("Girl's Dasha", "\(girlName)'s Dasha"),
            ("Girl (Lagna", "\(girlName) (Lagna"),
            ("Girl:", "\(girlName):"),
            ("Girl's ", "\(girlName)'s "),
        ]
        
        for (pattern, replacement) in boyPatterns {
            result = result.replacingOccurrences(of: pattern, with: replacement)
        }
        for (pattern, replacement) in girlPatterns {
            result = result.replacingOccurrences(of: pattern, with: replacement)
        }
        
        return result
    }
    
    // MARK: - PDF & Share Actions
    
    private func generateAndSharePDF() {
        isGeneratingPDF = true
        
        Task { @MainActor in
            // Create a report view for PDF rendering
            let pdfView = PremiumReportPDFView(
                result: result,
                boyName: boyName,
                girlName: girlName,
                boyDob: boyDob,
                girlDob: girlDob,
                sections: sections,
                ratingText: ratingText,
                starCount: starCount,
                formattedDate: formattedDate
            )
            
            let fileName = "Destiny_AI_\(boyName)_\(girlName)_Compatibility"
            
            if let pdfURL = ReportShareService.shared.generateMultiPagePDF(
                from: pdfView,
                width: 390,
                fileName: fileName
            ) {
                ReportShareService.shared.sharePDF(url: pdfURL)
            }
            
            isGeneratingPDF = false
        }
    }
    
    private func shareScoreCard() {
        Task { @MainActor in
            let cardView = ShareCardView(
                boyName: boyName,
                girlName: girlName,
                totalScore: result.totalScore,
                maxScore: result.maxScore,
                percentage: result.percentage
            )
            
            if let image = ReportShareService.shared.generateShareImage(from: cardView) {
                let shareText = "✨ \(boyName) & \(girlName) — Compatibility score: \(result.totalScore)/\(result.maxScore) (\(Int(result.percentage * 100))%) \(ratingText)\n\nAnalyzed with Destiny AI Astrology\n🔗 destinyaiastrology.com"
                ReportShareService.shared.shareImage(image, text: shareText)
            }
        }
    }
}

// MARK: - PDF Render View (Static version for ImageRenderer)
/// A non-interactive version of the report optimized for PDF generation
private struct PremiumReportPDFView: View {
    let result: CompatibilityResult
    let boyName: String
    let girlName: String
    let boyDob: String?
    let girlDob: String?
    let sections: [(emoji: String, title: String, content: String)]
    let ratingText: String
    let starCount: Int
    let formattedDate: String
    
    // SF Symbol mapping for section emojis (duplicated here since this is a separate struct)
    private func sfSymbol(for emoji: String) -> String? {
        switch emoji {
        case "🎯": return "target"                    // COMPATIBILITY VERDICT
        case "🌟", "⭐": return "star.fill"          // KEY STRENGTHS
        case "ⓘ", "ℹ️": return "info.circle.fill"    // KEY CHALLENGES
        case "🔮": return "wand.and.stars"          // FINAL RECOMMENDATION
        case "📋": return "doc.text"                // Default/Analysis
        default: return nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(spacing: 12) {
                Text("DESTINY AI ASTROLOGY")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                    .tracking(4)
                
                Text("COMPATIBILITY REPORT")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.6))
                    .tracking(3)
                
                Text("\(boyName) & \(girlName)")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                
                if let bDob = boyDob, let gDob = girlDob {
                    Text("Born: \(bDob) · \(gDob)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Text("\(result.totalScore)/\(result.maxScore) • \(Int(result.percentage * 100))% • \(ratingText)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                
                HStack(spacing: 3) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < starCount ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                    }
                }
                
                Rectangle()
                    .fill(Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            
            // Sections
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        // Use SF Symbol for emoji in PDF
                        if let symbolName = sfSymbol(for: section.emoji) {
                            Image(systemName: symbolName)
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                        } else {
                            Text(section.emoji)
                                .font(.system(size: 14))
                        }
                        
                        Text(section.title)
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                    }
                    
                    Rectangle()
                        .fill(Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.2))
                        .frame(height: 1)
                    
                    MarkdownTextView(
                        content: section.content,
                        textColor: .white.opacity(0.9),
                        fontSize: 12
                    )
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.15), lineWidth: 0.5)
                        )
                )
            }
            
            // Disclaimer
            VStack(spacing: 8) {
                Rectangle()
                    .fill(Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, 40)
                
                Text("ⓘ AI-Generated Analysis")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.5))
                
                Text("This report is generated using AI based on vedic astrology principles. Results are for informational and entertainment purposes only. Consider multiple factors when making important relationship or marriage decisions.")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                
                Text("© 2026 Destiny AI Astrology · destinyaiastrology.com")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.25))
                
                Text("Generated: \(formattedDate)")
                    .font(.system(size: 7))
                    .foregroundColor(.white.opacity(0.2))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .padding(20)
        .background(Color(red: 0.04, green: 0.06, blue: 0.10)) // #0B0F19
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
            .presentationDetents([.large])
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
            .accessibilityLabel("Send question")
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
        .accessibilityHidden(true)
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
