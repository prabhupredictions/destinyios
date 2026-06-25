import SwiftUI

// MARK: - MarkdownTextView (v4 rebuild)
//
// Renders ChatGPT-style markdown with the app's gold accents.
// Designed for crash safety + simplicity.
//
// Key principles (replacing v3, which had subtle @MainActor / NSCache /
// Task.detached interactions that caused the 0x8BADF00D watchdog
// crash repeatedly between 1.7 and 1.8 b428):
//   1. NO static stored state. Cache lives nowhere — SwiftUI rebuilds
//      View instances cheaply and AttributedString(markdown:) is fast
//      on inputs we ever pass through (block-by-block, each < 8 KB).
//   2. NO Task.detached. Parsing is straight-line synchronous Swift
//      string operations; for any reasonable chat message (< 50 KB)
//      this completes in single-digit milliseconds on device.
//   3. NO @ViewBuilder + explicit return mix. All conditional render
//      paths use plain @ViewBuilder if/else.
//   4. ONE attributed-string boundary, with a hard-coded safe path:
//      strip nested dangerous markers, parse, on any failure fall
//      through to plain Text. No multi-layer validators.
//
// Visual contract preserved from v3:
//   - Headers (## ### ####) in gold
//   - **Label:** content sections (gold bold label)
//   - Bullet lists with gold dot
//   - Numbered lists
//   - Diamond (◆) lists in gold
//   - Takeaway (→) lines in gold
//   - Blockquotes with gold left-bar, bold+italic via view modifier
//   - Code blocks (monospace, gold border)
//   - Tables, dividers, plain paragraphs
struct MarkdownTextView: View {
    let content: String
    var textColor: Color = AppTheme.Colors.textPrimary
    var fontSize: CGFloat = 15

    /// Hard cap: above this size, render as plain Text. No reasonable
    /// chat message exceeds 40 KB; this is a defense-in-depth backstop
    /// for runaway LLM output.
    private static let MAX_MARKDOWN_BYTES = 40_000

    var body: some View {
        if content.utf8.count > Self.MAX_MARKDOWN_BYTES {
            Text(MarkdownTextView.stripAllMarkers(content))
                .font(.system(size: fontSize))
                .foregroundColor(textColor)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            // Synchronous parse. For typical chat messages (< 16 KB) this
            // is single-digit milliseconds. SwiftUI re-runs `body` on
            // every @State change in the parent; we don't add our own
            // caching — that's what caused the v3 isolation bugs.
            let blocks = MarkdownTextView.parse(content)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(blocks.indices, id: \.self) { i in
                    renderBlock(blocks[i])
                }
            }
        }
    }

    // MARK: - Block types

    fileprivate enum Block {
        case header(level: Int, text: String)
        case paragraph(text: String)
        case boldLabel(label: String, content: String)
        case bulletList(items: [String])
        case numberedList(items: [String])
        case diamondList(items: [String])
        case takeaway(text: String)
        case codeBlock(code: String)
        case blockquote(text: String)
        case table(headers: [String], rows: [[String]])
        case divider
    }

    // MARK: - Parser (pure, no statics, no isolation)

    fileprivate static func parse(_ content: String) -> [Block] {
        var blocks: [Block] = []
        let lines = content.components(separatedBy: "\n")
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                i += 1
                continue
            }

            // Horizontal divider (--- *** ___) — before bullet
            if isDivider(trimmed) {
                blocks.append(.divider)
                i += 1
                continue
            }

            // Code block (```)
            if trimmed.hasPrefix("```") {
                var codeLines: [String] = []
                i += 1
                while i < lines.count,
                      !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                blocks.append(.codeBlock(code: codeLines.joined(separator: "\n")))
                if i < lines.count { i += 1 }
                continue
            }

            // Header (## ### ####)
            if let h = parseHeader(trimmed) {
                blocks.append(h)
                i += 1
                continue
            }

            // Table — `| ... |` with `|---|` on the next line
            if trimmed.contains("|"),
               i + 1 < lines.count,
               isTableSeparator(lines[i + 1].trimmingCharacters(in: .whitespaces)) {
                let headers = parseTableRow(trimmed)
                i += 2  // skip header + separator
                var rows: [[String]] = []
                while i < lines.count {
                    let rowLine = lines[i].trimmingCharacters(in: .whitespaces)
                    if rowLine.isEmpty || !rowLine.contains("|") { break }
                    rows.append(parseTableRow(rowLine))
                    i += 1
                }
                blocks.append(.table(headers: headers, rows: rows))
                continue
            }

            // Blockquote
            if trimmed.hasPrefix(">") {
                let quote = String(trimmed.dropFirst())
                    .trimmingCharacters(in: .whitespaces)
                blocks.append(.blockquote(text: quote))
                i += 1
                continue
            }

            // Bullet list (- * •)
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
                var items: [String] = []
                while i < lines.count {
                    let l = lines[i].trimmingCharacters(in: .whitespaces)
                    if l.hasPrefix("- ") || l.hasPrefix("* ") || l.hasPrefix("• ") {
                        items.append(String(l.dropFirst(2)))
                        i += 1
                    } else if l.isEmpty {
                        i += 1
                        break
                    } else {
                        break
                    }
                }
                if !items.isEmpty { blocks.append(.bulletList(items: items)) }
                continue
            }

            // Diamond bullet list (◆)
            if trimmed.hasPrefix("◆ ") {
                var items: [String] = []
                while i < lines.count {
                    let l = lines[i].trimmingCharacters(in: .whitespaces)
                    if l.hasPrefix("◆ ") {
                        items.append(String(l.dropFirst(2)))
                        i += 1
                    } else if l.isEmpty {
                        i += 1
                        break
                    } else {
                        break
                    }
                }
                if !items.isEmpty { blocks.append(.diamondList(items: items)) }
                continue
            }

            // Takeaway (→)
            if trimmed.hasPrefix("→ ") || trimmed.hasPrefix("→") {
                let text = String(trimmed.drop(while: { $0 == "→" || $0 == " " }))
                blocks.append(.takeaway(text: text))
                i += 1
                continue
            }

            // Numbered list (1. ...)
            if isNumberedListItem(trimmed) {
                var items: [String] = []
                while i < lines.count {
                    let l = lines[i].trimmingCharacters(in: .whitespaces)
                    if let item = extractNumberedItem(l) {
                        items.append(item)
                        i += 1
                    } else if l.isEmpty {
                        i += 1
                        break
                    } else {
                        break
                    }
                }
                if !items.isEmpty { blocks.append(.numberedList(items: items)) }
                continue
            }

            // Bold label (**Label:** content)
            if let labelBlock = parseBoldLabel(trimmed) {
                blocks.append(labelBlock)
                i += 1
                continue
            }

            // Default: paragraph
            blocks.append(.paragraph(text: trimmed))
            i += 1
        }

        return blocks
    }

    // MARK: - Block helpers (pure)

    private static func isDivider(_ line: String) -> Bool {
        let s = line.replacingOccurrences(of: " ", with: "")
        guard s.count >= 3 else { return false }
        return s.allSatisfy({ $0 == "-" })
            || s.allSatisfy({ $0 == "*" })
            || s.allSatisfy({ $0 == "_" })
    }

    private static func parseHeader(_ line: String) -> Block? {
        if line.hasPrefix("#### ") {
            return .header(level: 4, text: String(line.dropFirst(5)))
        }
        if line.hasPrefix("### ") {
            return .header(level: 3, text: String(line.dropFirst(4)))
        }
        if line.hasPrefix("## ") {
            return .header(level: 2, text: String(line.dropFirst(3)))
        }
        if line.hasPrefix("# ") {
            return .header(level: 1, text: String(line.dropFirst(2)))
        }
        return nil
    }

    private static func parseBoldLabel(_ text: String) -> Block? {
        guard text.hasPrefix("**") else { return nil }
        let afterOpen = text.index(text.startIndex, offsetBy: 2)
        guard let closeBold = text.range(of: "**", range: afterOpen..<text.endIndex)
        else { return nil }
        let label = String(text[afterOpen..<closeBold.lowerBound])
        let rest = String(text[closeBold.upperBound...])
            .trimmingCharacters(in: .whitespaces)

        // Two accepted patterns (v3 behavior preserved):
        //   `**Label:** content`     → bold gold label + body content
        //   `**Standalone Title**`   → bold gold heading on its own (no `:`)
        // Anything else (e.g. `**bold word** in middle of paragraph` or
        // `**multi-word inline**` followed by more content without colon)
        // should fall through and stay as a paragraph with inline bold.
        let isLabelWithColon = label.hasSuffix(":") || label.hasSuffix(": ")
        guard isLabelWithColon || rest.isEmpty else { return nil }

        let labelClean = isLabelWithColon
            ? String(label.dropLast())  // strip trailing :
                .trimmingCharacters(in: .whitespaces)
            : label.trimmingCharacters(in: .whitespaces)
        return .boldLabel(label: labelClean, content: rest)
    }

    private static func isTableSeparator(_ line: String) -> Bool {
        let s = line.replacingOccurrences(of: " ", with: "")
        guard s.contains("|"), s.contains("-") else { return false }
        return s.replacingOccurrences(of: "|", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: ":", with: "")
            .isEmpty
    }

    private static func parseTableRow(_ line: String) -> [String] {
        var t = line.trimmingCharacters(in: .whitespaces)
        if t.hasPrefix("|") { t = String(t.dropFirst()) }
        if t.hasSuffix("|") { t = String(t.dropLast()) }
        return t.components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private static func isNumberedListItem(_ line: String) -> Bool {
        guard line.count >= 3, let dot = line.firstIndex(of: ".") else { return false }
        let prefix = String(line[..<dot])
        guard !prefix.isEmpty, prefix.allSatisfy({ $0.isNumber }) else { return false }
        let afterDot = line.index(after: dot)
        return afterDot < line.endIndex && line[afterDot] == " "
    }

    private static func extractNumberedItem(_ line: String) -> String? {
        guard isNumberedListItem(line),
              let dot = line.firstIndex(of: "."),
              let afterSpace = line.index(dot, offsetBy: 2, limitedBy: line.endIndex)
        else { return nil }
        return String(line[afterSpace...])
    }

    // MARK: - Safe attributed string (crash-proof)

    /// Convert text with inline markdown to an AttributedString that
    /// carries the correct base font + color so that `Text(...)` can
    /// render inline `**bold**` and `_italic_` correctly without us
    /// applying a `.font()` modifier that would wipe inline traits.
    private func safeAttributedString(_ text: String) -> AttributedString {
        let cleaned = Self.neutralizeDangerousMarkers(text)
        var attr: AttributedString
        if let parsed = try? AttributedString(
            markdown: cleaned,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            attr = parsed
        } else {
            attr = AttributedString(stringLiteral: Self.stripAllMarkers(cleaned))
        }
        // Apply the base font to the entire AttributedString as the
        // container default. Markdown-emitted bold/italic runs keep
        // their own trait overrides on top of this.
        attr.font = AppTheme.Fonts.body(size: fontSize)
        attr.foregroundColor = textColor
        return attr
    }

    /// Same as above but with a custom base font (used for blockquote
    /// bold+italic styling).
    private func safeAttributedString(_ text: String, baseFont: Font, color: Color) -> AttributedString {
        let cleaned = Self.neutralizeDangerousMarkers(text)
        var attr: AttributedString
        if let parsed = try? AttributedString(
            markdown: cleaned,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            attr = parsed
        } else {
            attr = AttributedString(stringLiteral: Self.stripAllMarkers(cleaned))
        }
        attr.font = baseFont
        attr.foregroundColor = color
        return attr
    }

    /// Replace `**_x_**`, `__**x**__`, `**__x__**`, `_**x**_` -> `**x**`
    /// and lone `__y__` -> `y`. Preserves visible content; only changes
    /// dangerous nested or italic-underscore markers. The blockquote
    /// view modifier already applies bold+italic so dropping italic is
    /// visually lossless within blockquotes.
    /// Replace `**_x_**`, `__**x**__`, `**__x__**`, `_**x**_` -> `**x**`
    /// and lone `__y__` -> `y`. Preserves visible content; only changes
    /// dangerous nested or italic-underscore markers. The blockquote
    /// view modifier already applies bold+italic so dropping italic is
    /// visually lossless within blockquotes.
    private static func neutralizeDangerousMarkers(_ text: String) -> String {
        // Apply outer-bold patterns BEFORE __italic__ strip, otherwise
        // `**__x__**` becomes `**_x_**` mid-pipeline (still dangerous).
        let patterns: [(String, String)] = [
            (#"\*\*__([\s\S]*?)__\*\*"#, "**$1**"),
            (#"__\*\*([\s\S]*?)\*\*__"#, "**$1**"),
            (#"\*\*_([\s\S]*?)_\*\*"#,   "**$1**"),
            (#"_\*\*([\s\S]*?)\*\*_"#,   "**$1**"),
            (#"__([\s\S]*?)__"#,          "$1"),
        ]
        var result = text.replacingOccurrences(of: "|", with: "·")
        for (pat, repl) in patterns {
            if let re = try? NSRegularExpression(pattern: pat) {
                let range = NSRange(result.startIndex..., in: result)
                result = re.stringByReplacingMatches(
                    in: result, range: range, withTemplate: repl)
            }
        }
        return result
    }

    /// Strip every markdown emphasis marker from text. Used as the
    /// ultimate fallback when AttributedString parsing fails.
    fileprivate static func stripAllMarkers(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "`", with: "")
    }

    // MARK: - Block renderer

    @ViewBuilder
    private func renderBlock(_ block: Block) -> some View {
        switch block {
        case .header(let level, let text):
            renderHeader(level: level, text: text)

        case .paragraph(let text):
            // Base font + color are baked into the AttributedString by
            // safeAttributedString, so we MUST NOT apply .font() here —
            // doing so would override the inline bold/italic runs from
            // markdown parsing.
            Text(safeAttributedString(text))
                .lineSpacing(6)
                .textSelection(.enabled)

        case .boldLabel(let label, let content):
            renderBoldLabel(label: label, content: content)

        case .bulletList(let items):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items.indices, id: \.self) { idx in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Circle()
                            .fill(AppTheme.Colors.gold.opacity(0.7))
                            .frame(width: 5, height: 5)
                            .offset(y: 1)
                        Text(safeAttributedString(items[idx]))
                            .lineSpacing(6)
                            .textSelection(.enabled)
                    }
                    .padding(.leading, 4)
                }
            }

        case .numberedList(let items):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items.indices, id: \.self) { idx in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(idx + 1).")
                            .foregroundColor(AppTheme.Colors.gold)
                            .font(.system(size: fontSize, weight: .semibold))
                            .frame(minWidth: 20, alignment: .trailing)
                        Text(safeAttributedString(items[idx]))
                            .lineSpacing(6)
                            .textSelection(.enabled)
                    }
                    .padding(.leading, 4)
                }
            }

        case .diamondList(let items):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items.indices, id: \.self) { idx in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("◆")
                            .foregroundColor(AppTheme.Colors.gold)
                            .font(.system(size: fontSize - 2, weight: .semibold))
                        Text(safeAttributedString(items[idx]))
                            .lineSpacing(6)
                            .textSelection(.enabled)
                    }
                    .padding(.leading, 4)
                }
            }

        case .takeaway(let text):
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("→")
                    .foregroundColor(AppTheme.Colors.gold)
                    .font(.system(size: fontSize + 1, weight: .bold))
                Text(safeAttributedString(
                    text,
                    baseFont: AppTheme.Fonts.body(size: fontSize).weight(.medium),
                    color: AppTheme.Colors.gold))
                    .lineSpacing(6)
                    .textSelection(.enabled)
            }
            .padding(.vertical, 4)

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
            // Force the whole blockquote bold+italic via the AttributedString
            // base font. Inline emphasis (if any survives sanitization) keeps
            // its own trait on top.
            Text(safeAttributedString(
                text,
                baseFont: AppTheme.Fonts.body(size: fontSize).bold().italic(),
                color: AppTheme.Colors.textPrimary))
                .lineSpacing(6)
                .textSelection(.enabled)
                .padding(.vertical, 10)
                .padding(.leading, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(AppTheme.Colors.gold)
                        .frame(width: 3)
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
                            AppTheme.Colors.gold.opacity(0),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func renderHeader(level: Int, text: String) -> some View {
        let size: CGFloat = {
            switch level {
            case 1: return fontSize + 6
            case 2: return fontSize + 4
            case 3: return fontSize + 2
            default: return fontSize + 1
            }
        }()
        Text(MarkdownTextView.stripAllMarkers(text))
            .font(.system(size: size, weight: .bold))
            .foregroundColor(AppTheme.Colors.gold)
            .padding(.top, level <= 2 ? 8 : 4)
    }

    @ViewBuilder
    private func renderBoldLabel(label: String, content: String) -> some View {
        if content.isEmpty {
            // Standalone title — gold heading, slightly larger weight.
            Text(MarkdownTextView.stripAllMarkers(label))
                .font(.system(size: fontSize + 1, weight: .bold))
                .foregroundColor(AppTheme.Colors.gold)
                .padding(.top, 4)
        } else {
            // Label + content — gold label on top, body content below.
            VStack(alignment: .leading, spacing: 4) {
                Text(MarkdownTextView.stripAllMarkers(label))
                    .font(AppTheme.Fonts.body(size: fontSize).weight(.bold))
                    .foregroundColor(AppTheme.Colors.gold)
                Text(safeAttributedString(content))
                    .lineSpacing(6)
                    .textSelection(.enabled)
            }
        }
    }

    private func renderTable(headers: [String], rows: [[String]]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                ForEach(headers.indices, id: \.self) { idx in
                    Text(MarkdownTextView.stripAllMarkers(headers[idx]))
                        .font(AppTheme.Fonts.caption(size: fontSize - 2).weight(.bold))
                        .foregroundColor(AppTheme.Colors.gold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    if idx < headers.count - 1 {
                        Rectangle()
                            .fill(AppTheme.Colors.gold.opacity(0.15))
                            .frame(width: 1)
                    }
                }
            }
            .background(AppTheme.Colors.gold.opacity(0.08))

            ForEach(rows.indices, id: \.self) { rowIdx in
                Rectangle()
                    .fill(AppTheme.Colors.gold.opacity(0.15))
                    .frame(height: 1)
                HStack(spacing: 0) {
                    let row = rows[rowIdx]
                    ForEach(row.indices, id: \.self) { colIdx in
                        Text(safeAttributedString(
                            row[colIdx],
                            baseFont: AppTheme.Fonts.caption(size: fontSize - 2),
                            color: AppTheme.Colors.textPrimary))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                        if colIdx < row.count - 1 {
                            Rectangle()
                                .fill(AppTheme.Colors.gold.opacity(0.15))
                                .frame(width: 1)
                        }
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(AppTheme.Colors.gold.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(6)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        MarkdownTextView(content: """
        # Big header

        This is a **paragraph** with _emphasis_ and **bold**.

        ## Section

        - bullet one
        - bullet two with **bold inline**

        1. first
        2. second

        > **_Dangerous nested takeaway pattern that should not crash._**

        > Plain blockquote also works.

        **Label:** content after the label.

        ◆ diamond one
        ◆ diamond two

        → A takeaway in gold.

        ```
        code block lines
        line two
        ```

        | A | B | C |
        |---|---|---|
        | 1 | 2 | 3 |
        | 4 | 5 | 6 |

        ---
        """)
        .padding()
    }
    .background(Color.black)
}
