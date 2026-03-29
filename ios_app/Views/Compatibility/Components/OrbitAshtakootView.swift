import SwiftUI

struct OrbitAshtakootView: View {
    let kutas: [KutaDetail]
    let centerView: () -> AnyView // Closure to render the central gauge
    var boyName: String = "Boy"
    var girlName: String = "Girl"
    var doshaSummary: DoshaSummary? = nil  // V2.1: Cancellation data
    var onClassicalAnalysis: ((String) -> Void)? = nil

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
                girlValue: detail?.girlValue,
                plainEnglishSummary: detail?.plainEnglishSummary,
                boyValueDescription: detail?.boyValueDescription,
                girlValueDescription: detail?.girlValueDescription
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

    // MARK: - Tooltip View

    @ViewBuilder
    private func kutaTooltipView(kuta: AshtakootData) -> some View {
        let kutaName = kutaDisplayName(for: kuta.key)

        VStack(alignment: .leading, spacing: 10) {
            tooltipHeader(kuta: kuta, kutaName: kutaName)
            Divider().background(AppTheme.Colors.gold.opacity(0.2))
            tooltipDescription(kuta: kuta)
            Divider().background(AppTheme.Colors.gold.opacity(0.2))
            classicalAnalysisCTA(kuta: kuta)
        }
        .padding(14)
        .frame(width: 300, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            ZStack {
                AppTheme.Colors.mainBackground
                RadialGradient(
                    colors: [AppTheme.Colors.gold.opacity(0.08), Color.clear],
                    center: .topLeading, startRadius: 0, endRadius: 150
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [AppTheme.Colors.gold.opacity(0.6), AppTheme.Colors.gold.opacity(0.2)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: AppTheme.Colors.gold.opacity(0.25), radius: 15, x: 0, y: 8)
    }

    @ViewBuilder
    private func tooltipHeader(kuta: AshtakootData, kutaName: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: kuta.icon)
                .font(.system(size: 22))
                .foregroundColor(kuta.statusColor)
                .shadow(color: kuta.statusColor.opacity(0.6), radius: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(kutaThemeLabel(for: kuta.key))
                    .font(AppTheme.Fonts.title(size: 17))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("\(kutaName) Koota · \(format(kuta.score))/\(format(kuta.maxScore))")
                    .font(AppTheme.Fonts.caption(size: 10))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()
            scoreBadge(kuta: kuta)

            Button(action: { withAnimation { selectedKuta = nil } }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .font(.system(size: 20))
            }
        }
    }

    @ViewBuilder
    private func scoreBadge(kuta: AshtakootData) -> some View {
        if kuta.doshaPresent && !kuta.doshaCancelled {
            Text("⚠ Dosha Active")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(AppTheme.Colors.error)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(AppTheme.Colors.error.opacity(0.15)))
        } else if kuta.doshaPresent && kuta.doshaCancelled {
            Text("✓ Cancelled")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(AppTheme.Colors.gold)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(AppTheme.Colors.gold.opacity(0.15)))
        } else {
            Text("✓ \(format(kuta.score))/\(format(kuta.maxScore))")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(AppTheme.Colors.success)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(AppTheme.Colors.success.opacity(0.15)))
        }
    }

    @ViewBuilder
    private func tooltipDescription(kuta: AshtakootData) -> some View {
        Text(KutaTextBuilder(kuta: kuta, boyName: boyName, girlName: girlName).descriptionParagraph())
            .font(AppTheme.Fonts.body(size: 13))
            .foregroundColor(AppTheme.Colors.textSecondary)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func classicalAnalysisCTA(kuta: AshtakootData) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { selectedKuta = nil }
            onClassicalAnalysis?(
                KutaTextBuilder(kuta: kuta, boyName: boyName, girlName: girlName).classicalPrompt()
            )
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "scroll.fill")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.Colors.gold)
                Text("see_classical_analysis".localized)
                    .font(AppTheme.Fonts.caption(size: 12).weight(.medium))
                    .foregroundColor(AppTheme.Colors.gold)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.Colors.gold.opacity(0.6))
            }
        }
    }

    // MARK: - Helpers

    private func kutaDisplayName(for key: String) -> String {
        let names: [String: String] = [
            "varna": "Varna",
            "vashya": "Vashya",
            "tara": "Tara",
            "yoni": "Yoni",
            "maitri": "Graha Maitri",
            "gana": "Gana",
            "bhakoot": "Bhakoot",
            "nadi": "Nadi"
        ]
        return names[key] ?? key.capitalized
    }

    private func kutaThemeLabel(for key: String) -> String {
        let themes: [String: String] = [
            "varna": "Work compatibility",
            "vashya": "Attraction and influence",
            "tara": "Destiny and fortune",
            "yoni": "Intimacy and physical",
            "maitri": "Mental and friendship",
            "gana": "Temperament",
            "bhakoot": "Love and emotional",
            "nadi": "Health and progeny"
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
