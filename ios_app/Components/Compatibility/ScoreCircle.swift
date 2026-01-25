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

// MARK: - Kuta Grid Item (Compact box for grid display)
struct KutaGridItem: View {
    let kuta: KutaDetail
    
    private var backgroundColor: Color {
        let percentage = kuta.percentage
        if percentage >= 0.75 {
            return Color.green.opacity(0.15)
        } else if percentage >= 0.50 {
            return Color("GoldAccent").opacity(0.15)
        } else if percentage >= 0.25 {
            return Color.orange.opacity(0.15)
        } else {
            return Color.red.opacity(0.15)
        }
    }
    
    private var textColor: Color {
        let percentage = kuta.percentage
        if percentage >= 0.75 {
            return Color.green
        } else if percentage >= 0.50 {
            return Color("GoldAccent")
        } else if percentage >= 0.25 {
            return Color.orange
        } else {
            return Color.red
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Score
            Text("\(kuta.points)/\(kuta.maxPoints)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(textColor)
            
            // Name
            Text(kuta.name.uppercased())
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color("TextDark").opacity(0.6))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        )
    }
}

// MARK: - Kuta Grid (4x2 layout)
struct KutaGrid: View {
    let kutas: [KutaDetail]
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(kutas) { kuta in
                KutaGridItem(kuta: kuta)
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
        KutaRow(kuta: KutaDetail(name: "Nadi", maxPoints: 8, points: 8, description: "Health & Genes"))
        KutaRow(kuta: KutaDetail(name: "Bhakoot", maxPoints: 7, points: 5, description: "Love & Happiness"))
        KutaRow(kuta: KutaDetail(name: "Gana", maxPoints: 6, points: 2, description: "Temperament match"))
    }
    .padding()
}

#Preview("Kuta Grid") {
    KutaGrid(kutas: [
        KutaDetail(name: "Varna", maxPoints: 1, points: 1, description: "Work & Ego"),
        KutaDetail(name: "Vashya", maxPoints: 2, points: 1, description: "Dominance"),
        KutaDetail(name: "Tara", maxPoints: 3, points: 0, description: "Destiny"),
        KutaDetail(name: "Yoni", maxPoints: 4, points: 4, description: "Physical compatibility"),
        KutaDetail(name: "Maitri", maxPoints: 5, points: 2, description: "Mental friendship"),
        KutaDetail(name: "Gana", maxPoints: 6, points: 6, description: "Temperament"),
        KutaDetail(name: "Bhakoot", maxPoints: 7, points: 4, description: "Love"),
        KutaDetail(name: "Nadi", maxPoints: 8, points: 4, description: "Health")
    ])
    .padding()
}
