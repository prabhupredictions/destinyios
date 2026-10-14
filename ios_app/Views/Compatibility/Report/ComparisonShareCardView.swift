import SwiftUI

// MARK: - Comparison Share Card View
/// Square 1080×1080 social media card for sharing multi-partner comparison results.
/// Privacy-safe: shows only rank/score/verdict, no detailed analysis.
/// Mirrors the dark+gold visual language of ShareCardView.
struct ComparisonShareCardView: View {
    let userName: String
    private let displayResults: [ComparisonResult]

    private let goldColor = Color(red: 0.83, green: 0.69, blue: 0.22)

    init(results: [ComparisonResult], userName: String) {
        // Cap at 6 so rows fit comfortably inside 1080×1080
        self.displayResults = Array(results.prefix(6))
        self.userName = userName
    }

    var body: some View {
        ZStack {
            backgroundLayer
            glowLayer
            cornerOrnaments
            mainContent
        }
        .frame(width: 1080, height: 1080)
    }

    // MARK: - Background layers

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.06, blue: 0.10),  // #0B0F19
                Color(red: 0.08, green: 0.10, blue: 0.18),  // #141A2E
                Color(red: 0.04, green: 0.06, blue: 0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var glowLayer: some View {
        RadialGradient(
            colors: [
                goldColor.opacity(0.08),
                Color.clear
            ],
            center: .center,
            startRadius: 80,
            endRadius: 420
        )
    }

    // MARK: - Corner ornaments (mirrors ShareCardView)

    private var cornerOrnaments: some View {
        VStack {
            HStack {
                cornerOrnament(rotation: 0)
                Spacer()
                cornerOrnament(rotation: 90)
            }
            Spacer()
            HStack {
                cornerOrnament(rotation: 270)
                Spacer()
                cornerOrnament(rotation: 180)
            }
        }
        .padding(30)
    }

    // MARK: - Main content

    private var mainContent: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)

            // Logo + wordmark
            Image("logo_gold")
                .resizable()
                .scaledToFit()
                .frame(height: 80)

            Text("destiny_ai_astrology_brand".localized)
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundColor(goldColor)
                .tracking(6)
                .padding(.top, 8)

            Spacer().frame(height: 24)

            // Card title + user subtitle
            Text("comparison_share_card_title".localized)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .tracking(2)

            Text(String(format: "comparison_share_card_for_format".localized, userName))
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundColor(goldColor.opacity(0.8))
                .padding(.top, 4)

            Spacer().frame(height: 16)

            goldDivider
                .padding(.horizontal, 80)

            Spacer().frame(height: 16)

            // Ranked list
            VStack(spacing: 0) {
                ForEach(Array(displayResults.enumerated()), id: \.element.id) { index, result in
                    rankedRow(rank: index + 1, result: result)
                    if index < displayResults.count - 1 {
                        Rectangle()
                            .fill(goldColor.opacity(0.12))
                            .frame(height: 1)
                            .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.horizontal, 60)

            Spacer()

            // Footer
            VStack(spacing: 6) {
                goldDivider
                    .padding(.horizontal, 60)

                Text("destinyaiastrology.com")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(goldColor.opacity(0.6))
                    .tracking(2)
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Ranked row

    private func rankedRow(rank: Int, result: ComparisonResult) -> some View {
        HStack(spacing: 0) {
            // Rank number
            Text("\(rank)")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(goldColor)
                .frame(width: 60, alignment: .center)

            // Name + rating label
            VStack(alignment: .leading, spacing: 3) {
                Text(result.partner.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(rowRatingText(for: result).uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(
                        result.isRecommended
                            ? goldColor.opacity(0.75)
                            : Color(red: 0.95, green: 0.35, blue: 0.35).opacity(0.75)
                    )
                    .tracking(2)
            }

            Spacer()

            // Stars
            HStack(spacing: 3) {
                ForEach(0 ..< 5) { i in
                    Image(systemName: i < rowStarCount(for: result) ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundColor(goldColor)
                }
            }
            .padding(.trailing, 10)

            // Score
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(result.adjustedScore)")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Text("/\(result.maxScore)")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(goldColor.opacity(0.7))
            }
            .frame(width: 70, alignment: .trailing)

            // Recommended indicator
            Image(systemName: result.isRecommended ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(
                    result.isRecommended
                        ? goldColor
                        : Color(red: 0.95, green: 0.35, blue: 0.35)
                )
                .frame(width: 44)
        }
        .frame(height: 88)
        .padding(.horizontal, 20)
    }

    // MARK: - Star / rating helpers (mirrors ShareCardView logic)

    private func rowStarCount(for result: ComparisonResult) -> Int {
        if !result.isRecommended { return 1 }
        let pct = result.adjustedPercentage * 100
        if pct >= 90 { return 5 }
        else if pct >= 75 { return 4 }
        else if pct >= 60 { return 3 }
        else if pct >= 50 { return 2 }
        else { return 1 }
    }

    private func rowRatingText(for result: ComparisonResult) -> String {
        if !result.isRecommended { return "not_recommended".localized }
        let pct = result.adjustedPercentage * 100
        if pct >= 90 { return "excellent".localized }
        else if pct >= 75 { return "very_good".localized }
        else if pct >= 60 { return "good".localized }
        else if pct >= 50 { return "average".localized }
        else { return "not_recommended".localized }
    }

    // MARK: - Shared helper views

    private var goldDivider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        goldColor.opacity(0),
                        goldColor.opacity(0.5),
                        goldColor.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }

    private func cornerOrnament(rotation: Double) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 30))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 30, y: 0))
        }
        .stroke(goldColor.opacity(0.4), lineWidth: 2)
        .frame(width: 30, height: 30)
        .rotationEffect(.degrees(rotation))
    }
}

#Preview {
    ComparisonShareCardView(
        results: [],
        userName: "Prabhu"
    )
    .previewLayout(.fixed(width: 540, height: 540))
}
