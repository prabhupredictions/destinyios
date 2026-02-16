import SwiftUI

struct AshtakootData {
    let key: String
    let label: String
    let icon: String // SF Symbol
    let score: Double
    let maxScore: Double
    let description: String
    
    var statusColor: Color {
        // Status Color Logic (v3)
        // Red: 0 pts or very low
        // Green: Max or near max
        // Yellow: Average
        
        let ratio = score / maxScore
        
        // Critical failures (Nadi/Bhakoot 0 is always Red)
        if (key.lowercased().contains("nadi") || key.lowercased().contains("bhakoot")) && score == 0 {
            return .red
        }
        
        if ratio == 1.0 || (ratio >= 0.8 && maxScore >= 5) { // Perfect or High
            return .green
        } else if ratio == 0 || ratio < 0.25 { // Fail
            return .red
        } else { // Average
            return .yellow
        }
    }
}

struct AshtakootGlassGrid: View {
    let kutas: [KutaDetail] // Full detail object
    
    // Semantic Map (v3)
    private let semantics: [String: (label: String, icon: String)] = [
        "varna": ("Work & Ego", "briefcase.fill"),
        "vashya": ("Dominance", "bolt.heart.fill"),
        "tara": ("Destiny", "star.fill"),
        "yoni": ("Intimacy", "flame.fill"),
        "maitri": ("Friendship", "person.2.fill"),
        "gana": ("Temperament", "theatermasks.fill"),
        "bhakoot": ("Love", "heart.circle.fill"),
        "nadi": ("Health", "waveform.path.ecg")
    ]
    
    // Convert dictionary to ordered array
    private var gridItems: [AshtakootData] {
        let order = ["varna", "vashya", "tara", "yoni", "maitri", "gana", "bhakoot", "nadi"]
        
        return order.compactMap { key in
            guard let kuta = kutas.first(where: { $0.name.lowercased().prefix(key.count) == key }) else { return nil }
            let meta = semantics[key] ?? (kuta.name, "circle.fill")
            return AshtakootData(
                key: key,
                label: meta.label,
                icon: meta.icon,
                score: Double(kuta.points),
                maxScore: Double(kuta.maxPoints),
                description: kuta.description
            )
        }
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ashtakoot Analysis")
                .font(AppTheme.Fonts.title(size: 16))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(gridItems, id: \.key) { item in
                    GlassPill(item: item)
                }
            }
        }
    }
}

// Subcomponent: Glass Pill
struct GlassPill: View {
    let item: AshtakootData
    @State private var showDetails = false
    
    var body: some View {
        Button(action: {
             HapticManager.shared.play(.light)
             showDetails.toggle()
        }) {
            HStack(spacing: 8) {
                // Status Dot
                Circle()
                    .fill(item.statusColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: item.statusColor.opacity(0.5), radius: 2)
                
                // Icon & Label
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        Text(item.label)
                            .font(AppTheme.Fonts.caption(size: 11).weight(.medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    // Score
                    Text("\(item.score.formatted()) / \(item.maxScore.formatted())")
                        .font(AppTheme.Fonts.body(size: 13).weight(.bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial) // Glass Effect
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(item.statusColor.opacity(0.3), lineWidth: 1)
            )
        }
        .sheet(isPresented: $showDetails) {
            // Placeholder for details sheet
             VStack(spacing: 20) {
                 Capsule()
                     .fill(Color.gray.opacity(0.3))
                     .frame(width: 40, height: 4)
                     .padding(.top, 10)
                 
                 Image(systemName: item.icon)
                     .font(.system(size: 48))
                     .foregroundColor(item.statusColor)
                 
                 Text(item.label)
                     .font(AppTheme.Fonts.display(size: 24))
                 
                 Text("Score: \(item.score.formatted()) / \(item.maxScore.formatted())")
                     .font(AppTheme.Fonts.title(size: 16))
                 
                 Text("Detailed explanation for \(item.label) will appear here.")
                     .font(AppTheme.Fonts.body(size: 14))
                     .multilineTextAlignment(.center)
                     .foregroundColor(AppTheme.Colors.textSecondary)
                     .padding()
                 
                 Spacer()
             }
             .presentationDetents([.fraction(0.4)])
             .background(AppTheme.Colors.mainBackground)
        }
    }
}
