import SwiftUI

/// Multi-Partner Progress View - Shows progress for analyzing multiple partners
/// Displays: Overall progress, completed partners with scores, active partner, pending partners
struct MultiPartnerStreamingView: View {
    @Binding var isVisible: Bool
    let partners: [PartnerData]
    let completedResults: [ComparisonResult]
    let currentPartnerIndex: Int
    let currentStep: AnalysisStep
    let totalPartners: Int
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // Content card
            VStack(spacing: 24) {
                // Header with overall progress
                headerSection
                
                // Progress bar
                overallProgressBar
                
                // Partner list
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(Array(partners.enumerated()), id: \.offset) { index, partner in
                            partnerCard(for: partner, at: index)
                        }
                    }
                }
                .frame(maxHeight: 300)
                
                // Footer
                Text("This may take a few moments...")
                    .font(AppTheme.Fonts.body(size: 13))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.Colors.goldDim.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: AppTheme.Colors.gold.opacity(0.2), radius: 20)
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 20))
                .foregroundColor(AppTheme.Colors.gold)
            
            Text("Comparing \(totalPartners) Partners")
                .font(AppTheme.Fonts.premiumDisplay(size: 20))
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
    
    // MARK: - Overall Progress Bar
    private var overallProgressBar: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Colors.inputBackground)
                        .frame(height: 8)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.gold.opacity(0.8), AppTheme.Colors.gold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progressFraction, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progressFraction)
                }
            }
            .frame(height: 8)
            
            Text("\(completedResults.count)/\(totalPartners) Complete")
                .font(AppTheme.Fonts.caption(size: 12))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
    
    private var progressFraction: CGFloat {
        guard totalPartners > 0 else { return 0 }
        return CGFloat(completedResults.count) / CGFloat(totalPartners)
    }
    
    // MARK: - Partner Card
    @ViewBuilder
    private func partnerCard(for partner: PartnerData, at index: Int) -> some View {
        let isCompleted = completedResults.contains { $0.partner.id == partner.id }
        let isActive = index == currentPartnerIndex && !isCompleted
        let isPending = !isCompleted && !isActive
        
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(isActive ? AppTheme.Colors.gold : AppTheme.Colors.inputBackground)
                    .frame(width: 44, height: 44)
                
                Text(partner.name.prefix(1).uppercased())
                    .font(AppTheme.Fonts.display(size: 18))
                    .foregroundColor(isActive ? AppTheme.Colors.textOnGold : AppTheme.Colors.textPrimary)
                
                // Pulsing ring for active
                if isActive {
                    Circle()
                        .stroke(AppTheme.Colors.gold.opacity(0.5), lineWidth: 2)
                        .frame(width: 52, height: 52)
                        .scaleEffect(1.0)
                        .opacity(0.8)
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: isActive
                        )
                }
            }
            
            // Name + Status
            VStack(alignment: .leading, spacing: 4) {
                Text(partner.name.isEmpty ? "Partner \(index + 1)" : partner.name)
                    .font(AppTheme.Fonts.body(size: 15))
                    .fontWeight(.medium)
                    .foregroundColor(isPending ? AppTheme.Colors.textTertiary : AppTheme.Colors.textPrimary)
                
                if isActive {
                    Text(currentStep.title)
                        .font(AppTheme.Fonts.caption(size: 12))
                        .foregroundColor(AppTheme.Colors.gold)
                } else if isPending {
                    Text("Pending")
                        .font(AppTheme.Fonts.caption(size: 12))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
            
            Spacer()
            
            // Status indicator
            if isCompleted {
                // Checkmark + Score
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.Colors.success)
                    
                    if let result = completedResults.first(where: { $0.partner.id == partner.id }) {
                        Text("\(result.overallScore)/36")
                            .font(AppTheme.Fonts.caption(size: 12))
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(AppTheme.Colors.gold.opacity(0.2))
                            )
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                }
            } else if isActive {
                // Loading spinner
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.gold))
            } else {
                // Clock icon for pending
                Image(systemName: "clock")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isActive 
                        ? AppTheme.Colors.gold.opacity(0.1) 
                        : AppTheme.Colors.inputBackground.opacity(0.5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isActive ? AppTheme.Colors.gold.opacity(0.5) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .opacity(isPending ? 0.6 : 1.0)
    }
}

#Preview {
    MultiPartnerStreamingView(
        isVisible: .constant(true),
        partners: [
            PartnerData(name: "Vamshi", city: "Ranchi"),
            PartnerData(name: "Priya", city: "Mumbai"),
            PartnerData(name: "Meera", city: "Delhi")
        ],
        completedResults: [],
        currentPartnerIndex: 0,
        currentStep: .calculatingCharts,
        totalPartners: 3
    )
}
