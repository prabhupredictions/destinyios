import Foundation

/// Adversarial markdown fixtures for the streaming path.
///
/// These exercise the FINAL committed message (after .done flips it from
/// StreamingBubbleView → MarkdownTextView). For each fixture, the test
/// verifies that:
///   1. MarkdownTextView renders without crashing.
///   2. isSafeForAttributedString returns true (else plain-Text latch
///      engages and we beacon outcome=sanitizer_fallback).
///
/// Includes every 06156e7 crash pattern in partial-prefix form to ensure
/// truncated streams (Stop button mid-emit) don't poison the markdown
/// parser when later replayed from SwiftData.
enum MarkdownStreamingFixtures {
    static let cases: [(name: String, markdown: String)] = [
        // 1. Closing takeaway (06156e7 pattern — must be safe)
        ("closing_takeaway",
         "Your career will improve.\n\n> **_Stay grounded and patient._**"),

        // 2. Partial closing takeaway — Stop hit mid-emit
        ("partial_takeaway_open",
         "Your career will improve.\n\n> **_"),
        ("partial_takeaway_one_underscore",
         "Your career will improve.\n\n> **_Stay"),
        ("partial_takeaway_unclosed_bold",
         "Your career will improve.\n\n> **_Stay grounded_"),

        // 3. Vedic house notation — must NOT be parsed as headers
        ("house_h1_h2",
         "H1 lord is strong. H2 indicates wealth. H12 suggests rest."),

        // 4. Astrological asterisks
        ("ascendant_marker",
         "(*) Lagna in Gemini at 29°30' Cn."),

        // 5. Code blocks — unclosed mid-stream
        ("unclosed_fence",
         "Here's the analysis:\n```\nTransit Saturn"),
        ("closed_fence",
         "Here's the analysis:\n```\nTransit Saturn\n```"),

        // 6. Nested formatting
        ("bold_italic",
         "**Career: _promotion likely_**"),
        ("italic_in_bold",
         "**bold *italic* bold**"),

        // 7. Tables — atomic block (per contract)
        ("table_atomic",
         "| Period | Effect |\n|--------|--------|\n| Q1 | Strong |\n| Q2 | Mixed |"),

        // 8. Lists
        ("bullet_list",
         "- First\n- Second\n- Third"),
        ("numbered_list",
         "1. First\n2. Second\n3. Third"),

        // 9. Links
        ("safe_link",
         "See [the guide](https://example.com) for context."),

        // 10. Emoji + RTL safety
        ("emoji_only",
         "🌙✨🌟"),
        ("rtl_text",
         "تجربة الكتابة من اليمين"),

        // 11. Dollar sign — must render literally
        ("dollar_sign",
         "Spend below $5,000 this month."),

        // 12. Pound sign in middle of sentence (not a header)
        ("hash_inline",
         "Issue #42 in your chart."),

        // 13. Headers — supported
        ("h2_header",
         "## Career\n\nThe planets are favorable."),

        // 14. Multi-paragraph
        ("multi_paragraph",
         "First insight.\n\nSecond insight.\n\nThird insight.\n\n> **_Pace yourself._**"),

        // 15. Empty content
        ("empty",
         ""),

        // 16. Whitespace-only
        ("whitespace",
         "   \n\n   "),

        // 17. Single character
        ("single_char",
         "A"),

        // 18. Very large message (40 KB cap edge)
        ("near_cap",
         String(repeating: "word ", count: 8000)),  // ~40 KB

        // 19. Special characters
        ("backslash",
         "She said \"hello\\world\" in chat."),
        ("ampersand",
         "Q & A: questions and answers"),

        // 20. Mid-word truncation
        ("mid_word",
         "Your career trajec"),

        // 21. Mixed-script
        ("mixed_script",
         "Vedic insight: జాతకం"),
    ]
}
