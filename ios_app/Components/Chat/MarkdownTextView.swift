import SwiftUI

// MARK: - MarkdownTextView
/// A reusable SwiftUI view that renders markdown-formatted text
/// Handles: Headers, Bold, Italic, Code, Lists, Links, Blockquotes, Tables, Dividers
/// v3 — ChatGPT-style: bold-label sections, improved spacing, gold label rendering, better bullets
struct MarkdownTextView: View {
    let content: String
    var textColor: Color = AppTheme.Colors.textPrimary
    var fontSize: CGFloat = 15

    @State private var blocks: [MarkdownBlock] = []
    @State private var lastParsedContent: String = ""

    // Cache for expensive AttributedString parsing (shared across all instances)
    private static let attrCache = NSCache<NSString, CachedAttrString>()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                renderBlock(block)
            }
        }
        .task(id: content) {
            // Debounce: skip if content is growing rapidly (typewriter animation).
            // Only parse when content changes significantly (>20 chars) or stops changing.
            let text = content
            if !lastParsedContent.isEmpty && text.hasPrefix(lastParsedContent) && text.count - lastParsedContent.count < 20 {
                try? await Task.sleep(nanoseconds: 150_000_000) // 150ms debounce
                guard !Task.isCancelled else { return }
            }
            let (parsed, _) = await Task.detached(priority: .userInitiated) {
                let parsedBlocks = Self.parseBlocksStatic(from: text)
                // Pre-warm the AttributedString cache for every inline text that will
                // be rendered. This runs off the main thread so the first body render
                // hits the cache instead of blocking the main thread with synchronous
                // AttributedString(markdown:) calls (which cause watchdog kills on long
                // Opus responses with 30-50 paragraphs).
                for block in parsedBlocks {
                    switch block {
                    case .paragraph(let t), .blockquote(let t):
                        Self.prewarmAttrCache(t)
                    case .boldLabel(_, let c):
                        if !c.isEmpty { Self.prewarmAttrCache(c) }
                    case .bulletList(let items), .numberedList(let items):
                        for item in items { Self.prewarmAttrCache(item) }
                    default:
                        break
                    }
                }
                return (parsedBlocks, ())
            }.value
            blocks = parsed
            lastParsedContent = text
        }
    }
    
    // MARK: - Block Types
    
    private enum MarkdownBlock: Equatable {
        case header(level: Int, text: String)
        case paragraph(text: String)
        case boldLabel(label: String, content: String)
        case bulletList(items: [String])
        case numberedList(items: [String])
        case codeBlock(code: String)
        case blockquote(text: String)
        case table(headers: [String], rows: [[String]])
        case divider
    }
    
    // MARK: - Block Parser (No Regex - Performance Optimized)
    
    /// Static parser that can run off main thread
    private static func parseBlocksStatic(from content: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = content.components(separatedBy: "\n")
        var i = 0
        
        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Empty line - skip
            if trimmed.isEmpty {
                i += 1
                continue
            }
            
            // Horizontal rule (--- or *** or ___) — must check BEFORE bullet list
            if isDivider(trimmed) {
                blocks.append(.divider)
                i += 1
                continue
            }
            
            // Code block (``` ... ```)
            if trimmed.hasPrefix("```") {
                var codeLines: [String] = []
                i += 1
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                blocks.append(.codeBlock(code: codeLines.joined(separator: "\n")))
                if i < lines.count { i += 1 } // skip closing ```
                continue
            }
            
            // Header (## or ### or ####)
            if let headerMatch = parseHeaderStatic(trimmed) {
                blocks.append(headerMatch)
                i += 1
                continue
            }
            
            // Table detection: line contains | and next line is separator (|---|)
            if trimmed.contains("|") && isTableStartStatic(lines: lines, at: i) {
                let tableBlock = parseTableStatic(lines: lines, at: &i)
                if let table = tableBlock {
                    blocks.append(table)
                }
                continue
            }
            
            // Blockquote (> text)
            if trimmed.hasPrefix(">") {
                let quote = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                blocks.append(.blockquote(text: quote))
                i += 1
                continue
            }
            
            // Bullet list (- item or * item or • item)
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
                var items: [String] = []
                while i < lines.count {
                    let listLine = lines[i].trimmingCharacters(in: .whitespaces)
                    if listLine.hasPrefix("- ") {
                        items.append(String(listLine.dropFirst(2)))
                        i += 1
                    } else if listLine.hasPrefix("* ") {
                        items.append(String(listLine.dropFirst(2)))
                        i += 1
                    } else if listLine.hasPrefix("• ") {
                        items.append(String(listLine.dropFirst(2)))
                        i += 1
                    } else if listLine.isEmpty {
                        i += 1
                        break
                    } else {
                        break
                    }
                }
                if !items.isEmpty {
                    blocks.append(.bulletList(items: items))
                }
                continue
            }
            
            // Numbered list (1. item, 2. item, etc.) - Simple check without regex
            if isNumberedListItem(trimmed) {
                var items: [String] = []
                while i < lines.count {
                    let listLine = lines[i].trimmingCharacters(in: .whitespaces)
                    if let itemText = extractNumberedListItem(listLine) {
                        items.append(itemText)
                        i += 1
                    } else if listLine.isEmpty {
                        i += 1
                        break
                    } else {
                        break
                    }
                }
                if !items.isEmpty {
                    blocks.append(.numberedList(items: items))
                }
                continue
            }
            
            // Regular paragraph — each line with **bold:** prefix treated as standalone
            var paragraphLines: [String] = []
            while i < lines.count {
                let pLine = lines[i].trimmingCharacters(in: .whitespaces)
                if pLine.isEmpty || pLine.hasPrefix("#") || pLine.hasPrefix("> ") || pLine.hasPrefix("```") ||
                   isNumberedListItem(pLine) || isDivider(pLine) ||
                   (pLine.contains("|") && i + 1 < lines.count && isTableSeparatorStatic(lines[i + 1].trimmingCharacters(in: .whitespaces))) {
                    break
                }
                // Bullet check (but not --- which is already caught by isDivider)
                if pLine.hasPrefix("- ") || pLine.hasPrefix("* ") || pLine.hasPrefix("• ") {
                    break
                }
                
                // If this line starts with **bold:** or **bold** and previous lines exist,
                // treat it as a new paragraph to preserve line breaks
                if paragraphLines.count > 0 && pLine.hasPrefix("**") {
                    break
                }
                
                paragraphLines.append(pLine)
                i += 1
            }
            if !paragraphLines.isEmpty {
                let joined = paragraphLines.joined(separator: " ")
                if let labelBlock = parseBoldLabelStatic(joined) {
                    blocks.append(labelBlock)
                } else {
                    blocks.append(.paragraph(text: joined))
                }
            }
        }
        
        return blocks
    }
    
    // Instance wrappers for use in view body (call static versions)
    private func parseBlocks() -> [MarkdownBlock] {
        Self.parseBlocksStatic(from: content)
    }
    
    // MARK: - Divider Detection (static for background parsing)
    
    private static func isDivider(_ line: String) -> Bool {
        let stripped = line.replacingOccurrences(of: " ", with: "")
        if stripped.count >= 3 {
            if stripped.allSatisfy({ $0 == "-" }) { return true }
            if stripped.allSatisfy({ $0 == "*" }) { return true }
            if stripped.allSatisfy({ $0 == "_" }) { return true }
        }
        return false
    }
    
    // Instance wrapper
    private func isDivider(_ line: String) -> Bool { Self.isDivider(line) }
    
    // MARK: - Table Parsing (static for background parsing)
    
    private static func isTableSeparatorStatic(_ line: String) -> Bool {
        let stripped = line.replacingOccurrences(of: " ", with: "")
        return stripped.contains("|") && stripped.contains("-") &&
               stripped.replacingOccurrences(of: "|", with: "")
                       .replacingOccurrences(of: "-", with: "")
                       .replacingOccurrences(of: ":", with: "")
                       .isEmpty
    }
    
    private static func isTableStartStatic(lines: [String], at index: Int) -> Bool {
        guard index + 1 < lines.count else { return false }
        let nextLine = lines[index + 1].trimmingCharacters(in: .whitespaces)
        return isTableSeparatorStatic(nextLine)
    }
    
    private static func parseTableRowStatic(_ line: String) -> [String] {
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("|") { trimmed = String(trimmed.dropFirst()) }
        if trimmed.hasSuffix("|") { trimmed = String(trimmed.dropLast()) }
        return trimmed.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    private static func parseTableStatic(lines: [String], at index: inout Int) -> MarkdownBlock? {
        let headers = parseTableRowStatic(lines[index])
        index += 1
        
        if index < lines.count {
            index += 1
        }
        
        var rows: [[String]] = []
        while index < lines.count {
            let rowLine = lines[index].trimmingCharacters(in: .whitespaces)
            if rowLine.isEmpty || !rowLine.contains("|") {
                break
            }
            if index + 1 < lines.count && isTableSeparatorStatic(lines[index + 1].trimmingCharacters(in: .whitespaces)) {
                break
            }
            let cells = parseTableRowStatic(rowLine)
            rows.append(cells)
            index += 1
        }
        
        guard !headers.isEmpty else { return nil }
        return .table(headers: headers, rows: rows)
    }
    
    // MARK: - Numbered List Helpers (static for background parsing)
    
    private static func isNumberedListItem(_ line: String) -> Bool {
        guard line.count >= 3 else { return false }
        if let dotIndex = line.firstIndex(of: ".") {
            let prefix = String(line[..<dotIndex])
            if !prefix.isEmpty && prefix.allSatisfy({ $0.isNumber }) {
                let afterDot = line.index(dotIndex, offsetBy: 1)
                if afterDot < line.endIndex && line[afterDot] == " " {
                    return true
                }
            }
        }
        return false
    }
    
    private static func extractNumberedListItem(_ line: String) -> String? {
        guard isNumberedListItem(line) else { return nil }
        if let dotIndex = line.firstIndex(of: ".") {
            guard let afterDot = line.index(dotIndex, offsetBy: 2, limitedBy: line.endIndex),
                  afterDot < line.endIndex else { return nil }
            return String(line[afterDot...])
        }
        return nil
    }
    
    private static func parseHeaderStatic(_ line: String) -> MarkdownBlock? {
        if line.hasPrefix("#### ") {
            return .header(level: 4, text: String(line.dropFirst(5)))
        } else if line.hasPrefix("### ") {
            return .header(level: 3, text: String(line.dropFirst(4)))
        } else if line.hasPrefix("## ") {
            return .header(level: 2, text: String(line.dropFirst(3)))
        } else if line.hasPrefix("# ") {
            return .header(level: 1, text: String(line.dropFirst(2)))
        }
        return nil
    }
    
    // MARK: - Bold Label Detection (static for background parsing)
    
    private static func parseBoldLabelStatic(_ text: String) -> MarkdownBlock? {
        guard text.hasPrefix("**") else { return nil }
        
        let afterOpen = text.index(text.startIndex, offsetBy: 2)
        guard let closeRange = text.range(of: "**", range: afterOpen..<text.endIndex) else {
            return nil
        }
        
        let label = String(text[afterOpen..<closeRange.lowerBound])
        
        guard label.hasSuffix(":") || label.hasSuffix(": ") else {
            return nil
        }
        
        let contentStart = closeRange.upperBound
        let content = contentStart < text.endIndex
            ? String(text[contentStart...]).trimmingCharacters(in: .whitespaces)
            : ""
        
        return .boldLabel(label: label.trimmingCharacters(in: .whitespaces), content: content)
    }
    
    // MARK: - Block Renderer
    
    @ViewBuilder
    private func renderBlock(_ block: MarkdownBlock) -> some View {
        switch block {
        case .header(let level, let text):
            renderHeader(level: level, text: text)
            
        case .paragraph(let text):
            renderInlineMarkdown(text)
            
        case .boldLabel(let label, let content):
            renderBoldLabel(label: label, content: content)
            
        case .bulletList(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Circle()
                            .fill(AppTheme.Colors.gold.opacity(0.7))
                            .frame(width: 5, height: 5)
                            .offset(y: 1)
                        renderInlineMarkdown(item)
                    }
                    .padding(.leading, 4)
                }
            }
            
        case .numberedList(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(index + 1).")
                            .foregroundColor(AppTheme.Colors.gold)
                            .font(.system(size: fontSize, weight: .semibold))
                            .frame(minWidth: 20, alignment: .trailing)
                        renderInlineMarkdown(item)
                    }
                    .padding(.leading, 4)
                }
            }
            
        case .codeBlock(let code):
            Text(code)
                .font(.system(size: fontSize - 1, design: .monospaced))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.Colors.inputBackground)
                .cornerRadius(AppTheme.Styles.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Styles.cornerRadius)
                        .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                )
            
        case .blockquote(let text):
            renderInlineMarkdown(text)
                .italic()
                .padding(.vertical, 8)
                .padding(.leading, 16)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(AppTheme.Colors.gold)
                        .frame(width: 3)
                        .alignmentGuide(.top) { $0[.top] }
                        .alignmentGuide(.bottom) { $0[.bottom] }
                }
            
        case .table(let headers, let rows):
            renderTable(headers: headers, rows: rows)
            
        case .divider:
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.gold.opacity(0),
                            AppTheme.Colors.gold.opacity(0.4),
                            AppTheme.Colors.gold.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.vertical, 4)
        }
    }
    
    // MARK: - Table Renderer
    
    private func renderTable(headers: [String], rows: [[String]]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                ForEach(Array(headers.enumerated()), id: \.offset) { index, header in
                    Text(stripMarkdownBold(header))
                        .font(AppTheme.Fonts.caption(size: fontSize - 2).weight(.bold))
                        .foregroundColor(AppTheme.Colors.gold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    
                    if index < headers.count - 1 {
                        Rectangle()
                            .fill(AppTheme.Colors.gold.opacity(0.15))
                            .frame(width: 1)
                    }
                }
            }
            .background(AppTheme.Colors.gold.opacity(0.08))
            
            // Separator
            Rectangle()
                .fill(AppTheme.Colors.gold.opacity(0.2))
                .frame(height: 1)
            
            // Data rows
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIdx, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { colIdx, cell in
                        Text(stripMarkdownBold(cell))
                            .font(AppTheme.Fonts.body(size: fontSize - 2))
                            .foregroundColor(textColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                        
                        if colIdx < row.count - 1 {
                            Rectangle()
                                .fill(AppTheme.Colors.gold.opacity(0.1))
                                .frame(width: 1)
                        }
                    }
                }
                .background(rowIdx % 2 == 0 ? Color.clear : AppTheme.Colors.gold.opacity(0.03))
                
                // Row separator
                if rowIdx < rows.count - 1 {
                    Rectangle()
                        .fill(AppTheme.Colors.gold.opacity(0.08))
                        .frame(height: 1)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.Colors.gold.opacity(0.2), lineWidth: 1)
        )
    }
    
    /// Strip ** bold ** markers from table cell text for plain rendering
    private func stripMarkdownBold(_ text: String) -> String {
        text.replacingOccurrences(of: "**", with: "")
    }
    
    // MARK: - Header Renderer
    
    private func renderHeader(level: Int, text: String) -> some View {
        let cleanText = text.replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespaces)
        let headerFontSize: CGFloat
        let weight: Font.Weight
        
        switch level {
        case 1:
            headerFontSize = fontSize + 6
            weight = .bold
        case 2:
            headerFontSize = fontSize + 4
            weight = .bold
        case 3:
            headerFontSize = fontSize + 2
            weight = .semibold
        default:
            headerFontSize = fontSize + 1
            weight = .semibold
        }
        
        return HStack(spacing: 6) {
            Text(cleanText)
                .font(.system(size: headerFontSize, weight: weight))
                .foregroundColor(AppTheme.Colors.gold)
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
    
    // MARK: - Bold Label Renderer (ChatGPT-style **Label:** content)
    
    @ViewBuilder
    private func renderBoldLabel(label: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if content.isEmpty {
                // Label-only line (e.g. "**Chart Promise:**" followed by bullet list)
                Text(label)
                    .font(.system(size: fontSize + 1, weight: .bold))
                    .foregroundColor(AppTheme.Colors.gold)
            } else {
                // Label + inline content (e.g. "**Verdict:** Highly Favorable — Confidence: High")
                (Text(label + " ")
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundColor(AppTheme.Colors.gold)
                +
                renderInlineAttributedString(content))
                    .lineSpacing(5)
                    .textSelection(.enabled)
            }
        }
    }
    
    /// Build an AttributedString for inline content (used by bold label renderer)
    private func renderInlineAttributedString(_ text: String) -> Text {
        let sanitized = sanitizeForInlineParsing(text)
        if let attrString = cachedAttributedString(for: sanitized) {
            return Text(attrString)
                .font(AppTheme.Fonts.body(size: fontSize))
                .foregroundColor(textColor)
        }
        return Text(stripMarkdownBold(sanitized))
            .font(AppTheme.Fonts.body(size: fontSize))
            .foregroundColor(textColor)
    }
    
    // MARK: - Inline Markdown (cached)
    
    @ViewBuilder
    private func renderInlineMarkdown(_ text: String) -> some View {
        let sanitized = sanitizeForInlineParsing(text)
        
        if let attrString = cachedAttributedString(for: sanitized) {
            Text(attrString)
                .font(AppTheme.Fonts.body(size: fontSize))
                .foregroundColor(textColor)
                .lineSpacing(5)
                .textSelection(.enabled)
        } else {
            Text(stripMarkdownBold(sanitized))
                .font(AppTheme.Fonts.body(size: fontSize))
                .foregroundColor(textColor)
                .lineSpacing(5)
        }
    }
    
    /// Cached AttributedString lookup — avoids re-parsing identical text on main thread
    private func cachedAttributedString(for sanitized: String) -> AttributedString? {
        let key = sanitized as NSString
        if let cached = Self.attrCache.object(forKey: key) {
            return cached.value
        }
        if let attrString = try? AttributedString(
            markdown: sanitized,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            Self.attrCache.setObject(CachedAttrString(attrString), forKey: key)
            return attrString
        }
        return nil
    }

    /// Pre-warm the attrCache off the main thread so body renders are cache hits.
    /// Called from .task (background thread) before blocks are set on the main thread.
    private static func prewarmAttrCache(_ text: String) {
        var result = text
        result = result.replacingOccurrences(of: "|", with: "·")
        let boldCount = result.components(separatedBy: "**").count - 1
        if boldCount % 2 != 0 { result += "**" }
        let italicSingles = result.components(separatedBy: "*").count - 1 - (boldCount / 2 * 2 + boldCount % 2)
        if italicSingles > 0 && italicSingles % 2 != 0 { result += "*" }
        let key = result as NSString
        guard attrCache.object(forKey: key) == nil else { return }
        if let attrString = try? AttributedString(
            markdown: result,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            attrCache.setObject(CachedAttrString(attrString), forKey: key)
        }
    }
    
    /// Sanitize text for safe inline markdown parsing.
    /// Removes/escapes characters that cause AttributedString to hang or fail.
    private func sanitizeForInlineParsing(_ text: String) -> String {
        var result = text
        
        // Pipe characters from table remnants cause hangs — escape them
        result = result.replacingOccurrences(of: "|", with: "·")
        
        // Unclosed bold/italic markers cause hangs — close them
        let boldCount = result.components(separatedBy: "**").count - 1
        if boldCount % 2 != 0 {
            result += "**"
        }
        let italicSingles = result.components(separatedBy: "*").count - 1 - (boldCount / 2 * 2 + boldCount % 2)
        // Simplified: if odd number of non-bold * marks, close
        if italicSingles > 0 && italicSingles % 2 != 0 {
            result += "*"
        }
        
        return result
    }
}

// MARK: - AttributedString Cache Wrapper (NSCache requires reference type)
private final class CachedAttrString: NSObject {
    let value: AttributedString
    init(_ value: AttributedString) { self.value = value }
}

// MARK: - Preview

#Preview("Full Markdown") {
    ScrollView {
        MarkdownTextView(content: """
        **Verdict:** Highly Favorable — Confidence: High

        Your career chart shows exceptionally strong promise for a job change, primarily driven by **Jupiter** as your **10th lord**.

        **Chart Promise:**
        - **Jupiter** in **D10** — own sign (Sagittarius) in 10th house = high status
        - **Jupiter** exalted in **D9** (Cancer), confirming D1 promise
        - **Gajakesari Yoga** active via Jupiter-Moon = professional recognition

        **Best Window:** November 2026 — April 2027
        - **Saturn-Saturn-Jupiter dasha** directly activates your 10th lord
        - Transit **Saturn** in Pisces aspecting **10th house** = restructuring
        - Transit **Jupiter** in Cancer = double transit trigger

        **Challenges:**
        - Current **Saturn-Saturn** period may feel restrictive until the window opens
        - **Mars** transit over **6th house** in Jan 2027 = workplace friction

        **Guidance:**
        Begin preparations now. The Nov 2026 window is strongest when both dasha and transit align. Network actively during **Jupiter's** Cancer transit — this is your career expansion period.
        """, fontSize: 16)
        .padding()
    }
    .background(AppTheme.Colors.mainBackground)
}

// MARK: - Typing Indicator


/// Animated typing indicator for AI response loading - Professional design
struct PremiumTypingIndicator: View {
    @State private var animationPhase: Int = 0
    @State private var dotScales: [CGFloat] = [1.0, 1.0, 1.0]
    @State private var bounceTimer: Timer?
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(spacing: 10) {
                // AI Avatar
                Circle()
                    .fill(AppTheme.Colors.gold)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text("D")
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundColor(AppTheme.Colors.mainBackground)
                    )
                
                // Typing label + dots
                HStack(spacing: 4) {
                    Text("analyzing_label".localized)
                        .font(AppTheme.Fonts.body(size: 13))
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    // Bouncing dots
                    HStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(AppTheme.Colors.gold)
                                .frame(width: 6, height: 6)
                                .scaleEffect(dotScales[index])
                                .offset(y: animationPhase == index ? -4 : 0)
                        }
                    }
                }
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
            startBouncingAnimation()
        }
        .onDisappear {
            bounceTimer?.invalidate()
            bounceTimer = nil
        }
    }
    
    private func startBouncingAnimation() {
        // Continuous bouncing animation
        bounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

#Preview("Typing") {
    PremiumTypingIndicator()
        .padding()
        .background(Color(red: 0.96, green: 0.95, blue: 0.98))
}
