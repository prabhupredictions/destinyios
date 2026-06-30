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
    @State private var showAskDestiny = false
    
    // Parse summary into sections by ### headers
    private var sections: [(emoji: String, title: String, content: String)] {
        parseSections(from: result.summary)
    }
    
    private var ratingText: String {
        if !result.isRecommended { return "not_recommended".localized }
        let pct = result.adjustedPercentage * 100
        if pct >= 90 { return "excellent".localized }
        else if pct >= 75 { return "very_good".localized }
        else if pct >= 60 { return "good".localized }
        else if pct >= 50 { return "average".localized }
        else { return "not_recommended".localized }
    }

    private var starCount: Int {
        if !result.isRecommended { return 1 }
        let pct = result.adjustedPercentage * 100
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
                        // 1. Branded Header (Score Card)
                        brandedHeader
                        
                        // 2. Save to Files row
                        actionBar
                        
                        // 3. Section Cards (parsed from LLM output)
                        if sections.isEmpty {
                            // Fallback: render full summary as markdown (strip follow-up section)
                            sectionCard(emoji: "📋", title: "Analysis", content: ComparisonOverviewView.stripFollowUpSection(result.summary))
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
                
                // Floating AMA Chat Button
                FloatingContextButton(
                    icon: "bubble.left.and.bubble.right.fill",
                    action: { showAskDestiny = true }
                )
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        presentNativeShareSheet()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                }
            }
        }
        .sheet(isPresented: $showAskDestiny) {
            AskDestinySheet(result: result, boyName: boyName, girlName: girlName, showFollowUpSuggestions: false)
        }
    }
    
    // MARK: - Native Share Sheet
    
    private func presentNativeShareSheet() {
        Task { @MainActor in
            // Generate professional vector PDF
            let renderer = CompatibilityPDFRenderer(
                result: result,
                boyName: boyName,
                girlName: girlName,
                boyDob: boyDob,
                girlDob: girlDob,
                sections: sections
            )
            let pdfURL = renderer.generateReport()
            
            // Generate Score Card Image (for social media)
            let cardView = ShareCardView(
                boyName: boyName,
                girlName: girlName,
                totalScore: result.totalScore,
                maxScore: result.maxScore,
                percentage: result.percentage,
                isRecommended: result.isRecommended,
                adjustedScore: result.adjustedScore
            )
            let shareImage = ReportShareService.shared.generateShareImage(from: cardView)
            
            // Prepare share items
            var shareItems: [Any] = []
            
            // Add share text
            let shareText = "✨ \(boyName) & \(girlName) — Compatibility score: \(result.totalScore)/\(result.maxScore) (\(Int(result.percentage * 100))%) \(ratingText)\n\nAnalyzed with Destiny AI Astrology\n🔗 destinyaiastrology.com"
            shareItems.append(shareText)
            
            // Add image if available
            if let image = shareImage {
                shareItems.append(image)
            }
            
            // Add PDF if available
            if let url = pdfURL {
                shareItems.append(url)
            }
            
            // Present native share sheet
            ReportShareService.shared.presentShareSheet(items: shareItems)
        }
    }
    
    // MARK: - Action Bar (Save to Files row style)
    
    private var actionBar: some View {
        Button {
            generateAndSaveToFiles()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("save_to_files".localized)
                    .font(AppTheme.Fonts.body(size: 16))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.Colors.gold.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .disabled(isGeneratingPDF)
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
            
            Text("destiny_ai_astrology_brand".localized)
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
            Text(String(format: "born_date_format".localized, bDob, gDob))
                    .font(AppTheme.Fonts.caption(size: 11))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            // Score Ring — show adjusted score for transparency
            ZStack {
                Circle()
                    .stroke(AppTheme.Colors.gold.opacity(0.15), lineWidth: 3)
                    .frame(width: 100, height: 100)
                
                let displayPct: Double = {
                    if let adj = result.adjustedScore, adj != result.totalScore {
                        return Double(adj) / Double(result.maxScore)
                    }
                    return result.percentage
                }()
                
                Circle()
                    .trim(from: 0, to: displayPct)
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
                    Text("\(result.adjustedScore ?? result.totalScore)")
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
            
            // Transparency: show original vs adjusted score for all cases
            if let adjScore = result.adjustedScore, adjScore != result.totalScore {
                Text(String(format: "ashtakoot_adjusted_score_format".localized, result.totalScore, result.maxScore, adjScore, result.maxScore))
                    .font(AppTheme.Fonts.caption(size: 10))
                    .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.7))
                    .padding(.top, 2)
            } else {
                Text(String(format: "ashtakoot_score_format".localized, result.totalScore, result.maxScore))
                    .font(AppTheme.Fonts.caption(size: 10))
                    .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.7))
                    .padding(.top, 2)
            }
            
            // Rejection reasons for Not Recommended
            if !result.isRecommended {
                VStack(spacing: 6) {
                    Text("overridden_due_to_issues".localized)
                        .font(AppTheme.Fonts.caption(size: 10))
                        .foregroundColor(AppTheme.Colors.error.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    // Rejection reasons
                    ForEach(result.rejectionReasons, id: \.self) { reason in
                        let displayReason = reason
                            .replacingOccurrences(of: "Boy:", with: "\(boyName):")
                            .replacingOccurrences(of: "Girl:", with: "\(girlName):")
                            .replacingOccurrences(of: "Boy ", with: "\(boyName) ")
                            .replacingOccurrences(of: "Girl ", with: "\(girlName) ")
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 9))
                                .foregroundColor(AppTheme.Colors.error.opacity(0.7))
                                .padding(.top, 1)
                            Text(displayReason)
                                .font(AppTheme.Fonts.caption(size: 10))
                                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
            }
            
            // Report date
            Text(String(format: "report_generated_format".localized, formattedDate))
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
                Text("ai_generated_analysis".localized)
                    .font(AppTheme.Fonts.caption(size: 11).weight(.semibold))
                    .foregroundColor(AppTheme.Colors.gold.opacity(0.6))
            }
            
            Text("ai_disclaimer_text".localized)
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
        
        // Strip follow-up questions section — only relevant in Ask Destiny chat, not in reports or share
        return result.filter { section in
            !section.title.localizedCaseInsensitiveContains("SUGGESTED FOLLOW-UP")
        }
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
    
    private func generateAndSaveToFiles() {
        isGeneratingPDF = true
        
        Task { @MainActor in
            let renderer = CompatibilityPDFRenderer(
                result: result,
                boyName: boyName,
                girlName: girlName,
                boyDob: boyDob,
                girlDob: girlDob,
                sections: sections
            )
            
            if let pdfURL = renderer.generateReport() {
                ReportShareService.shared.presentSaveToFiles(fileURL: pdfURL)
            }
            
            isGeneratingPDF = false
        }
    }
    
    // MARK: - PDF Section Builder
    
    private func buildPDFSections() -> [AnyView] {
        let gold = Color(red: 0.83, green: 0.69, blue: 0.22)
        var pdfSections: [AnyView] = []
        
        // 1. Header
        let header = VStack(spacing: 12) {
            Text("destiny_ai_astrology_title".localized)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(gold)
                .tracking(4)
            
            Text("compatibility_report_title".localized)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(gold.opacity(0.6))
                .tracking(3)
            
            Text("\(boyName) & \(girlName)")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(.white)
            
            if let bDob = boyDob, let gDob = girlDob {
                Text(String(format: "born_date_format".localized, bDob, gDob))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Text("\(result.totalScore)/\(result.maxScore) • \(Int(result.percentage * 100))% • \(ratingText)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(gold)
            
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: index < starCount ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundColor(gold)
                }
            }
            
            Rectangle()
                .fill(gold.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        
        pdfSections.append(AnyView(header))
        
        // 2. Each LLM section card
        for section in sections {
            let card = VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    if let symbolName = sfSymbol(for: section.emoji) {
                        Image(systemName: symbolName)
                            .font(.system(size: 12))
                            .foregroundColor(gold)
                    } else {
                        Text(section.emoji)
                            .font(.system(size: 14))
                    }
                    
                    Text(section.title)
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundColor(gold)
                }
                
                Rectangle()
                    .fill(gold.opacity(0.2))
                    .frame(height: 1)
                
                MarkdownTextView(
                    content: replaceGenericLabels(in: section.content),
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
                            .stroke(gold.opacity(0.15), lineWidth: 0.5)
                    )
            )
            
            pdfSections.append(AnyView(card))
        }
        
        // 3. Disclaimer
        let disclaimer = VStack(spacing: 8) {
            Rectangle()
                .fill(gold.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 40)
            
            Text("ai_generated_analysis_info".localized)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(gold.opacity(0.5))
            
            Text("ai_disclaimer_text".localized)
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
            
            Text("© 2026 Destiny AI Astrology · destinyaiastrology.com")
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.25))
            
            Text(String(format: "report_generated_label_format".localized, formattedDate))
                .font(.system(size: 7))
                .foregroundColor(.white.opacity(0.2))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)

        pdfSections.append(AnyView(disclaimer))
        
        return pdfSections
    }
    
    private func shareScoreCard() {
        Task { @MainActor in
            let cardView = ShareCardView(
                boyName: boyName,
                girlName: girlName,
                totalScore: result.totalScore,
                maxScore: result.maxScore,
                percentage: result.percentage,
                isRecommended: result.isRecommended,
                adjustedScore: result.adjustedScore
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
                Text("destiny_ai_astrology_title".localized)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                    .tracking(4)
                
                Text("compatibility_report_title".localized)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.6))
                    .tracking(3)
                
                Text("\(boyName) & \(girlName)")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                
                if let bDob = boyDob, let gDob = girlDob {
                    Text(String(format: "born_date_format".localized, bDob, gDob))
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
                
                Text("ai_generated_analysis_info".localized)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.5))
                
                Text("ai_disclaimer_text".localized)
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                
                Text("© 2026 Destiny AI Astrology · destinyaiastrology.com")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.25))
                
                Text(String(format: "report_generated_label_format".localized, formattedDate))
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
    var initialPrompt: String? = nil  // V2.5 — pre-fill from "See classical analysis →"
    var showFollowUpSuggestions: Bool = true  // false when opened from FullReportSheet
    var initialQuestions: [String] = []  // AI-generated from /analyze; falls back to hardcoded
    @Environment(\.dismiss) private var dismiss
    
    // Chat State
    @State private var messages: [CompatChatMessage] = []
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showQuotaSheet: Bool = false
    @State private var quotaMessage: String = ""
    /// Rich quota-blockage state to drive QuotaExhaustedView's plan-aware
    /// branching (Plus fair-use → Contact Support; otherwise upgrade CTA).
    /// Populated alongside quotaMessage when a 403 fires from /follow-up.
    @State private var quotaError: QuotaErrorInfo? = nil
    @State private var showSubscription: Bool = false
    @State private var suggestedQuestions: [String] = []  // Follow-up suggestions from API
    @State private var compatScrollTrigger = UUID()  // Debounced bottom-scroll trigger
    // Pin-to-top state — see ChatView.swift for the full design rationale.
    // When the user taps Send, we anchor THEIR message to the top of the
    // viewport so the answer that lands below reads top-down, instead of
    // dumping the user at the bottom of a long markdown response.
    @State private var compatPinToTopTrigger = UUID()
    @State private var compatPinToTopMessageId: UUID?
    @State private var newMessageIds: Set<UUID> = []  // IDs of newly arrived messages (fade-in targets)
    @State private var pendingScrollWorkItem: DispatchWorkItem?  // Coalesced scroll debounce
    @State private var showStyleSelector = false
    @State private var lengthManager = ResponseLengthManager.shared
    // Agentic path: cosmic progress while awaiting followup response
    @State private var cosmicProgressSteps: [CosmicProgressStep] = []
    @State private var cosmicTimerTask: Task<Void, Never>? = nil
    // Sub-agent streaming tracking (redirect → individual chart)
    @State private var redirectStreamingMessageId: UUID? = nil
    @State private var redirectCosmicProgressSteps: [CosmicProgressStep] = []
    @State private var redirectProgressTimerTask: Task<Void, Never>? = nil

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
                        Text("ask_destiny_title".localized)
                            .font(AppTheme.Fonts.title(size: 17))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Spacer()
                        Button("done_action".localized) { dismiss() }
                            .font(AppTheme.Fonts.title(size: 17))
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    // Messages List
                    ScrollViewReader { proxy in
                        ScrollView {
                            if messages.isEmpty && !isLoading {
                                welcomeView
                            } else {
                                // LazyVStack (was VStack) — prevents main-thread
                                // watchdog kills on Ask Destiny follow-up threads
                                // with long persisted messages. Same fix as
                                // ChatView.swift:390. See 2026-06-24 audit.
                                LazyVStack(spacing: 24) {
                                    ForEach(messages, id: \.id) { message in
                                        CompatChatBubble(
                                            message: message,
                                            cosmicProgressSteps: message.id == redirectStreamingMessageId
                                                ? redirectCosmicProgressSteps : []
                                        )
                                        .id(message.id)
                                    }

                                    // Agentic path: cosmic progress while awaiting followup
                                    if isLoading && !cosmicProgressSteps.isEmpty {
                                        CosmicProgressView(steps: cosmicProgressSteps)
                                            .id("loading")
                                            .padding(.horizontal, 4)
                                    }

                                    // Follow-up suggestions (vertical rows matching ChatView)
                                    if showFollowUpSuggestions && !suggestedQuestions.isEmpty && !isLoading {
                                        FollowUpSuggestionsView(questions: suggestedQuestions) { question in
                                            HapticManager.shared.play(.light)
                                            isInputFocused = false
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                            // Batch state mutations into one transaction so
                                            // SwiftUI does a single layout pass — pre-fix this
                                            // produced a jarring viewport stutter when tapping
                                            // a follow-up from a deep scroll position.
                                            withTransaction(Transaction(animation: nil)) {
                                                suggestedQuestions = []
                                                inputText = question
                                            }
                                            Task { await sendMessage() }
                                        }
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
                        // Reserve top scroll content space so pin-to-top
                        // doesn't slide the user's question behind the
                        // sibling header. iOS 17+.
                        .contentMargins(.top, 8, for: .scrollContent)
                        .scrollDismissesKeyboard(.interactively)
                        // Bottom-scroll handler (loading reveal + suggestions + keyboard).
                        .onChange(of: compatScrollTrigger) { _, _ in
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo("bottomAnchor", anchor: .bottom)
                            }
                        }
                        // Pin-to-top handler: scroll the just-appended user
                        // message to the TOP of the visible area. Same design
                        // as ChatView.
                        .onChange(of: compatPinToTopTrigger) { _, _ in
                            guard let id = compatPinToTopMessageId else { return }
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(id, anchor: .top)
                            }
                        }
                        // Messages.count change: pin-to-top when a user message
                        // was just appended. Assistant-only appends (e.g. the
                        // redirect ".info" / ".ai" bubbles produced during the
                        // sub-agent path) intentionally do NOT scroll — they
                        // arrive while the typewriter is running and the user
                        // is already reading from the pinned position.
                        .onChange(of: messages.count) { oldCount, newCount in
                            guard newCount > oldCount else { return }
                            let appendedSuffix = messages.suffix(newCount - oldCount)
                            if let userMsg = appendedSuffix.first(where: { $0.isUser }) {
                                compatPinToTopMessageId = userMsg.id
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    compatPinToTopTrigger = UUID()
                                }
                            }
                        }
                        // Cosmic progress card reveal — only on loading→true.
                        .onChange(of: isLoading) { oldVal, newVal in
                            if newVal { requestCompatScroll() }
                            // Loading flips false ↔ response arrived. If a
                            // pin target is still active (user hasn't moved
                            // on), re-trigger pin-to-top so the user lands
                            // at the start of the freshly-rendered answer
                            // instead of mid-bubble where layout shifts
                            // left them.
                            if oldVal == true && newVal == false, compatPinToTopMessageId != nil {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    compatPinToTopTrigger = UUID()
                                }
                            }
                        }
                        // Follow-up suggestions appear below the answer.
                        .onChange(of: suggestedQuestions) { _, q in
                            if !q.isEmpty { requestCompatScroll() }
                        }
                        // Keyboard-up reveal.
                        .onChange(of: isInputFocused) { _, focused in
                            if focused { requestCompatScroll(delay: 0.3) }
                        }
                        // REMOVED (intentionally) — see ChatView.swift for full rationale:
                        //   .onChange(of: newMessageIds) { _, ids in
                        //       if ids.isEmpty { requestCompatScroll(delay: 0.3) }
                        //   }
                        //     ↑ Fired the moment the typewriter finished — and
                        //       parked the user at the bottom of a long answer
                        //       they wanted to read from the top. The pin-to-top
                        //       on user-send already provided the correct
                        //       starting position; once typewriter completes
                        //       we leave them wherever they scrolled to during
                        //       the reveal.
                        //
                        //   .onChange(of: cosmicProgressSteps.count) { _, _ in
                        //       requestCompatScroll()
                        //   }
                        //     ↑ Jittery — see ChatView.swift comment.
                    }
                    
                    // Error Banner
                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(AppTheme.Fonts.body(size: 14))
                            Text(error)
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
                        .onTapGesture { errorMessage = nil }
                    }
                    
                    // Input Bar
                    inputBar
                }
            }
            .accessibilityIdentifier("ask_destiny_sheet")
            .navigationBarHidden(true)  // Use custom header
        }
        .onAppear {
            loadStoredMessages()
            // V2.5 — auto-send classical analysis prompt regardless of existing chat history
            if let prompt = initialPrompt, !prompt.isEmpty {
                inputText = prompt
                Task { await sendMessage() }
            }
        }
        .sheet(isPresented: $showQuotaSheet) {
            QuotaExhaustedView(
                context: .compatibility,
                quotaError: quotaError,
                isGuest: isGuest,
                customMessage: quotaMessage,
                onSignIn: { signOutAndReauth() },
                onUpgrade: { isTrialCTA in
                    // Mirror ChatView's onUpgrade routing (parity gap fix):
                    //   - guest → re-auth
                    //   - trial-eligible (CTA reads "Start my free week") →
                    //     direct StoreKit purchase via purchasePlusDirect()
                    //   - otherwise → plan picker
                    // Without `isTrialCTA` branching, every tap routed to
                    // SubscriptionView even when the gold "Start my free
                    // week" button promised a direct purchase.
                    if isGuest {
                        signOutAndReauth()
                    } else if isTrialCTA {
                        Task {
                            _ = await SubscriptionManager.shared.purchasePlusDirect()
                        }
                    } else {
                        showQuotaSheet = false
                        showSubscription = true
                    }
                },
                onSeeCore: {
                    // Parity with ChatView: trial-eligible users tapping
                    // "Prefer a lighter plan? See Core" should land on the
                    // SubscriptionView plan picker.
                    showQuotaSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
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
        // Filter out only the initial compatibility report (identified by table markers or header keywords)
        if !item.chatMessages.isEmpty {
            let filteredMessages = item.chatMessages.filter { msg in
                let isReportMessage = msg.content.contains("---|") ||
                                     msg.content.contains("|---") ||
                                     msg.content.contains("KEY STRENGTHS")
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
    
    /// Debounced scroll request for compat chat — coalesces rapid calls
    private func requestCompatScroll(delay: Double = 0.1) {
        pendingScrollWorkItem?.cancel()
        let workItem = DispatchWorkItem { [self] in
            self.compatScrollTrigger = UUID()
        }
        pendingScrollWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
    
    // MARK: - Welcome View
    private var welcomeView: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.Colors.gold.opacity(0.1))
                    .frame(width: 72, height: 72)
                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundColor(AppTheme.Colors.gold)
            }

            Text(String(format: "ask_about_match_title".localized, boyName, girlName))
                .font(AppTheme.Fonts.title(size: 18))
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text("ask_destiny_welcome".localized)
                .font(AppTheme.Fonts.body(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Quick Questions — AI-generated from /analyze if available, else hardcoded fallbacks
            VStack(spacing: 8) {
                let questions = initialQuestions.isEmpty
                    ? ["suggested_q_strengths".localized, "suggested_q_challenges".localized, "suggested_q_timing".localized]
                    : initialQuestions
                ForEach(questions, id: \.self) { q in
                    quickQuestionButton(q)
                }
            }
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private func quickQuestionButton(_ text: String) -> some View {
        Button {
            isInputFocused = false
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
        HStack(alignment: .bottom, spacing: 0) {
            // Style selector icon (left, inside pill — same as ChatInputBar)
            if !isLoading {
                Button { showStyleSelector = true } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.Colors.gold)
                        .frame(width: 40, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(lengthManager.currentLength.label)
            }

            // Text field
            TextField("ask_question_placeholder".localized, text: $inputText, axis: .vertical)
                .font(AppTheme.Fonts.body(size: 16))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(1...5)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity)
                .focused($isInputFocused)
                .onSubmit {
                    Task { await sendMessage() }
                }
                .accessibilityIdentifier("compat_chat_input")

            // Send button (right, inside pill)
            Button {
                Task { await sendMessage() }
            } label: {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.gold))
                            .scaleEffect(0.75)
                            .frame(width: 40, height: 36)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(canSend ? AppTheme.Colors.gold : AppTheme.Colors.textSecondary.opacity(0.4))
                            .frame(width: 40, height: 36)
                    }
                }
            }
            .disabled(!canSend)
            .accessibilityLabel("a11y_send_question".localized)
            .accessibilityIdentifier("compat_send_button")
            .animation(.spring(response: 0.3), value: canSend)
        }
        .padding(.leading, 4)
        .padding(.trailing, 4)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.Colors.inputBackground)
                .shadow(color: isInputFocused ? AppTheme.Colors.gold.opacity(0.12) : .clear, radius: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isInputFocused ? AppTheme.Colors.gold : AppTheme.Colors.gold.opacity(0.25),
                                lineWidth: isInputFocused ? 1.5 : 1)
                )
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .padding(.bottom, 4)
        .background(AppTheme.Colors.mainBackground)
        .sheet(isPresented: $showStyleSelector) {
            ResponseLengthSheet()
                .onDisappear { lengthManager = ResponseLengthManager.shared }
        }
    }
    
    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
    
    // MARK: - Send Message
    private func sendMessage() async {
        let query = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        isInputFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        inputText = ""
        errorMessage = nil
        suggestedQuestions = []  // Clear previous suggestions

        // Check quota BEFORE appending the user bubble. If we appended first,
        // an exhausted user briefly saw their question accepted before the
        // paywall popped — same bug pattern fixed in ChatViewModel.
        let email = UserDefaults.standard.string(forKey: "userEmail") ?? "guest"

        do {
            let access = try await QuotaManager.shared.canAccessFeature(.aiQuestions, email: email)
            if !access.canAccess {
                if access.reason == "daily_limit_reached" {
                    errorMessage = "Daily limit reached. Resets tomorrow."
                } else {
                    showQuotaSheet = true
                }
                return  // No user bubble was ever appended — nothing to roll back
            }
        } catch {
            print("Quota check failed: \(error)")
            // Fail-open: continue to append + send. Server-side enforcement
            // still gates the followUp endpoint.
        }

        // Quota passed — NOW it's safe to append the user bubble.
        let userMessage = CompatChatMessage(content: query, isUser: true, type: .user)
        messages.append(userMessage)
        
        isLoading = true
        // Defer cosmic timer by 600ms. If the followUp REST call returns
        // a quota rejection in <600ms, no "Mapping the sky..." flash is shown
        // before the paywall. If the call takes longer (real work), the
        // cosmic UI kicks in and the user gets feedback.
        let cosmicStartTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 600_000_000)
            if !Task.isCancelled, isLoading {
                startCosmicTimer()
            }
        }
        defer {
            cosmicStartTask.cancel()
            isLoading = false
            stopCosmicTimer()
        }
        
        // Get session ID
        guard let sessionId = result.sessionId else {
            isLoading = false
            errorMessage = "Session not found. Please run analysis again."
            return
        }
        
        do {
            // Call follow-up API
            let appLanguage = UserDefaults.standard.string(forKey: "appLanguageCode") ?? "en"
            let request = CompatibilityFollowUpRequest(
                query: query,
                sessionId: sessionId,
                userEmail: email,
                language: appLanguage,
                responseStyle: ContentStyleManager.shared.currentStyle.rawValue,
                responseLength: ResponseLengthManager.shared.currentLength.rawValue
            )
            
            let response = try await compatibilityService.followUp(request: request)
            
            // Handle response
            let redirectTarget = response.target  // May be nil if backend returned null
            if response.status == "redirect" || response.status == "redirect_no_data" {
                // Stop agentic timer — redirect streaming will manage its own cosmic steps
                stopCosmicTimer()
                let resolvedTarget = redirectTarget ?? boyName
                print("[AskDestiny] redirect status=\(response.status ?? "") target=\(resolvedTarget)")
                await handleRedirect(query: query, target: resolvedTarget, response: response)
            } else if let answer = response.answer {
                // Normal compatibility answer
                var aiMessage = CompatChatMessage(content: answer, isUser: false, type: .ai)
                aiMessage.executionTimeMs = response.executionTimeMs ?? 0
                newMessageIds.insert(aiMessage.id)
                messages.append(aiMessage)
                saveMessagesToHistory()  // Persist messages

                // Set follow-up suggestions — prefer JSON field, fall back to embedded block
                if showFollowUpSuggestions {
                    let followUps = response.followUpSuggestions ?? []
                    suggestedQuestions = followUps.isEmpty ? extractFollowUpQuestions(from: answer) : followUps
                }
            } else if let message = response.message {
                // Info/error message — detect redirect patterns (including "None's chart" from backend bug)
                let isRedirectMsg = message.contains("Redirecting") || message.contains("individual analysis") ||
                                    message.contains("None's chart") || message.contains("birth details")
                if isRedirectMsg && result.analysisData?.boy?.details != nil {
                    // Fallback: backend sent redirect as message instead of status — use local data
                    print("[AskDestiny] Redirect fallback from message pattern, using boyName")
                    await handleRedirectWithLocalData(query: query, target: boyName, response: response)
                } else {
                    let aiMessage = CompatChatMessage(content: message, isUser: false, type: .info)
                    messages.append(aiMessage)
                }
            }
            
        } catch let quota as QuotaExhaustedError {
            // Server-side quota rejection from /vedic/api/compatibility/follow-up.
            // The pre-call /can-access gate may have said canAccess=true (race
            // window between two ai_questions on borderline quota, or the gate
            // throwing DecodingError and failing open). Mirror the chat path:
            // drop the user bubble, surface the paywall sheet instead of the
            // generic "Failed to get response" banner.
            if !messages.isEmpty, messages.last?.isUser == true {
                messages.removeLast()
            }
            // Build the rich struct so QuotaExhaustedView renders Plus
            // fair-use Contact Support flow (instead of an upgrade paywall
            // that doesn't apply) when the server flagged it.
            quotaError = QuotaErrorInfo(
                reason: quota.reason,
                planId: quota.planId,
                featureId: "ai_questions",
                message: quota.upgradeMessage,
                action: nil,
                suggestedPlan: quota.suggestedPlan,
                supportEmail: nil,
                resetAt: quota.resetAt,
                serverIsFairUseViolation: quota.isFairUseViolation
            )
            if let serverMsg = quota.upgradeMessage, !serverMsg.isEmpty {
                quotaMessage = serverMsg
            } else if quota.reason == "daily_limit_reached" {
                quotaMessage = "daily_limit_reached_tomorrow".localized
            } else {
                quotaMessage = "upgrade_to_keep_going".localized
            }
            showQuotaSheet = true
            print("[AskDestiny] Quota exhausted: \(quota.reason)")
        } catch {
            errorMessage = "Failed to get response. Please try again."
            print("Follow-up error: \(error)")
        }
    }
    
    // MARK: - Handle Redirect With Local Data (fallback when backend has no cache)
    private func handleRedirectWithLocalData(query: String, target: String, response: CompatibilityFollowUpResponse) async {
        // Build a response with birthData = nil so handleRedirect uses result.analysisData (local) instead
        let localResponse = CompatibilityFollowUpResponse(
            status: "redirect",
            target: target,
            answer: nil,
            message: nil,
            birthData: nil,  // Force handleRedirect to use result.analysisData
            redirectQuery: nil,
            reason: response.reason,
            executionTimeMs: nil,
            followUpSuggestions: nil
        )
        await handleRedirect(query: query, target: target, response: localResponse)
    }

    // MARK: - Handle Redirect to Individual Analysis (Streaming)
    private func handleRedirect(query: String, target: String, response: CompatibilityFollowUpResponse) async {
        let targetLower = target.lowercased()
        let boyNameLower = boyName.lowercased()
        let girlNameLower = girlName.lowercased()
        let boyFirst = boyName.components(separatedBy: " ").first ?? boyName
        let girlFirst = girlName.components(separatedBy: " ").first ?? girlName

        // Determine actual person — match "boy"/"his"/"him" → boyName, "girl"/"her"/"she" → girlName
        let isBoyTarget = targetLower.contains("boy") || targetLower.contains("him") || targetLower.contains("his") ||
                          targetLower == boyNameLower ||
                          boyNameLower.hasPrefix(targetLower) ||
                          targetLower.hasPrefix(boyNameLower)
        let isGirlTarget = targetLower.contains("girl") || targetLower.contains("her") || targetLower.contains("she") ||
                           targetLower == girlNameLower ||
                           girlNameLower.hasPrefix(targetLower) ||
                           targetLower.hasPrefix(girlNameLower)

        // Resolved display name — always a real person's name, never "Boy"/"Girl"
        let resolvedDisplayName: String
        let birthDetails: BirthDetails?
        if isBoyTarget {
            resolvedDisplayName = boyFirst
            birthDetails = result.analysisData?.boy?.details ?? response.birthData
        } else if isGirlTarget {
            resolvedDisplayName = girlFirst
            birthDetails = result.analysisData?.girl?.details ?? response.birthData
        } else {
            resolvedDisplayName = boyFirst
            birthDetails = result.analysisData?.boy?.details ?? response.birthData
            print("[AskDestiny] Ambiguous target '\(target)' — defaulting to \(boyFirst)'s data")
        }

        guard let details = birthDetails else {
            let errorMsg = CompatChatMessage(
                content: "Could not retrieve \(resolvedDisplayName)'s birth data for individual analysis.",
                isUser: false,
                type: .error
            )
            messages.append(errorMsg)
            return
        }

        // Add placeholder bubble — CompatChatBubble renders CosmicProgressView when redirectStreamingMessageId matches
        let redirectMsg = CompatChatMessage(content: "", isUser: false, type: .info)
        messages.append(redirectMsg)
        let redirectMsgId = redirectMsg.id
        redirectStreamingMessageId = redirectMsgId
        startRedirectProgressTimer()

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
        let compatThreadId = result.sessionId  // Already "compat_xxx" — use as-is to link predict to compat chat history
        let redirectLang = UserDefaults.standard.string(forKey: "appLanguageCode") ?? "en"
        let predictRequest = PredictionRequest(
            query: response.redirectQuery ?? query,
            birthData: birthData,
            sessionId: nil,
            conversationId: nil,  // No compat context — compat history confuses the LLM for the redirect person's chart
            userEmail: email,
            language: redirectLang,
            responseStyle: ContentStyleManager.shared.currentStyle.rawValue,
            responseLength: ResponseLengthManager.shared.currentLength.rawValue,
            quotaContext: "compatibility"
        )

        do {
            // Sub-agent path: non-streaming individual chart lookup
            let predictResponse = try await predictionService.predict(request: predictRequest)
            stopRedirectProgressTimer()
            redirectStreamingMessageId = nil
            withAnimation(.easeInOut(duration: 0.2)) { messages.removeAll { $0.id == redirectMsgId } }
            let analysisContent = "**Individual Analysis (\(resolvedDisplayName)):**\n\n\(predictResponse.answer)"
            var aiMessage = CompatChatMessage(content: analysisContent, isUser: false, type: .ai)
            aiMessage.executionTimeMs = predictResponse.executionTimeMs
            newMessageIds.insert(aiMessage.id)
            messages.append(aiMessage)
            saveMessagesToHistory()
            if showFollowUpSuggestions {
                let followUps = predictResponse.followUpSuggestions
                suggestedQuestions = followUps.isEmpty ? extractFollowUpQuestions(from: analysisContent) : followUps
            }
        } catch let error as NetworkError {
            stopRedirectProgressTimer()
            redirectStreamingMessageId = nil
            withAnimation(.easeInOut(duration: 0.2)) { messages.removeAll { $0.id == redirectMsgId } }
            let errorString = String(describing: error)
            if errorString.contains("maximum free questions") || errorString.contains("quota") || errorString.contains("limit") {
                let e = UserDefaults.standard.string(forKey: "userEmail") ?? ""
                quotaMessage = (QuotaManager.isGuestEmail(e) || isGuest)
                    ? "sign_in_to_continue_asking".localized
                    : "create_account_to_continue".localized
                showQuotaSheet = true
            } else {
                messages.append(CompatChatMessage(
                    content: "Failed to get individual analysis: \(error.localizedDescription)",
                    isUser: false, type: .error
                ))
            }
        } catch {
            stopRedirectProgressTimer()
            redirectStreamingMessageId = nil
            withAnimation(.easeInOut(duration: 0.2)) { messages.removeAll { $0.id == redirectMsgId } }
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("maximum free") || errorString.contains("quota") || errorString.contains("limit") {
                let e = UserDefaults.standard.string(forKey: "userEmail") ?? ""
                quotaMessage = (QuotaManager.isGuestEmail(e) || isGuest)
                    ? "sign_in_to_continue_asking".localized
                    : "create_account_to_continue".localized
                showQuotaSheet = true
            } else {
                messages.append(CompatChatMessage(
                    content: "Failed to get individual analysis: \(error.localizedDescription)",
                    isUser: false, type: .error
                ))
            }
        }
    }

    // MARK: - Follow-up Question Extraction

    /// Parse embedded FOLLOW_UP_QUESTIONS block from content when the JSON field is absent.
    private func extractFollowUpQuestions(from content: String) -> [String] {
        guard let markerRange = content.range(of: "\nFOLLOW_UP_QUESTIONS:") else { return [] }
        let block = String(content[markerRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return block.components(separatedBy: "\n").compactMap { line -> String? in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            let cleaned = trimmed
                .replacingOccurrences(of: "^[-•*]\\s*", with: "", options: .regularExpression)
                .replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned.isEmpty ? nil : cleaned
        }
    }

    // MARK: - Cosmic Progress Timer Helpers

    private static let cosmicMessageKeys: [String] = [
        "progress_connecting", "progress_mapping_sky", "progress_reading_planets",
        "progress_planetary_voice", "progress_chart_secrets", "progress_deeper_patterns",
        "progress_river_of_time", "progress_cosmic_windows", "progress_destiny_shaped",
        "progress_oracle_weaving"
    ]

    private func startCosmicTimer() {
        cosmicTimerTask?.cancel()
        cosmicTimerTask = Task { @MainActor in
            var index = 0
            while !Task.isCancelled {
                let key = Self.cosmicMessageKeys[index % 10]
                let step = CosmicProgressStep(text: LocalizedString.get(key),
                                              displayKey: key, isCompleted: false, isActive: true)
                withAnimation(.easeInOut(duration: 0.4)) { cosmicProgressSteps = [step] }
                index += 1
                try? await Task.sleep(nanoseconds: 1_500_000_000)
            }
        }
    }

    private func stopCosmicTimer() {
        cosmicTimerTask?.cancel()
        cosmicTimerTask = nil
        withAnimation(.easeOut(duration: 0.3)) { cosmicProgressSteps = [] }
    }

    private func startRedirectProgressTimer() {
        redirectProgressTimerTask?.cancel()
        redirectProgressTimerTask = Task { @MainActor in
            var index = 0
            while !Task.isCancelled {
                let key = Self.cosmicMessageKeys[index % 10]
                let step = CosmicProgressStep(text: LocalizedString.get(key),
                                              displayKey: key, isCompleted: false, isActive: true)
                withAnimation(.easeInOut(duration: 0.4)) { redirectCosmicProgressSteps = [step] }
                index += 1
                try? await Task.sleep(nanoseconds: 1_500_000_000)
            }
        }
    }

    private func stopRedirectProgressTimer() {
        redirectProgressTimerTask?.cancel()
        redirectProgressTimerTask = nil
        withAnimation(.easeOut(duration: 0.3)) { redirectCosmicProgressSteps = [] }
    }
}

// MARK: - Chat Bubble View (Matches ReadingMessageView fade-in pattern)
private struct CompatChatBubble: View {
    let message: CompatChatMessage
    var cosmicProgressSteps: [CosmicProgressStep] = []

    @State private var appeared = false
    @State private var showCopiedConfirmation = false

    // Cached formatter — DateFormatter is expensive to create
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    private var isUser: Bool { message.isUser }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if isUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                messageContent

                // Metadata row — only for completed AI messages (matches ChatView)
                if !isUser && message.type == .ai && appeared {
                    metadataRow
                }
            }

            if !isUser {
                Spacer(minLength: 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
        .accessibilityIdentifier(isUser ? "compat_user_message" : "compat_ai_message")
        .onAppear {
            guard !appeared else { return }
            withAnimation(.easeIn(duration: 0.5)) {
                appeared = true
            }
        }
    }

    private var displayContent: String {
        let raw = message.content
        if let markerRange = raw.range(of: "\nFOLLOW_UP_QUESTIONS:") {
            return String(raw[raw.startIndex..<markerRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return raw
    }

    @ViewBuilder
    private var messageContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isUser {
                Text(message.content)
                    .font(AppTheme.Fonts.body(size: 17))
                    .foregroundColor(AppTheme.Colors.mainBackground)
            } else if message.type == .info {
                // Info message — show cosmic progress during redirect streaming, else styled text
                if !cosmicProgressSteps.isEmpty {
                    CosmicProgressView(steps: cosmicProgressSteps)
                        .padding(.horizontal, 4)
                } else {
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
                }
            } else if message.type == .error {
                Text(message.content)
                    .font(AppTheme.Fonts.body(size: 14))
                    .foregroundColor(AppTheme.Colors.error)
            } else {
                MarkdownTextView(
                    content: displayContent,
                    textColor: AppTheme.Colors.textPrimary,
                    fontSize: 17
                )
                .opacity(appeared ? 1 : 0)
                .animation(.easeIn(duration: 0.5), value: appeared)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, isUser ? 14 : 4)
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
            Color.clear
        }
    }

    // MARK: - Metadata Row (timestamp · exec time · copy · stars)
    @ViewBuilder
    private var metadataRow: some View {
        HStack(spacing: 6) {
            Text(formatTime(message.timestamp))
                .font(AppTheme.Fonts.caption(size: 10))
                .foregroundColor(AppTheme.Colors.textTertiary)

            if message.executionTimeMs > 0 {
                Text("•")
                    .font(AppTheme.Fonts.caption(size: 10))
                    .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.6))
                Text(formatExecTime(message.executionTimeMs))
                    .font(AppTheme.Fonts.caption(size: 10))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            Spacer()

            if message.content.count > 50 {
                Button(action: {
                    UIPasteboard.general.string = displayContent
                    showCopiedConfirmation = true
                    HapticManager.shared.play(.light)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopiedConfirmation = false
                    }
                }) {
                    Image(systemName: showCopiedConfirmation ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(showCopiedConfirmation ? AppTheme.Colors.gold : AppTheme.Colors.textTertiary)
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: showCopiedConfirmation)
                .accessibilityLabel("a11y_copy_response".localized)
                .accessibilityIdentifier("copy_button")
            }

            if message.content.count > 50 {
                CompatInlineRating(messageContent: displayContent)
            }
        }
        .padding(.horizontal, 4)
    }

    private func formatTime(_ date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }

    private func formatExecTime(_ ms: Double) -> String {
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

// MARK: - Compact Inline Rating for Compatibility Chat
private struct CompatInlineRating: View {
    let messageContent: String

    @State private var selectedRating: Int = 0
    @State private var isSubmitting = false
    @State private var hasSubmitted = false

    var body: some View {
        HStack(spacing: 4) {
            if hasSubmitted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
                Text("rated_status".localized)
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .fixedSize()
            } else {
                Text("rate_action".localized)
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .fixedSize()
                HStack(spacing: 1) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            guard !isSubmitting else { return }
                            selectedRating = star
                            submitRating(star)
                        } label: {
                            Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                .font(.system(size: 12))
                                .foregroundColor(star <= selectedRating ? AppTheme.Colors.gold : AppTheme.Colors.textSecondary.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        .disabled(isSubmitting)
                        .accessibilityLabel(String(format: "a11y_star_rating".localized, star))
                    }
                }
                .opacity(isSubmitting ? 0.5 : 1)
            }
        }
    }

    private func submitRating(_ stars: Int) {
        isSubmitting = true
        Task {
            do {
                try await FeedbackService.shared.submitRating(
                    predictionId: nil,
                    rating: stars,
                    query: "Compatibility follow-up",
                    predictionText: String(messageContent.prefix(500)),
                    area: "compatibility"
                )
            } catch {
                print("[CompatRating] Submit failed: \(error)")
            }
            await MainActor.run {
                isSubmitting = false
                hasSubmitted = true
            }
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
    var executionTimeMs: Double = 0
    
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
