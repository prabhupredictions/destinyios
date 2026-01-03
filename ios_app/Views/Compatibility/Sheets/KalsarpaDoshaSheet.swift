//
//  KalsarpaDoshaSheet.swift
//  ios_app
//
//  Premium Kalsarpa Dosha detail sheet with professional design
//

import SwiftUI

struct KalsarpaDoshaSheet: View {
    let boyData: KalaSarpaData?
    let girlData: KalaSarpaData?
    let boyName: String
    let girlName: String
    
    @State private var selectedPartner: Int = 0
    @State private var animateSnake: Bool = false
    @State private var animateOrbit: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    private var currentData: KalaSarpaData? {
        selectedPartner == 0 ? boyData : girlData
    }
    
    private var currentName: String {
        selectedPartner == 0 ? boyName : girlName
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.Colors.mainBackground
                    .ignoresSafeArea()
                
                // Subtle star field effect
                starFieldOverlay
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Partner Picker
                        partnerPicker
                        
                        // Hero Section
                        if let data = currentData {
                            heroSection(data)
                            
                            // Consolidated Dosha Details Card
                            if data.isPresent {
                                doshaDetailsCard(data)
                            }
                            
                            // Remedies (separate card for emphasis)
                            if let remedies = data.remedies, !remedies.isEmpty {
                                remediesCard(remedies)
                            }
                        } else {
                            noDataView
                        }
                    }
                    .padding()
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("kalsarpa_analysis".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.Colors.gold)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(AppTheme.Colors.secondaryBackground))
                            .overlay(Circle().stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1))
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateSnake = true
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                animateOrbit = true
            }
        }
    }
    
    // MARK: - Star Field Overlay
    
    private var starFieldOverlay: some View {
        GeometryReader { geo in
            ForEach(0..<20, id: \.self) { i in
                Circle()
                .fill(Color.white.opacity(Double.random(in: 0.1...0.3)))
                    .frame(width: CGFloat.random(in: 1...2))
                    .position(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: 0...geo.size.height)
                    )
            }
        }
    }
    
    // MARK: - Partner Picker
    
    private var partnerPicker: some View {
        HStack(spacing: 0) {
            ForEach([boyName, girlName].indices, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPartner = index
                    }
                } label: {
                    Text(index == 0 ? boyName : girlName)
                        .font(AppTheme.Fonts.caption(size: 14).weight(.semibold))
                        .foregroundColor(selectedPartner == index ? AppTheme.Colors.mainBackground : AppTheme.Colors.textSecondary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedPartner == index
                            ? AppTheme.Colors.gold
                            : Color.clear
                        )
                }
            }
        }
        .background(AppTheme.Colors.inputBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Hero Section
    
    private func heroSection(_ data: KalaSarpaData) -> some View {
        VStack(spacing: 20) {
            if data.isPresent {
                // Animated snake in cosmic circle
                ZStack {
                    // Orbit
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [AppTheme.Colors.gold.opacity(0.6), AppTheme.Colors.goldDim.opacity(0.3), AppTheme.Colors.gold.opacity(0.6)],
                                center: .center
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(animateOrbit ? 360 : 0))
                    
                    // Inner circle
                    Circle()
                        .fill(AppTheme.Colors.cardBackground)
                        .frame(width: 140, height: 140)
                        .overlay(Circle().stroke(AppTheme.Colors.gold.opacity(0.2), lineWidth: 1))
                    
                    // Snake emoji with animation
                    Text("🐍")
                        .font(.system(size: 56))
                        .scaleEffect(animateSnake ? 1.08 : 0.95)
                        .rotationEffect(.degrees(animateSnake ? 8 : -8))
                }
                
                VStack(spacing: 12) {
                    // Status badge
                    Text("kalsarpa_dosha".localized.uppercased())
                        .font(AppTheme.Fonts.caption(size: 11).weight(.bold))
                        .foregroundColor(AppTheme.Colors.error)
                        .tracking(3)
                    
                    // Main status
                    Text("DETECTED")
                        .font(AppTheme.Fonts.title(size: 24))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    // Yoga Name
                    Text(data.displayName)
                        .font(AppTheme.Fonts.body(size: 18).weight(.bold))
                        .foregroundStyle(AppTheme.Colors.gold)
                    
                    // Completeness & Severity badges
                    HStack(spacing: 12) {
                        if let completeness = data.completeness {
                            statusBadge(text: completeness == "complete" ? "complete_formation".localized : "partial_formation".localized, color: completeness == "complete" ? .orange : .yellow)
                        }
                        
                        if let severity = data.severity, severity != "none" {
                            statusBadge(text: severity.capitalized, color: severityColor(severity))
                        }
                    }
                }
            } else {
                // No Kalsarpa - Positive state
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.Colors.success.opacity(0.5), AppTheme.Colors.success.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 140, height: 140)
                    
                    Text("✨")
                        .font(.system(size: 52))
                        .scaleEffect(animateSnake ? 1.05 : 0.98)
                }
                
                VStack(spacing: 8) {
                    Text("no_kalsarpa".localized.uppercased())
                        .font(AppTheme.Fonts.caption(size: 12).weight(.bold))
                        .foregroundColor(AppTheme.Colors.success)
                        .tracking(2)
                    
                    Text("planets_balanced".localized)
                        .font(AppTheme.Fonts.body(size: 16))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
             RoundedRectangle(cornerRadius: AppTheme.Styles.cornerRadius)
                 .fill(AppTheme.Colors.cardBackground)
                 .overlay(AppTheme.Styles.goldBorder.stroke, in: RoundedRectangle(cornerRadius: AppTheme.Styles.cornerRadius))
        )
    }
    
    private func statusBadge(text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .font(AppTheme.Fonts.caption(size: 11).weight(.medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(AppTheme.Colors.inputBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
    }
    
    // MARK: - Consolidated Dosha Details Card
    
    private func doshaDetailsCard(_ data: KalaSarpaData) -> some View {
        VStack(spacing: 20) {
            // Header - Dosha Details
            HStack {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.inputBackground)
                        .frame(width: 32, height: 32)
                    Image(systemName: "sparkle")
                        .foregroundColor(AppTheme.Colors.gold)
                        .font(.system(size: 14))
                }
                Text("dosha_details".localized)
                    .font(AppTheme.Fonts.body(size: 15).weight(.bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
            }
            
            // Dosha Name and Description
            HStack(spacing: 12) {
                Text("🐍")
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.displayName + " Kala Sarpa")
                        .font(AppTheme.Fonts.body(size: 16).weight(.bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(doshaDescription(data.doshaName ?? data.type ?? ""))
                        .font(AppTheme.Fonts.caption())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(2)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Colors.inputBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.Colors.gold.opacity(0.1), lineWidth: 1))
            
            // Affected Life Areas Section
            if let areas = data.lifeAreas, !areas.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.text.square.fill")
                            .foregroundColor(AppTheme.Colors.gold)
                            .font(.system(size: 14))
                        Text("affected_areas".localized)
                            .font(AppTheme.Fonts.body(size: 13).weight(.semibold))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    FlowLayout(spacing: 8) {
                        ForEach(areas, id: \.self) { area in
                            HStack(spacing: 4) {
                                Text(areaIcon(area))
                                    .font(.system(size: 11))
                                Text(area)
                                    .font(AppTheme.Fonts.caption(size: 11))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.Colors.inputBackground)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            
            // Peak Period Section
            if let period = data.peakPeriod, !period.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(AppTheme.Colors.goldDim)
                        .font(.system(size: 16))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("peak_period".localized)
                            .font(AppTheme.Fonts.caption())
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        Text(period)
                            .font(AppTheme.Fonts.body(size: 14).weight(.bold))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(AppTheme.Colors.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Analysis Notes Section
            if let notes = data.analysisNotes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(AppTheme.Colors.gold)
                            .font(.system(size: 14))
                        Text("analysis_notes".localized)
                            .font(AppTheme.Fonts.body(size: 13).weight(.semibold))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(notes, id: \.self) { note in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(AppTheme.Colors.gold.opacity(0.5))
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 5)
                                
                                Text(note)
                                    .font(AppTheme.Fonts.caption())
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Styles.cornerRadius)
                .fill(AppTheme.Colors.cardBackground)
                .overlay(AppTheme.Styles.goldBorder.stroke, in: RoundedRectangle(cornerRadius: AppTheme.Styles.cornerRadius))
        )
    }
    
    // MARK: - Remedies Card
    
    private func remediesCard(_ remedies: [String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.inputBackground)
                        .frame(width: 32, height: 32)
                    Image(systemName: "sparkles")
                        .foregroundColor(AppTheme.Colors.gold)
                        .font(.system(size: 14))
                }
                Text("recommended_remedies".localized)
                    .font(AppTheme.Fonts.body(size: 15).weight(.bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(remedies.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 12) {
                        Text("🙏")
                            .font(.system(size: 16))
                        
                        Text(remedies[index])
                            .font(AppTheme.Fonts.caption())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.Colors.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.Colors.gold.opacity(0.1), lineWidth: 1))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Styles.cornerRadius)
                .fill(AppTheme.Colors.cardBackground)
                .overlay(AppTheme.Styles.goldBorder.stroke, in: RoundedRectangle(cornerRadius: AppTheme.Styles.cornerRadius))
        )
    }
    
    // MARK: - No Data View
    
    private var noDataView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.inputBackground)
                    .frame(width: 80, height: 80)
                Image(systemName: "questionmark")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            
            Text("no_kalsarpa_data".localized)
                .font(AppTheme.Fonts.body(size: 16))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(50)
    }
    
    // MARK: - Helpers
    
    private func severityColor(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "mild": return .yellow
        case "moderate": return .orange
        case "severe": return .red
        default: return .gray
        }
    }
    
    private func planetEmoji(_ abbr: String) -> String {
        switch abbr.lowercased() {
        case "su", "sun": return "☀️"
        case "mo", "moon": return "🌙"
        case "ma", "mars": return "🔴"
        case "me", "mercury": return "⚡"
        case "ju", "jupiter": return "🟡"
        case "ve", "venus": return "💕"
        case "sa", "saturn": return "🪐"
        case "ra", "rahu": return "🐍"
        case "ke", "ketu": return "☄️"
        default: return "⭐"
        }
    }
    
    private func planetFullName(_ abbr: String) -> String {
        switch abbr.lowercased() {
        case "su", "sun": return "Sun"
        case "mo", "moon": return "Moon"
        case "ma", "mars": return "Mars"
        case "me", "mercury": return "Mercury"
        case "ju", "jupiter": return "Jupiter"
        case "ve", "venus": return "Venus"
        case "sa", "saturn": return "Saturn"
        default: return abbr
        }
    }
    
    private func areaIcon(_ area: String) -> String {
        switch area.lowercased() {
        case "mother": return "👩"
        case "home": return "🏠"
        case "emotions": return "💭"
        case "career": return "💼"
        case "health": return "❤️"
        case "wealth": return "💰"
        case "marriage": return "💒"
        case "children": return "👶"
        case "education": return "📚"
        default: return "•"
        }
    }
    
    private func doshaDescription(_ name: String) -> String {
        switch name.lowercased() {
        case "shankhapal", "shankhpal": return "Affects family harmony and maternal relationships"
        case "ananta", "anant": return "Influences spiritual growth and liberation"
        case "kulik": return "Creates obstacles in career and professional life"
        case "vasuki": return "Impacts wealth and financial stability"
        case "padam", "padma": return "Affects marriage and partnerships"
        case "mahapadam", "maha padma": return "Influences overall life direction"
        case "takshak": return "Creates sudden changes and transformations"
        case "karkotak": return "Impacts health and vitality"
        case "sheshnag", "shesh": return "Affects longevity and deep subconscious"
        case "ghatak": return "Creates hidden enemies and obstacles"
        case "vishdhar": return "Influences communication and expression"
        case "shankachood": return "Affects father and dharma"
        default: return "A powerful serpent dosha affecting life path"
        }
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }
        
        return (CGSize(width: maxWidth, height: y + maxHeight), positions)
    }
}

#Preview {
    KalsarpaDoshaSheet(
        boyData: nil,
        girlData: nil,
        boyName: "Partner A",
        girlName: "Partner B"
    )
}
