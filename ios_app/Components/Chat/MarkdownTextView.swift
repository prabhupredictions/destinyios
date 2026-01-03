import SwiftUI

// MARK: - MarkdownTextView
/// A reusable SwiftUI view that renders markdown-formatted text
/// Handles: Headers, Bold, Italic, Code, Lists, Links, Blockquotes
/// Optimized for performance - no regex in parsing
struct MarkdownTextView: View {
    let content: String
    var textColor: Color = AppTheme.Colors.textPrimary
    var fontSize: CGFloat = 15
    
    @State private var blocks: [MarkdownBlock] = []
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                renderBlock(block)
            }
        }
        .onAppear {
            if blocks.isEmpty {
                blocks = parseBlocks()
            }
        }
        .onChange(of: content) { newValue in
            blocks = parseBlocks()
        }
    }
    
    // MARK: - Block Types
    
    private enum MarkdownBlock: Equatable {
        case header(level: Int, text: String)
        case paragraph(text: String)
        case bulletList(items: [String])
        case numberedList(items: [String])
        case codeBlock(code: String)
        case blockquote(text: String)
    }
    
    // MARK: - Block Parser (No Regex - Performance Optimized)
    
    private func parseBlocks() -> [MarkdownBlock] {
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
            
            // Code block (``` ... ```)
            if trimmed.hasPrefix("```") {
                var codeLines: [String] = []
                i += 1
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                blocks.append(.codeBlock(code: codeLines.joined(separator: "\n")))
                i += 1
                continue
            }
            
            // Header (## or ### or ####)
            if let headerMatch = parseHeader(trimmed) {
                blocks.append(headerMatch)
                i += 1
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
            
            // Regular paragraph - collect consecutive lines
            var paragraphLines: [String] = []
            while i < lines.count {
                let pLine = lines[i].trimmingCharacters(in: .whitespaces)
                if pLine.isEmpty || pLine.hasPrefix("#") || pLine.hasPrefix("-") || 
                   pLine.hasPrefix("* ") || pLine.hasPrefix(">") || pLine.hasPrefix("```") ||
                   isNumberedListItem(pLine) {
                    break
                }
                paragraphLines.append(pLine)
                i += 1
            }
            if !paragraphLines.isEmpty {
                blocks.append(.paragraph(text: paragraphLines.joined(separator: " ")))
            }
        }
        
        return blocks
    }
    
    // Check if line starts with number followed by dot and space (e.g., "1. ", "10. ")
    private func isNumberedListItem(_ line: String) -> Bool {
        guard line.count >= 3 else { return false }
        
        // Find the first dot
        if let dotIndex = line.firstIndex(of: ".") {
            let prefix = String(line[..<dotIndex])
            // Check if prefix is all digits and followed by ". "
            if !prefix.isEmpty && prefix.allSatisfy({ $0.isNumber }) {
                let afterDot = line.index(dotIndex, offsetBy: 1)
                if afterDot < line.endIndex && line[afterDot] == " " {
                    return true
                }
            }
        }
        return false
    }
    
    // Extract the text after "N. " from a numbered list item
    private func extractNumberedListItem(_ line: String) -> String? {
        guard isNumberedListItem(line) else { return nil }
        
        if let dotIndex = line.firstIndex(of: ".") {
            let afterDot = line.index(dotIndex, offsetBy: 2) // Skip ". "
            if afterDot < line.endIndex {
                return String(line[afterDot...])
            }
        }
        return nil
    }
    
    private func parseHeader(_ line: String) -> MarkdownBlock? {
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
    
    // MARK: - Block Renderer
    
    @ViewBuilder
    private func renderBlock(_ block: MarkdownBlock) -> some View {
        switch block {
        case .header(let level, let text):
            renderHeader(level: level, text: text)
            
        case .paragraph(let text):
            renderInlineMarkdown(text)
            
        case .bulletList(let items):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(AppTheme.Colors.gold)
                            .font(.system(size: fontSize, weight: .bold))
                        renderInlineMarkdown(item)
                    }
                }
            }
            
        case .numberedList(let items):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .foregroundColor(AppTheme.Colors.gold)
                            .font(.system(size: fontSize, weight: .semibold))
                            .frame(minWidth: 20, alignment: .trailing)
                        renderInlineMarkdown(item)
                    }
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
            HStack(spacing: 12) {
                Rectangle()
                    .fill(AppTheme.Colors.gold)
                    .frame(width: 3)
                renderInlineMarkdown(text)
                    .italic()
            }
            .padding(.vertical, 4)
        }
    }
    
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
    
    // MARK: - Inline Markdown
    
    @ViewBuilder
    private func renderInlineMarkdown(_ text: String) -> some View {
        if let attrString = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            Text(attrString)
                .font(AppTheme.Fonts.body(size: fontSize))
                .foregroundColor(textColor)
                .lineSpacing(4)
                .textSelection(.enabled)
        } else {
            Text(text)
                .font(AppTheme.Fonts.body(size: fontSize))
                .foregroundColor(textColor)
                .lineSpacing(4)
        }
    }
}

// MARK: - Preview

#Preview("Full Markdown") {
    ScrollView {
        MarkdownTextView(content: """
        ### VERDICT:
        **Likely** (Medium Probability)
        
        ### TIMING:
        The most auspicious time is between **June 2026 and August 2026**.
        
        ### RATIONALE:
        Here are the key factors:
        
        - Mercury is well-placed in the 7th house
        - Jupiter's transit enhances prospects
        - Venus adds positive energy
        
        > Note: This is based on your birth chart analysis.
        
        1. Check your compatibility
        2. Consult with family
        3. Plan accordingly
        
        ```
        Dasha Period: Venus-Moon-Jupiter
        ```
        """)
        .padding()
    }
    .background(Color(red: 0.96, green: 0.95, blue: 0.98))
}

// MARK: - Typing Indicator


/// Animated typing indicator for AI response loading - Professional design
struct PremiumTypingIndicator: View {
    @State private var animationPhase: Int = 0
    @State private var dotScales: [CGFloat] = [1.0, 1.0, 1.0]
    
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
                    Text("Analyzing")
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
    }
    
    private func startBouncingAnimation() {
        // Continuous bouncing animation
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
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
