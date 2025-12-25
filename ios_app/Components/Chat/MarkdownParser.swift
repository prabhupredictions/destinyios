import SwiftUI

// MARK: - Section Header Configuration
// Easy to extend: just add new cases and their icon/color!
// Comprehensive list of headers used by ChatGPT, Gemini, Claude, and AI models

/// Known section headers for premium styled rendering
enum SectionHeader: String, CaseIterable {
    // Astrology-specific headers
    case verdict = "VERDICT"
    case timing = "TIMING"
    case rationale = "RATIONALE"
    case challenges = "CHALLENGES"
    case compatibility = "COMPATIBILITY"
    case prediction = "PREDICTION"
    case horoscope = "HOROSCOPE"
    case planetary = "PLANETARY"
    case transit = "TRANSIT"
    case dasha = "DASHA"
    case remedies = "REMEDIES"
    case favorable = "FAVORABLE"
    case unfavorable = "UNFAVORABLE"
    
    // Common AI response headers (ChatGPT/Gemini style)
    case summary = "SUMMARY"
    case overview = "OVERVIEW"
    case introduction = "INTRODUCTION"
    case conclusion = "CONCLUSION"
    case analysis = "ANALYSIS"
    case insights = "INSIGHTS"
    case recommendation = "RECOMMENDATION"
    case recommendations = "RECOMMENDATIONS"
    case advice = "ADVICE"
    case suggestion = "SUGGESTION"
    case suggestions = "SUGGESTIONS"
    
    // Instructional headers
    case steps = "STEPS"
    case howTo = "HOW TO"
    case instructions = "INSTRUCTIONS"
    case procedure = "PROCEDURE"
    case method = "METHOD"
    case process = "PROCESS"
    case guide = "GUIDE"
    
    // Examples and notes
    case example = "EXAMPLE"
    case examples = "EXAMPLES"
    case note = "NOTE"
    case notes = "NOTES"
    case important = "IMPORTANT"
    case warning = "WARNING"
    case caution = "CAUTION"
    case tip = "TIP"
    case tips = "TIPS"
    case hint = "HINT"
    
    // Evaluation headers
    case pros = "PROS"
    case cons = "CONS"
    case benefits = "BENEFITS"
    case drawbacks = "DRAWBACKS"
    case advantages = "ADVANTAGES"
    case disadvantages = "DISADVANTAGES"
    case strengths = "STRENGTHS"
    case weaknesses = "WEAKNESSES"
    
    // Content headers
    case keyPoints = "KEY POINTS"
    case highlights = "HIGHLIGHTS"
    case takeaways = "TAKEAWAYS"
    case keyTakeaways = "KEY TAKEAWAYS"
    case considerations = "CONSIDERATIONS"
    case factors = "FACTORS"
    case features = "FEATURES"
    case requirements = "REQUIREMENTS"
    
    // Answer/Response headers
    case answer = "ANSWER"
    case response = "RESPONSE"
    case result = "RESULT"
    case results = "RESULTS"
    case outcome = "OUTCOME"
    case solution = "SOLUTION"
    case explanation = "EXPLANATION"
    
    // Context headers
    case background = "BACKGROUND"
    case context = "CONTEXT"
    case definition = "DEFINITION"
    case meaning = "MEANING"
    case description = "DESCRIPTION"
    case details = "DETAILS"
    
    // Action headers  
    case action = "ACTION"
    case actions = "ACTIONS"
    case nextSteps = "NEXT STEPS"
    case todo = "TODO"
    case tasks = "TASKS"
    
    /// Icon for the section header
    var icon: String {
        switch self {
        // Astrology
        case .verdict: return "⚖️"
        case .timing: return "⏰"
        case .rationale: return "📖"
        case .challenges: return "⚠️"
        case .compatibility: return "❤️"
        case .prediction: return "🌟"
        case .horoscope: return "🔮"
        case .planetary: return "🪐"
        case .transit: return "🌙"
        case .dasha: return "⏳"
        case .remedies: return "💎"
        case .favorable: return "✅"
        case .unfavorable: return "❌"
        
        // Common
        case .summary, .overview, .conclusion: return "✨"
        case .introduction, .background, .context: return "📋"
        case .analysis, .insights: return "📊"
        case .recommendation, .recommendations, .advice, .suggestion, .suggestions: return "💡"
        
        // Instructional
        case .steps, .howTo, .instructions, .procedure, .method, .process, .guide: return "�"
        
        // Examples/Notes
        case .example, .examples: return "💬"
        case .note, .notes, .hint: return "📌"
        case .important, .warning, .caution: return "⚠️"
        case .tip, .tips: return "💡"
        
        // Evaluation
        case .pros, .benefits, .advantages, .strengths, .favorable: return "✅"
        case .cons, .drawbacks, .disadvantages, .weaknesses: return "❌"
        
        // Content
        case .keyPoints, .highlights, .takeaways, .keyTakeaways: return "�"
        case .considerations, .factors: return "🤔"
        case .features, .requirements: return "�"
        
        // Answer
        case .answer, .response, .result, .results, .outcome, .solution: return "✅"
        case .explanation, .definition, .meaning, .description, .details: return "�"
        
        // Action
        case .action, .actions, .nextSteps, .todo, .tasks: return "🎬"
        }
    }
    
    /// Color for the section header
    var color: Color {
        switch self {
        // Gold for key insights
        case .verdict, .summary, .recommendation, .recommendations, .prediction,
             .answer, .solution, .result, .results, .outcome, .keyPoints, 
             .highlights, .takeaways, .keyTakeaways, .conclusion:
            return Color("GoldAccent")
        
        // Orange for warnings/caution
        case .challenges, .warning, .caution, .important, .unfavorable:
            return Color.orange
        
        // Pink for relationships
        case .compatibility:
            return Color.pink
            
        // Green for positive
        case .pros, .benefits, .advantages, .strengths, .favorable:
            return Color.green
            
        // Red for negative
        case .cons, .drawbacks, .disadvantages, .weaknesses:
            return Color.red
        
        // Navy for everything else
        default:
            return Color("NavyPrimary")
        }
    }
    
    /// Check if a line starts with this header
    func matches(_ line: String) -> Bool {
        let patterns = [
            "**\(rawValue):**",
            "**\(rawValue.capitalized):**",
            "**\(rawValue.lowercased()):**"
        ]
        return patterns.contains { line.hasPrefix($0) }
    }
    
    /// Extract content after the header
    func extractContent(from line: String) -> String {
        let patterns = [
            "**\(rawValue):**",
            "**\(rawValue.capitalized):**",
            "**\(rawValue.lowercased()):**"
        ]
        for pattern in patterns {
            if line.hasPrefix(pattern) {
                return String(line.dropFirst(pattern.count)).trimmingCharacters(in: .whitespaces)
            }
        }
        return line
    }
}

// MARK: - Parsed Section
struct ParsedSection: Identifiable {
    let id = UUID()
    let header: SectionHeader?
    let content: String
    
    var isStyledSection: Bool {
        header != nil
    }
}

// MARK: - Markdown Parser
/// Parses AI response text into styled sections and regular markdown
struct MarkdownParser {
    
    /// Parse text into sections (styled headers + regular content)
    static func parse(_ text: String) -> [ParsedSection] {
        var sections: [ParsedSection] = []
        var currentContent = ""
        var currentHeader: SectionHeader? = nil
        
        let lines = text.components(separatedBy: "\n")
        
        for line in lines {
            // Check if this line starts a new section
            if let matchedHeader = findMatchingHeader(line) {
                // Save previous content if any
                if !currentContent.isEmpty || currentHeader != nil {
                    sections.append(ParsedSection(
                        header: currentHeader,
                        content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines)
                    ))
                }
                
                // Start new section
                currentHeader = matchedHeader
                currentContent = matchedHeader.extractContent(from: line)
                if !currentContent.isEmpty {
                    currentContent += "\n"
                }
            } else {
                // Continue current section
                currentContent += line + "\n"
            }
        }
        
        // Don't forget the last section
        if !currentContent.isEmpty || currentHeader != nil {
            sections.append(ParsedSection(
                header: currentHeader,
                content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
        }
        
        return sections.filter { !$0.content.isEmpty || $0.header != nil }
    }
    
    /// Find matching header for a line
    private static func findMatchingHeader(_ line: String) -> SectionHeader? {
        for header in SectionHeader.allCases {
            if header.matches(line) {
                return header
            }
        }
        return nil
    }
    
    /// Check if text contains any known section headers
    static func hasStyledSections(_ text: String) -> Bool {
        for header in SectionHeader.allCases {
            if text.contains("**\(header.rawValue):**") ||
               text.contains("**\(header.rawValue.capitalized):**") {
                return true
            }
        }
        return false
    }
}

// MARK: - Styled Section View
/// Renders a single section with optional styled header
struct StyledSectionView: View {
    let section: ParsedSection
    let textColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Styled header if present
            if let header = section.header {
                HStack(spacing: 8) {
                    Text(header.icon)
                        .font(.system(size: 14))
                    
                    Text(header.rawValue)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(header.color)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                .padding(.bottom, 2)
            }
            
            // Content with markdown support
            if let attrString = try? AttributedString(
                markdown: section.content,
                options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            ) {
                Text(attrString)
                    .font(.system(size: 15))
                    .foregroundColor(textColor)
                    .textSelection(.enabled)
            } else {
                Text(section.content)
                    .font(.system(size: 15))
                    .foregroundColor(textColor)
                    .textSelection(.enabled)
            }
        }
    }
}

// MARK: - Full Message Renderer
/// Renders complete message with styled sections
struct StyledMarkdownView: View {
    let content: String
    let textColor: Color
    
    private var sections: [ParsedSection] {
        MarkdownParser.parse(content)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(sections) { section in
                StyledSectionView(section: section, textColor: textColor)
                
                // Add divider between styled sections (not after last)
                if section.isStyledSection && section.id != sections.last?.id {
                    Divider()
                        .background(Color("NavyPrimary").opacity(0.1))
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Styled Sections") {
    VStack(spacing: 20) {
        StyledMarkdownView(
            content: """
            **VERDICT:** Likely Positive Experience Tomorrow (Medium Probability)
            
            **TIMING:** The favorable influences are most prominent during the morning hours.
            
            **RATIONALE:** The Moon, placed in the 6th house in Scorpio, indicates a day focused on overcoming challenges. The strong Shadbala suggests an ability to navigate difficulties effectively.
            
            **CHALLENGES:** Despite the overall positive outlook, the Moon's debilitation may lead to emotional sensitivity.
            """,
            textColor: Color("NavyPrimary")
        )
        .padding()
        .background(Color.white)
        .cornerRadius(18)
    }
    .padding()
    .background(Color(red: 0.96, green: 0.95, blue: 0.98))
}

#Preview("Regular Markdown") {
    StyledMarkdownView(
        content: "The Moon is in a favorable position. You should focus on **relationships** and **career** decisions this week.",
        textColor: Color("NavyPrimary")
    )
    .padding()
    .background(Color.white)
    .cornerRadius(18)
    .padding()
}
