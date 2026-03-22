import SwiftUI

struct OrbitAshtakootView: View {
    let kutas: [KutaDetail]
    let centerView: () -> AnyView // Closure to render the central gauge
    var boyName: String = "Boy"
    var girlName: String = "Girl"
    var doshaSummary: DoshaSummary? = nil  // V2.1: Cancellation data
    
    @State private var selectedKuta: AshtakootData?
    @State private var hintVisible: Bool = true
    
    // Semantic Map (v5)
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
    
    // Convert dictionary to ordered array, enriched with cancellation data
    private var orbitItems: [AshtakootData] {
        let order = ["varna", "vashya", "tara", "yoni", "maitri", "gana", "bhakoot", "nadi"]
        
        return order.compactMap { key in
            guard let kuta = kutas.first(where: { $0.name.lowercased().prefix(key.count) == key }) else { return nil }
            let meta = semantics[key] ?? (kuta.name, "circle.fill")
            
            // Enrich with cancellation data from DoshaSummary
            let detail = doshaSummary?.details?[key]
            let doshaPresent = detail?.present ?? false
            let doshaCancelled = detail?.cancelled ?? false
            let reason = detail?.reasonShort
            let reasonsAll = detail?.reasonsAll
            
                        
            // Adjusted score: if cancelled → max points restored, if active dosha → stays 0
            let adjustedScore: Double? = doshaPresent
                ? (doshaCancelled ? Double(kuta.maxPoints) : 0)
                : nil
            
            return AshtakootData(
                key: key,
                label: meta.label,
                icon: meta.icon,
                score: Double(kuta.points),
                maxScore: Double(kuta.maxPoints),
                description: kuta.description,
                doshaPresent: doshaPresent,
                doshaCancelled: doshaCancelled,
                cancellationReason: reason,
                cancellationReasons: reasonsAll,
                adjustedScore: adjustedScore,
                doshaType: detail?.doshaType,
                classicalEffect: detail?.classicalEffect,
                boyConstitution: detail?.boyConstitution,
                girlConstitution: detail?.girlConstitution,
                severity: detail?.severity,
                fieldStudy: detail?.fieldStudy,
                housePositions: detail?.housePositions,
                sadbhakootWarning: detail?.sadbhakootWarning,
                taraBoyToGirl: detail?.taraBoyToGirl,
                taraGirlToBoy: detail?.taraGirlToBoy,
                boyVashya: detail?.boyVashya,
                girlVashya: detail?.girlVashya,
                boyToGirlScore: detail?.boyToGirlScore,
                girlToBoyScore: detail?.girlToBoyScore,
                boyVarna: detail?.boyVarna,
                girlVarna: detail?.girlVarna,
                complementarityNote: detail?.complementarityNote,
                boyValue: detail?.boyValue,
                girlValue: detail?.girlValue
            )
        }
    }
    
    /// Whether any dosha data exists to show indicators
    private var hasDoshaData: Bool {
        orbitItems.contains { $0.doshaPresent }
    }
    
    // Geometry
    private let orbitRadius: CGFloat = 155
    private let bubbleSize: CGFloat = 64
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // 1. Orbital Rings (Decoration)
                Circle()
                    .stroke(AppTheme.Colors.gold.opacity(0.15), lineWidth: 1)
                    .frame(width: orbitRadius * 2, height: orbitRadius * 2)
                
                Circle()
                    .stroke(AppTheme.Colors.gold.opacity(0.05), lineWidth: 40)
                    .frame(width: orbitRadius * 2, height: orbitRadius * 2)
                
                // 2. Center Sun (The Gauge)
                centerView()
                    .frame(width: 180, height: 180)
                    .opacity(selectedKuta == nil ? 1 : 0.3) // Dim when tooltip active
                    .animation(.easeInOut, value: selectedKuta != nil)
                
                // 3. Planet Bubbles
                ForEach(Array(orbitItems.enumerated()), id: \.element.key) { index, item in
                    let angleDeg = Double(index) * (360.0 / 8.0) - 90.0 // Start from Top (-90)
                    let angleRad = CGFloat(angleDeg) * .pi / 180.0
                    
                    PlanetBubble(item: item, isSelected: selectedKuta?.key == item.key) {
                        // Tap handler
                        HapticManager.shared.play(.light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if selectedKuta?.key == item.key {
                                selectedKuta = nil
                            } else {
                                selectedKuta = item
                                hintVisible = false // Hide hint once user taps
                            }
                        }
                    }
                    .offset(
                        x: orbitRadius * cos(angleRad),
                        y: orbitRadius * sin(angleRad)
                    )
                }
                
                // 4. Premium Tooltip Overlay (Center)
                if let kuta = selectedKuta {
                    kutaTooltipView(kuta: kuta)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(100)
                }
            }
            .frame(height: (orbitRadius * 2) + bubbleSize + 20)
            .contentShape(Rectangle())
            .onTapGesture {
                // Tap outside bubbles to dismiss
                if selectedKuta != nil {
                    withAnimation { selectedKuta = nil }
                }
            }
            
        }
    }
    
    // MARK: - Tooltip View (6-Point Structured Format)
    @ViewBuilder
    private func kutaTooltipView(kuta: AshtakootData) -> some View {
        let kutaName = kutaDisplayName(for: kuta.key)
        
        VStack(alignment: .leading, spacing: 10) {
            tooltipHeader(kuta: kuta, kutaName: kutaName)
            tooltipPoints1to3(kuta: kuta, kutaName: kutaName)
            tooltipPoints4to6(kuta: kuta, kutaName: kutaName)
            tooltipComplementarity(kuta: kuta)
        }
        .padding(14)
        .frame(width: 280, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            ZStack {
                AppTheme.Colors.mainBackground
                RadialGradient(
                    colors: [AppTheme.Colors.gold.opacity(0.08), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 150
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [AppTheme.Colors.gold.opacity(0.6), AppTheme.Colors.gold.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: AppTheme.Colors.gold.opacity(0.25), radius: 15, x: 0, y: 8)
    }
    
    // MARK: - Tooltip Sub-sections (split for type-checker)
    
    @ViewBuilder
    private func tooltipHeader(kuta: AshtakootData, kutaName: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: kuta.icon)
                .font(.system(size: 22))
                .foregroundColor(kuta.statusColor)
                .shadow(color: kuta.statusColor.opacity(0.6), radius: 6)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(kuta.label)
                    .font(AppTheme.Fonts.title(size: 17))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(kutaName + " " + "koota_label".localized)
                    .font(AppTheme.Fonts.caption(size: 10))
                    .foregroundColor(AppTheme.Colors.gold)
            }
            
            Spacer()
            
            Button(action: { withAnimation { selectedKuta = nil } }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .font(.system(size: 20))
            }
        }
    }
    
    @ViewBuilder
    private func tooltipPoints1to3(kuta: AshtakootData, kutaName: String) -> some View {
        // ─── 1. What determines it ───
        tooltipRow(
            number: "1",
            icon: "doc.text.magnifyingglass",
            text: String(format: "tooltip_determined_by".localized, kutaThemeName(for: kuta.key), kutaName)
        )
        
        // ─── 2. Partner values ───
        if let bv = kuta.boyValue, !bv.isEmpty, let gv = kuta.girlValue, !gv.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                tooltipRow(
                    number: "2",
                    icon: "person.2.fill",
                    text: "tooltip_partner_values".localized
                )
                partnerValueLine(name: boyName, value: bv)
                partnerValueLine(name: girlName, value: gv)
            }
        }
        
        // ─── 3. Score ───
        tooltipScoreRow(kuta: kuta, kutaName: kutaName)
    }
    
    @ViewBuilder
    private func tooltipScoreRow(kuta: AshtakootData, kutaName: String) -> some View {
        let scoreLabel = kutaName + " " + "tooltip_score_label".localized + ": "
        HStack(alignment: .top, spacing: 6) {
            tooltipNumberBadge("3")
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 10))
                .foregroundColor(AppTheme.Colors.gold)
                .frame(width: 14)
            
            if kuta.doshaPresent, let adj = kuta.adjustedScore, Int(adj) != Int(kuta.score) {
                HStack(spacing: 4) {
                    Text(scoreLabel)
                        .font(AppTheme.Fonts.caption(size: 11))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Text(format(kuta.score))
                        .strikethrough(true)
                        .font(AppTheme.Fonts.caption(size: 11))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8))
                        .foregroundColor(AppTheme.Colors.gold)
                    Text("\(format(adj))/\(format(kuta.maxScore))")
                        .font(AppTheme.Fonts.caption(size: 11).bold())
                        .foregroundColor(kuta.statusColor)
                }
            } else {
                Text(scoreLabel + "\(format(kuta.score))/\(format(kuta.maxScore))")
                    .font(AppTheme.Fonts.caption(size: 11))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    @ViewBuilder
    private func tooltipPoints4to6(kuta: AshtakootData, kutaName: String) -> some View {
        // ─── 4. Dosha present ───
        tooltipDoshaStatus(kuta: kuta, kutaName: kutaName)
        
        // ─── 5. Impact ───
        tooltipImpact(kuta: kuta)
        
        // ─── 6. Exemption / Cancellation ───
        if kuta.doshaPresent {
            tooltipExemption(kuta: kuta)
        }
    }
    
    @ViewBuilder
    private func tooltipDoshaStatus(kuta: AshtakootData, kutaName: String) -> some View {
        if kuta.doshaPresent {
            HStack(alignment: .top, spacing: 6) {
                tooltipNumberBadge("4")
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.Colors.error)
                    .frame(width: 14)
                VStack(alignment: .leading, spacing: 2) {
                    Text(kutaName + " " + "dosha_present_label".localized)
                        .font(AppTheme.Fonts.caption(size: 11).weight(.semibold))
                        .foregroundColor(AppTheme.Colors.error)
                    if let dt = kuta.doshaType, !dt.isEmpty {
                        Text("tooltip_type_label".localized + ": " + dt)
                            .font(AppTheme.Fonts.caption(size: 10))
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                }
            }
        } else {
            tooltipRow(
                number: "4",
                icon: "checkmark.circle.fill",
                text: "tooltip_no_dosha".localized,
                color: AppTheme.Colors.success
            )
        }
    }
    
    @ViewBuilder
    private func tooltipImpact(kuta: AshtakootData) -> some View {
        if kuta.doshaPresent, let effect = kuta.classicalEffect, !effect.isEmpty {
            HStack(alignment: .top, spacing: 6) {
                tooltipNumberBadge("5")
                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.Colors.warning)
                    .frame(width: 14)
                Text(replaceNames(in: effect))
                    .font(AppTheme.Fonts.caption(size: 10).italic())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let study = kuta.fieldStudy, !study.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Color.clear.frame(width: 18, height: 1)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 9))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .frame(width: 14)
                    Text(study)
                        .font(AppTheme.Fonts.caption(size: 9).italic())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    @ViewBuilder
    private func tooltipExemption(kuta: AshtakootData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if kuta.doshaCancelled {
                HStack(alignment: .top, spacing: 6) {
                    tooltipNumberBadge("6")
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Colors.success)
                        .frame(width: 14)
                    Text("tooltip_dosha_exempted".localized)
                        .font(AppTheme.Fonts.caption(size: 11).weight(.semibold))
                        .foregroundColor(AppTheme.Colors.success)
                }
                tooltipCancellationReasons(kuta: kuta)
                tooltipAdjustedScore(kuta: kuta)
            } else {
                HStack(alignment: .top, spacing: 6) {
                    tooltipNumberBadge("6")
                    Image(systemName: "xmark.shield.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Colors.error.opacity(0.7))
                        .frame(width: 14)
                    Text("tooltip_no_exemption".localized)
                        .font(AppTheme.Fonts.caption(size: 11))
                        .foregroundColor(AppTheme.Colors.error.opacity(0.8))
                }
            }
        }
    }
    
    @ViewBuilder
    private func tooltipCancellationReasons(kuta: AshtakootData) -> some View {
        if let reasons = kuta.cancellationReasons, !reasons.isEmpty {
            ForEach(reasons, id: \.self) { reason in
                HStack(alignment: .top, spacing: 6) {
                    Color.clear.frame(width: 18, height: 1)
                    Image(systemName: "arrow.turn.down.right")
                        .font(.system(size: 8))
                        .foregroundColor(AppTheme.Colors.success.opacity(0.6))
                        .frame(width: 14)
                    Text(replaceNames(in: reason))
                        .font(AppTheme.Fonts.caption(size: 10))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } else if let reason = kuta.cancellationReason, !reason.isEmpty {
            HStack(alignment: .top, spacing: 6) {
                Color.clear.frame(width: 18, height: 1)
                Image(systemName: "arrow.turn.down.right")
                    .font(.system(size: 8))
                    .foregroundColor(AppTheme.Colors.success.opacity(0.6))
                    .frame(width: 14)
                Text(replaceNames(in: reason))
                    .font(AppTheme.Fonts.caption(size: 10))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    @ViewBuilder
    private func tooltipAdjustedScore(kuta: AshtakootData) -> some View {
        if let adj = kuta.adjustedScore {
            HStack(alignment: .top, spacing: 6) {
                Color.clear.frame(width: 18, height: 1)
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.Colors.success)
                    .frame(width: 14)
                Text(String(format: "tooltip_adjusted_score".localized, format(adj), format(kuta.maxScore)))
                    .font(AppTheme.Fonts.caption(size: 10).weight(.medium))
                    .foregroundColor(AppTheme.Colors.success)
            }
        }
    }
    
    @ViewBuilder
    private func tooltipComplementarity(kuta: AshtakootData) -> some View {
        if let note = kuta.complementarityNote, !note.isEmpty {
            HStack(alignment: .top, spacing: 6) {
                Color.clear.frame(width: 18, height: 1)
                Image(systemName: "sparkles")
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.Colors.gold)
                    .frame(width: 14)
                Text(note)
                    .font(AppTheme.Fonts.caption(size: 10))
                    .foregroundColor(AppTheme.Colors.gold)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - Tooltip Helper Views
    
    private func tooltipNumberBadge(_ num: String) -> some View {
        Text(num)
            .font(.system(size: 8, weight: .bold, design: .rounded))
            .foregroundColor(AppTheme.Colors.gold)
            .frame(width: 16, height: 16)
            .background(Circle().fill(AppTheme.Colors.gold.opacity(0.15)))
    }
    
    @ViewBuilder
    private func tooltipRow(number: String, icon: String, text: String, color: Color = AppTheme.Colors.textSecondary) -> some View {
        HStack(alignment: .top, spacing: 6) {
            tooltipNumberBadge(number)
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color == AppTheme.Colors.textSecondary ? AppTheme.Colors.gold : color)
                .frame(width: 14)
            Text(text)
                .font(AppTheme.Fonts.caption(size: 11))
                .foregroundColor(color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func partnerValueLine(name: String, value: String) -> some View {
        HStack(spacing: 6) {
            Color.clear.frame(width: 18, height: 1) // indent to align with text
            Image(systemName: "person.fill")
                .font(.system(size: 9))
                .foregroundColor(AppTheme.Colors.gold.opacity(0.6))
                .frame(width: 14)
            Text(name)
                .font(AppTheme.Fonts.caption(size: 10).weight(.semibold))
                .foregroundColor(AppTheme.Colors.textPrimary)
            Text(value)
                .font(AppTheme.Fonts.caption(size: 10))
                .foregroundColor(AppTheme.Colors.textSecondary)
            Spacer()
        }
    }
    
    private func kutaDisplayName(for key: String) -> String {
        let names: [String: String] = [
            "varna": "kuta_varna_label".localized,
            "vashya": "kuta_vashya_label".localized,
            "tara": "kuta_tara_label".localized,
            "yoni": "kuta_yoni_label".localized,
            "maitri": "kuta_maitri_label".localized,
            "gana": "kuta_gana_label".localized,
            "bhakoot": "kuta_bhakoot_label".localized,
            "nadi": "kuta_nadi_label".localized
        ]
        return names[key] ?? key.capitalized
    }
    
    private func kutaThemeName(for key: String) -> String {
        let themes: [String: String] = [
            "varna": "kuta_varna_theme".localized,
            "vashya": "kuta_vashya_theme".localized,
            "tara": "kuta_tara_theme".localized,
            "yoni": "kuta_yoni_theme".localized,
            "maitri": "kuta_maitri_theme".localized,
            "gana": "kuta_gana_theme".localized,
            "bhakoot": "kuta_bhakoot_theme".localized,
            "nadi": "kuta_nadi_theme".localized
        ]
        return themes[key] ?? key.capitalized
    }
    
    private func format(_ value: Double) -> String {
        return value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(value)
    }
    
    /// Replace generic "Boy"/"Girl"/"Groom"/"Bride" with actual partner names
    private func replaceNames(in text: String) -> String {
        text
            .replacingOccurrences(of: "Groom's", with: "\(boyName)'s")
            .replacingOccurrences(of: "Bride's", with: "\(girlName)'s")
            .replacingOccurrences(of: "Groom:", with: "\(boyName):")
            .replacingOccurrences(of: "Bride:", with: "\(girlName):")
            .replacingOccurrences(of: "Groom ", with: "\(boyName) ")
            .replacingOccurrences(of: "Bride ", with: "\(girlName) ")
            .replacingOccurrences(of: "Boy's", with: "\(boyName)'s")
            .replacingOccurrences(of: "Girl's", with: "\(girlName)'s")
            .replacingOccurrences(of: "Boy:", with: "\(boyName):")
            .replacingOccurrences(of: "Girl:", with: "\(girlName):")
            .replacingOccurrences(of: "Boy ", with: "\(boyName) ")
            .replacingOccurrences(of: "Girl ", with: "\(girlName) ")
    }
}

struct PlanetBubble: View {
    let item: AshtakootData
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        let orbSize: CGFloat = 64
        
        Button(action: action) {
            ZStack {
                // 0. Outer ring (static — pulse animation removed for battery optimization)
                Circle()
                    .stroke(
                        item.doshaPresent
                            ? (item.doshaCancelled
                                ? AppTheme.Colors.success.opacity(0.35)
                                : AppTheme.Colors.error.opacity(0.4))
                            : item.statusColor.opacity(0.35),
                        lineWidth: 2
                    )
                    .frame(width: orbSize + 8, height: orbSize + 8)
                    .scaleEffect(1.08)
                
                // 1. Status Glow Aura
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                item.statusColor.opacity(isSelected ? 0.8 : 0.5),
                                item.statusColor.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: orbSize * 0.3,
                            endRadius: orbSize * 0.9
                        )
                    )
                    .frame(width: orbSize * 1.5, height: orbSize * 1.5)
                    .blur(radius: 12)
                
                // 2. Glass Sphere Base
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.18, green: 0.2, blue: 0.26),
                                Color(red: 0.12, green: 0.14, blue: 0.18),
                                Color(red: 0.08, green: 0.1, blue: 0.14).opacity(0.6),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: orbSize * 0.52
                        )
                    )
                    .frame(width: orbSize, height: orbSize)
                
                // 3. Inner Glass Bubble
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.clear,
                                Color.black.opacity(0.2)
                            ],
                            center: UnitPoint(x: 0.35, y: 0.35),
                            startRadius: 0,
                            endRadius: orbSize * 0.45
                        )
                    )
                    .frame(width: orbSize * 0.85, height: orbSize * 0.85)
                
                // 4. Highlight
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            center: UnitPoint(x: 0.25, y: 0.25),
                            startRadius: 0,
                            endRadius: orbSize * 0.3
                        )
                    )
                    .frame(width: orbSize, height: orbSize)
                
                // 5. Gold Ring (Brighter if selected)
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.gold.opacity(isSelected ? 1.0 : 0.6),
                                AppTheme.Colors.gold.opacity(isSelected ? 0.6 : 0.3),
                                AppTheme.Colors.gold.opacity(isSelected ? 0.9 : 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 2 : 1.5
                    )
                    .frame(width: orbSize, height: orbSize)
                
                // 6. Content
                VStack(spacing: 0) {
                    Image(systemName: item.icon)
                        .font(.system(size: 16))
                        .foregroundColor(item.statusColor)
                        .padding(.bottom, 2)
                        .shadow(color: item.statusColor.opacity(0.5), radius: 4)
                    
                    let displayScore = (item.doshaPresent && item.doshaCancelled && item.adjustedScore != nil) ? item.adjustedScore! : item.score
                    Text("\(format(displayScore))/\(format(item.maxScore))")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(item.doshaCancelled ? AppTheme.Colors.success : AppTheme.Colors.goldLight)
                    
                    Text(item.label)
                        .font(AppTheme.Fonts.caption(size: 8))
                        .foregroundColor(.white.opacity(0.9))
                        .textCase(.uppercase)
                        .padding(.top, 1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                // 7. Dosha indicator badge (top-right corner)
                if item.doshaPresent {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: item.doshaCancelled ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(item.doshaCancelled ? AppTheme.Colors.success : AppTheme.Colors.error)
                                .background(
                                    Circle()
                                        .fill(AppTheme.Colors.mainBackground)
                                        .frame(width: 16, height: 16)
                                )
                                .shadow(color: (item.doshaCancelled ? AppTheme.Colors.success : AppTheme.Colors.error).opacity(0.5), radius: 3)
                        }
                        Spacer()
                    }
                    .frame(width: orbSize, height: orbSize)
                }
            }
            .frame(width: 64, height: 64)
            .scaleEffect(isSelected ? 1.1 : 1.0) // Pop effect
        }
    }
    
    private func format(_ value: Double) -> String {
        return value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(value)
    }
}
