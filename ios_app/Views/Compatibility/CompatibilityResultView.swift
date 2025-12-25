import SwiftUI

/// Results view for compatibility analysis
struct CompatibilityResultView: View {
    let result: CompatibilityResult
    let boyName: String
    let girlName: String
    let onNewAnalysis: () -> Void
    
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                AppHeader(
                    title: "Match Result",
                    showMenuButton: false
                )
                
                // Score section
                scoreSection
                
                // Names
                HStack(spacing: 12) {
                    NameBadge(name: boyName, icon: "person.fill")
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color("GoldAccent"))
                    
                    NameBadge(name: girlName, icon: "person.fill")
                }
                
                // Summary card
                summaryCard
                
                // Kuta details
                kutaDetailsCard
                
                // Recommendation
                recommendationCard
                
                // New analysis button
                Button(action: onNewAnalysis) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("New Analysis")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("NavyPrimary"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("NavyPrimary").opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                
                // Spacer for tab bar
                Spacer(minLength: 120)
            }
            .padding(.top, 8)
            .opacity(contentOpacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                contentOpacity = 1.0
            }
        }
    }
    
    // MARK: - Score Section
    private var scoreSection: some View {
        VStack(spacing: 16) {
            ScoreCircle(score: result.totalScore, maxScore: result.maxScore)
            
            // Compatibility level label
            Text(compatibilityLevel)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(levelColor)
            
            Text("\(Int(result.percentage * 100))% compatible")
                .font(.system(size: 14))
                .foregroundColor(Color("TextDark").opacity(0.6))
        }
        .padding(.vertical, 12)
    }
    
    private var compatibilityLevel: String {
        if result.percentage >= 0.75 {
            return "Excellent Match"
        } else if result.percentage >= 0.5 {
            return "Good Match"
        } else {
            return "Moderate Match"
        }
    }
    
    private var levelColor: Color {
        if result.percentage >= 0.75 {
            return .green
        } else if result.percentage >= 0.5 {
            return Color("GoldAccent")
        } else {
            return .orange
        }
    }
    
    // MARK: - Summary Card
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color("GoldAccent"))
                
                Text("Summary")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("NavyPrimary"))
            }
            
            Text(result.summary)
                .font(.system(size: 15))
                .foregroundColor(Color("NavyPrimary"))
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Kuta Details Card
    private var kutaDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color("GoldAccent"))
                
                Text("Ashtakoot Details")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("NavyPrimary"))
            }
            
            VStack(spacing: 14) {
                ForEach(result.kutas) { kuta in
                    KutaRow(kuta: kuta)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Recommendation Card
    private var recommendationCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Recommendation")
                    .font(.system(size: 12))
                    .foregroundColor(Color("TextDark").opacity(0.5))
                
                Text(result.recommendation)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("NavyPrimary"))
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Name Badge
struct NameBadge: View {
    let name: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color("NavyPrimary").opacity(0.6))
            
            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color("NavyPrimary"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("NavyPrimary").opacity(0.08))
        )
    }
}

// MARK: - Preview
#Preview {
    CompatibilityResultView(
        result: CompatibilityResult(
            totalScore: 28,
            maxScore: 36,
            kutas: [
                KutaDetail(name: "Varna", maxPoints: 1, points: 1),
                KutaDetail(name: "Vashya", maxPoints: 2, points: 2),
                KutaDetail(name: "Tara", maxPoints: 3, points: 3),
                KutaDetail(name: "Yoni", maxPoints: 4, points: 3),
                KutaDetail(name: "Graha Maitri", maxPoints: 5, points: 4),
                KutaDetail(name: "Gana", maxPoints: 6, points: 5),
                KutaDetail(name: "Bhakoot", maxPoints: 7, points: 5),
                KutaDetail(name: "Nadi", maxPoints: 8, points: 5)
            ],
            summary: "This is an excellent match with strong compatibility across all major areas. The couple shares deep emotional understanding.",
            recommendation: "Favorable for marriage"
        ),
        boyName: "Vamshi",
        girlName: "Swathi"
    ) {}
}
