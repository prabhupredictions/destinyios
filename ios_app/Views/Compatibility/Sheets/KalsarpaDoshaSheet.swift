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
    
    @State private var animateSnake: Bool = false
    @State private var animateOrbit: Bool = false
    
    // MARK: - Scenario Logic
    
    enum KalsarpaScenario {
        case none
        case one(isBoy: Bool)
        case both
    }
    
    private var scenario: KalsarpaScenario {
        let boyHas = boyData?.isPresent == true
        let girlHas = girlData?.isPresent == true
        
        if boyHas && girlHas { return .both }
        if boyHas { return .one(isBoy: true) }
        if girlHas { return .one(isBoy: false) }
        return .none
    }
    
    var body: some View {
        ZStack {
            // Background
            CosmicBackgroundView()
                .ignoresSafeArea()
            
            // Subtle star field effect
            starFieldOverlay
            
            ScrollView {
                VStack(spacing: 24) {
                    switch scenario {
                    case .none:
                        divineProtectionView
                    case .one(let isBoy):
                        singleDoshaView(isBoy: isBoy)
                    case .both:
                        mutualDoshaView
                    }
                }
                .padding()
                .padding(.bottom, 50)
            }
        }
        .navigationTitle("kalsarpa_analysis".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
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
    
    // MARK: - Scenario 1: Divine Protection (None)
    
    private var divineProtectionView: some View {
        VStack(spacing: 30) {
            // Hero
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.success.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                Circle()
                    .stroke(AppTheme.Colors.success.opacity(0.3), lineWidth: 1)
                    .frame(width: 140, height: 140)
                
                Image(systemName: "shield.check.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.Colors.success)
                    .shadow(color: AppTheme.Colors.success.opacity(0.5), radius: 10)
            }
            .padding(.top, 20)
            
            VStack(spacing: 12) {
                Text("kalsarpa_divine_protection_title".localized)
                    .font(AppTheme.Fonts.title(size: 24))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("kalsarpa_divine_protection_message".localized)
                    .font(AppTheme.Fonts.body(size: 16))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .padding(.horizontal)
            
            // Positive Reinforcement Card
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(AppTheme.Colors.gold)
                    Text("kalsarpa_relationship_benefits".localized)
                        .font(AppTheme.Fonts.body(size: 14).weight(.semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    benefitItem(icon: "heart.circle.fill", text: "kalsarpa_emotional_harmony".localized)
                    benefitItem(icon: "arrow.up.circle.fill", text: "kalsarpa_smooth_progression".localized)
                    benefitItem(icon: "sun.max.fill", text: "kalsarpa_positive_energy".localized)
                }
            }
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.black.opacity(0.45))
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.08), location: 0),
                                    .init(color: Color.white.opacity(0.0), location: 0.45)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 8)
            )
        }
    }
    
    private func benefitItem(icon: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(AppTheme.Colors.gold)
            Text(text)
                .font(AppTheme.Fonts.caption(size: 12))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Scenario 2: Single Dosha (One)
    
    private func singleDoshaView(isBoy: Bool) -> some View {
        let affectedName = isBoy ? boyName : girlName
        let affectedData = isBoy ? boyData : girlData
        let safeName = isBoy ? girlName : boyName
        
        return VStack(spacing: 24) {
            // Comparison Card
            HStack(spacing: 0) {
                // Affected Side
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.error.opacity(0.1))
                            .frame(width: 60, height: 60)
                        Text("🐍")
                            .font(.system(size: 30))
                    }
                    Text(affectedName)
                        .font(AppTheme.Fonts.body(size: 14).weight(.semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("kalsarpa_has_dosha".localized)
                        .font(AppTheme.Fonts.caption(size: 11).weight(.bold))
                        .foregroundColor(AppTheme.Colors.error)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.Colors.error.opacity(0.1))
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                
                // Divider
                Rectangle()
                    .fill(AppTheme.Colors.textTertiary.opacity(0.2))
                    .frame(width: 1, height: 80)
                
                // Safe Side
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.success.opacity(0.1))
                            .frame(width: 60, height: 60)
                        Image(systemName: "shield.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.Colors.success)
                    }
                    Text(safeName)
                        .font(AppTheme.Fonts.body(size: 14).weight(.semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("kalsarpa_protected".localized)
                        .font(AppTheme.Fonts.caption(size: 11).weight(.bold))
                        .foregroundColor(AppTheme.Colors.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.Colors.success.opacity(0.1))
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.black.opacity(0.4))
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.06), location: 0),
                                    .init(color: Color.white.opacity(0.0), location: 0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
            )
            
            // Detailed Analysis for Affected Partner
            if let data = affectedData {
                VStack(spacing: 16) {
                    Text(String(format: "kalsarpa_analysis_title".localized, affectedName))
                        .font(AppTheme.Fonts.title(size: 20))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    doshaDetailsCard(data)
                    
                    if let remedies = data.remedies, !remedies.isEmpty {
                        remediesCard(remedies, forName: affectedName)
                    }
                }
            }
        }
    }
    
    // MARK: - Scenario 3: Mutual Dosha (Both)
    
    private var mutualDoshaView: some View {
        VStack(spacing: 24) {
            // Hero
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.gold.opacity(0.1))
                    .frame(width: 140, height: 140)
                
                HStack(spacing: -10) {
                    Text("🐍")
                        .font(.system(size: 50))
                        .scaleEffect(x: -1, y: 1)
                    Text("🐍")
                        .font(.system(size: 50))
                }
            }
            
            VStack(spacing: 12) {
                Text("kalsarpa_mutual_kalsarpa".localized)
                    .font(AppTheme.Fonts.title(size: 24))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("kalsarpa_dosha_samya".localized)
                    .font(AppTheme.Fonts.body(size: 14).weight(.semibold))
                    .foregroundColor(AppTheme.Colors.gold)
                
                Text("kalsarpa_mutual_message".localized)
                    .font(AppTheme.Fonts.body(size: 16))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .padding(.horizontal)
            
            // Partner Details Comparison
            if let bData = boyData, let gData = girlData {
                VStack(spacing: 16) {
                    compactDoshaRow(name: boyName, data: bData)
                    compactDoshaRow(name: girlName, data: gData)
                }
                .padding()
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.black.opacity(0.4))
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.06), location: 0),
                                        .init(color: Color.white.opacity(0.0), location: 0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.08),
                                        Color.white.opacity(0.03)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
                )
                
                // Shared Remedies
                let allRemedies = Array(Set((bData.remedies ?? []) + (gData.remedies ?? []))).prefix(3).map { String($0) }
                if !allRemedies.isEmpty {
                    remediesCard(allRemedies, forName: "Both")
                }
            }
        }
    }
    
    private func compactDoshaRow(name: String, data: KalaSarpaData) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name)
                    .font(AppTheme.Fonts.body(size: 14).weight(.bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(data.displayName)
                    .font(AppTheme.Fonts.caption())
                    .foregroundColor(AppTheme.Colors.gold)
            }
            Spacer()
            statusBadge(text: data.severity?.capitalized ?? "Unknown", color: severityColor(data.severity ?? ""))
        }
        .padding()
        .background(AppTheme.Colors.inputBackground)
        .cornerRadius(10)
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
                        .font(AppTheme.Fonts.body(size: 14))
                }
                Text("dosha_details".localized)
                    .font(AppTheme.Fonts.body(size: 15).weight(.bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
            }
            
            // Dosha Name and Description
            HStack(spacing: 12) {
                Text("🐍")
                    .font(AppTheme.Fonts.title(size: 24))
                
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
                            .font(AppTheme.Fonts.body(size: 14))
                        Text("affected_areas".localized)
                            .font(AppTheme.Fonts.body(size: 13).weight(.semibold))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    FlowLayout(spacing: 8) {
                        ForEach(areas, id: \.self) { area in
                            HStack(spacing: 4) {
                                Text(areaIcon(area))
                                    .font(AppTheme.Fonts.caption(size: 11))
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
                        .font(AppTheme.Fonts.body(size: 16))
                    
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
                            .font(AppTheme.Fonts.body(size: 14))
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
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.45))
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.08), location: 0),
                                .init(color: Color.white.opacity(0.0), location: 0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Remedies Card
    
    // MARK: - Remedies Card
    
    private func remediesCard(_ remedies: [String], forName: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.inputBackground)
                        .frame(width: 32, height: 32)
                    Image(systemName: "sparkles")
                        .foregroundColor(AppTheme.Colors.gold)
                        .font(AppTheme.Fonts.body(size: 14))
                }
                Text(forName != nil ? String(format: "kalsarpa_remedies_for".localized, forName!) : "recommended_remedies".localized)
                    .font(AppTheme.Fonts.body(size: 15).weight(.bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(remedies.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 12) {
                        Text("🙏")
                            .font(AppTheme.Fonts.body(size: 16))
                        
                        Text(remedies[index])
                            .font(AppTheme.Fonts.caption())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
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
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.45))
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.08), location: 0),
                                .init(color: Color.white.opacity(0.0), location: 0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 8)
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
                    .font(AppTheme.Fonts.display(size: 32))
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
