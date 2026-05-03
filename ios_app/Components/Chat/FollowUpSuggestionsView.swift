import SwiftUI

/// Full-width vertical follow-up suggestion rows.
/// Replaces horizontal scroll capsule pills.
struct FollowUpSuggestionsView: View {
    let questions: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(questions.prefix(3).enumerated()), id: \.offset) { index, question in
                Button {
                    onSelect(question)
                } label: {
                    HStack(spacing: 12) {
                        Text("✦")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.Colors.gold.opacity(0.4))
                        Text(question)
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.5))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.15))
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("followup_row_\(index)")

                if index < min(questions.count, 3) - 1 {
                    Divider().background(Color.white.opacity(0.05))
                }
            }
        }
        .padding(.top, 4)
        .accessibilityIdentifier("followup_suggestions_view")
    }
}
