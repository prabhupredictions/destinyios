import Foundation

/// Canonical base filename (no extension) for a shared or saved Destiny matching
/// report PDF:
///
///     Destiny_Matching_<You>_<Partner>_<yyyy-MM-dd>
///
/// Matches the Android convention so both platforms produce identical, descriptive
/// report names. Single-partner reports pass the partner's name; multi-partner
/// comparisons pass "Comparison". Each token is sanitized to letters/digits (runs of
/// spaces/punctuation collapse to a single underscore) so the result is filesystem-
/// and share-safe. The date is the report-generation date (today). Callers append
/// the ".pdf" extension.
func destinyMatchingReportBaseName(you: String, partner: String, date: Date = Date()) -> String {
    func slug(_ s: String) -> String {
        let underscored = s.replacingOccurrences(
            of: "[^A-Za-z0-9]+",
            with: "_",
            options: .regularExpression
        )
        let trimmed = underscored.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return trimmed.isEmpty ? "Unknown" : trimmed
    }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return "Destiny_Matching_\(slug(you))_\(slug(partner))_\(formatter.string(from: date))"
}
