import SwiftUI

/// Circular score display with animated progress
struct ScoreCircle: View {
    let score: Int
    let maxScore: Int
    var animate: Bool = true
    
    @State private var animatedProgress: Double = 0
    
    private var progress: Double {
        guard maxScore > 0 else { return 0 }
        return Double(score) / Double(maxScore)
    }
    
    private var scoreColor: Color {
        if progress >= 0.75 {
            return .green
        } else if progress >= 0.5 {
            return Color("GoldAccent")
        } else {
            return .orange
        }
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    Color("NavyPrimary").opacity(0.1),
                    lineWidth: 12
                )
                .frame(width: 140, height: 140)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [scoreColor, scoreColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))
            
            // Score text
            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(Color("NavyPrimary"))
                
                Text("out of \(maxScore)")
                    .font(.system(size: 12))
                    .foregroundColor(Color("TextDark").opacity(0.5))
            }
        }
        .onAppear {
            if animate {
                withAnimation(.easeOut(duration: 1.0)) {
                    animatedProgress = progress
                }
            } else {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Kuta Row
struct KutaRow: View {
    let kuta: KutaDetail
    @State private var animatedProgress: Double = 0
    
    private var progressColor: Color {
        if kuta.percentage >= 0.75 {
            return .green
        } else if kuta.percentage >= 0.5 {
            return Color("GoldAccent")
        } else {
            return .orange
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(kuta.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("NavyPrimary"))
                
                Spacer()
                
                Text("\(kuta.points)/\(kuta.maxPoints)")
                    .font(.system(size: 14))
                    .foregroundColor(Color("TextDark").opacity(0.6))
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color("NavyPrimary").opacity(0.1))
                        .frame(height: 6)
                    
                    // Fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressColor)
                        .frame(width: max(geo.size.width * animatedProgress, 4), height: 6)
                }
            }
            .frame(height: 6)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animatedProgress = kuta.percentage
            }
        }
    }
}

// MARK: - Previews
#Preview("Score Circle") {
    VStack(spacing: 40) {
        ScoreCircle(score: 28, maxScore: 36)
        ScoreCircle(score: 22, maxScore: 36)
        ScoreCircle(score: 15, maxScore: 36)
    }
    .padding()
}

#Preview("Kuta Row") {
    VStack(spacing: 16) {
        KutaRow(kuta: KutaDetail(name: "Nadi", maxPoints: 8, points: 8))
        KutaRow(kuta: KutaDetail(name: "Bhakoot", maxPoints: 7, points: 5))
        KutaRow(kuta: KutaDetail(name: "Gana", maxPoints: 6, points: 2))
    }
    .padding()
}
