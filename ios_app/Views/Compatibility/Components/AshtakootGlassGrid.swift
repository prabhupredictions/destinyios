import SwiftUI

struct AshtakootData {
    let key: String
    let label: String
    let icon: String // SF Symbol
    let score: Double
    let maxScore: Double
    let description: String
    
    // V2.1 — Cancellation data
    var doshaPresent: Bool = false
    var doshaCancelled: Bool = false
    var cancellationReason: String? = nil
    var cancellationReasons: [String]? = nil
    var adjustedScore: Double? = nil
    
    // V2.2 — Nadi transparency fields
    var doshaType: String? = nil
    var classicalEffect: String? = nil
    var boyConstitution: NadiConstitution? = nil
    var girlConstitution: NadiConstitution? = nil
    
    // V2.2 — Bhakoot transparency fields
    var severity: String? = nil
    var fieldStudy: String? = nil
    var housePositions: String? = nil
    var sadbhakootWarning: String? = nil
    
    // V2.2 — Tara transparency fields
    var taraBoyToGirl: Int? = nil
    var taraGirlToBoy: Int? = nil
    
    // V2.2 — Vashya transparency fields
    var boyVashya: String? = nil
    var girlVashya: String? = nil
    var boyToGirlScore: Double? = nil
    var girlToBoyScore: Double? = nil
    
    // V2.3 — Varna transparency fields
    var boyVarna: String? = nil
    var girlVarna: String? = nil
    var complementarityNote: String? = nil
    
    // V2.4 — Universal partner values
    var boyValue: String? = nil
    var girlValue: String? = nil
    
    /// Effective score after cancellation (adjusted if available, else raw)
    var effectiveScore: Double {
        adjustedScore ?? score
    }
    
    var statusColor: Color {
        // V2.1 — Cancellation-aware coloring
        // Cancelled dosha: green (restored to max)
        // Active dosha: red (0 points, not cancelled)
        // No dosha: ratio-based
        
        if doshaPresent && doshaCancelled {
            return AppTheme.Colors.success  // Green — dosha was cancelled
        }
        if doshaPresent && !doshaCancelled {
            return .red  // Active dosha
        }
        
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
    
    // Semantic Map (v4)
    private let semantics: [String: (label: String, icon: String)] = [
        "varna": ("kuta_varna_label".localized, "briefcase.fill"),
        "vashya": ("kuta_vashya_label".localized, "bolt.heart.fill"),
        "tara": ("kuta_tara_label".localized, "star.fill"),
        "yoni": ("kuta_yoni_label".localized, "flame.fill"),
        "maitri": ("kuta_maitri_label".localized, "person.2.fill"),
        "gana": ("kuta_gana_label".localized, "theatermasks.fill"),
        "bhakoot": ("kuta_bhakoot_label".localized, "heart.circle.fill"),
        "nadi": ("kuta_nadi_label".localized, "waveform.path.ecg")
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
            Text("ashtakoot_analysis_title".localized)
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
                 
                 Text("\("score".localized): \(item.score.formatted()) / \(item.maxScore.formatted())")
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
