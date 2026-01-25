import SwiftUI

/// Comparison Overview View - Multi-Partner Ranking Screen
/// Shows ranked comparison results for multiple partners
struct ComparisonOverviewView: View {
    let results: [ComparisonResult]
    let userName: String
    var onSelectPartner: (Int) -> Void  // Index of selected partner
    var onBack: () -> Void
    var onNewMatch: () -> Void
    
    // Sorted results by score
    private var sortedResults: [ComparisonResult] {
        results.sorted { $0.overallScore > $1.overallScore }
    }
    
    var body: some View {
        ZStack {
            // Background
            CosmicBackgroundView()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Results List
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(Array(sortedResults.enumerated()), id: \.element.id) { index, result in
                            ComparisonPartnerCard(
                                result: result,
                                rank: index + 1,
                                isTop: index == 0
                            )
                            .onTapGesture {
                                HapticManager.shared.play(.light)
                                // Find original index
                                if let originalIndex = results.firstIndex(where: { $0.id == result.id }) {
                                    onSelectPartner(originalIndex)
                                }
                            }
                        }
                        
                        // New Match Button
                        Button(action: onNewMatch) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                Text("new_match".localized)
                                    .font(AppTheme.Fonts.body(size: 16).weight(.medium))
                            }
                            .foregroundColor(AppTheme.Colors.gold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.Colors.gold.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.Colors.gold)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Title
            HStack(spacing: 8) {
                Image("match_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                
                Text("comparison_results".localized)
                    .font(AppTheme.Fonts.display(size: 22))
                    .foregroundColor(AppTheme.Colors.gold)
            }
            
            // Subtitle
            Text("\(results.count) " + "partners_compared".localized)
                .font(AppTheme.Fonts.body(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            // User reference
            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                Text("comparing_with".localized + " \(userName)")
                    .font(AppTheme.Fonts.caption(size: 12))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}

// MARK: - Comparison Partner Card
struct ComparisonPartnerCard: View {
    let result: ComparisonResult
    let rank: Int
    let isTop: Bool
    
    private var medalEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }
    
    private var statusColor: Color {
        switch result.statusColor {
        case "green": return Color.green
        case "gold": return AppTheme.Colors.gold
        case "orange": return Color.orange
        default: return Color.red
        }
    }
    
    var body: some View {
        DivineGlassCard {
            HStack(spacing: 16) {
                // Rank Badge
                ZStack {
                    if rank <= 3 {
                        Text(medalEmoji)
                            .font(.system(size: 28))
                    } else {
                        Text("#\(rank)")
                            .font(AppTheme.Fonts.title(size: 18).weight(.bold))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                .frame(width: 44)
                
                // Partner Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(result.partner.name)
                        .font(AppTheme.Fonts.title(size: 17).weight(.semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(result.partner.formattedSummary)
                        .font(AppTheme.Fonts.caption(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Score & Status
                VStack(alignment: .trailing, spacing: 4) {
                    // Score
                    HStack(spacing: 4) {
                        Text("\(result.overallScore)")
                            .font(AppTheme.Fonts.display(size: 24))
                            .foregroundColor(AppTheme.Colors.gold)
                        Text("/\(result.maxScore)")
                            .font(AppTheme.Fonts.caption(size: 14))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    
                    // Percentage Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [statusColor.opacity(0.8), statusColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(result.percentage), height: 6)
                        }
                    }
                    .frame(width: 60, height: 6)
                    
                    // Status Label
                    Text(result.statusLabel)
                        .font(AppTheme.Fonts.caption(size: 10))
                        .foregroundColor(statusColor)
                }
            }
            .padding(16)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isTop ? AppTheme.Colors.gold.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    ComparisonOverviewView(
        results: [],
        userName: "John",
        onSelectPartner: { _ in },
        onBack: {},
        onNewMatch: {}
    )
}
