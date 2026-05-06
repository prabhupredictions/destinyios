import SwiftUI

/// Results view for compatibility analysis - Compact Premium Design (v3)
struct CompatibilityResultView: View {
    let result: CompatibilityResult
    let boyName: String
    let girlName: String
    let boyDob: String?
    let girlDob: String?
    let boyCity: String?
    let girlCity: String?
    let onNewAnalysis: () -> Void
    let onBack: (() -> Void)?
    let onHistory: (() -> Void)?
    let onCharts: (() -> Void)?
    let onLoadHistory: ((CompatibilityHistoryItem) -> Void)?
    var isFromComparison: Bool = false  // true when opened from multi-partner comparison overview

    init(result: CompatibilityResult, boyName: String, girlName: String,
         boyDob: String?, girlDob: String?, boyCity: String?, girlCity: String?,
         onNewAnalysis: @escaping () -> Void,
         onBack: (() -> Void)?,
         onHistory: (() -> Void)?,
         onCharts: (() -> Void)?,
         onLoadHistory: ((CompatibilityHistoryItem) -> Void)?,
         isFromComparison: Bool = false) {
        self.result = result
        self.boyName = boyName
        self.girlName = girlName
        self.boyDob = boyDob
        self.girlDob = girlDob
        self.boyCity = boyCity
        self.girlCity = girlCity
        self.onNewAnalysis = onNewAnalysis
        self.onBack = onBack
        self.onHistory = onHistory
        self.onCharts = onCharts
        self.onLoadHistory = onLoadHistory
        self.isFromComparison = isFromComparison
    }
    
    // Sheet States
    @State private var showFullReport = false
    @State private var showHistorySheet = false
    @State private var showProfile = false
    // V2.5: item-based sheet so initialPrompt is always captured correctly
    private struct AskDestinyItem: Identifiable {
        let id = UUID()
        let prompt: String?
    }
    @State private var askDestinyItem: AskDestinyItem? = nil
    // Lifted from OrbitAshtakootView so tooltip renders above ScrollView content
    @State private var selectedKuta: AshtakootData? = nil
    
    // Animation State
    @State private var contentOpacity: Double = 0
    
    // Cached Mangal Dosha data (avoid re-decoding on every render)
    @State private var cachedBoyMangalDosha: MangalDoshaData?
    @State private var cachedGirlMangalDosha: MangalDoshaData?
    @State private var mangalDoshaCached = false

    // Computed Data for Grid
    private var ashtakootPoints: [String: Double] {
        Dictionary<String, Double>(uniqueKeysWithValues: result.kutas.map { ($0.name.lowercased(), Double($0.points)) })
    }
    
    // Kalsarpa Dosha Status
    private var kalsarpaStatusText: String {
        let boyPresent = result.analysisData?.boy?.raw?.kalaSarpa?.present ?? false
        let girlPresent = result.analysisData?.girl?.raw?.kalaSarpa?.present ?? false
        
        if !boyPresent && !girlPresent {
            return "kalsarpa_clear".localized
        } else if boyPresent && girlPresent {
            return "kalsarpa_both_present".localized
        } else {
            return "kalsarpa_moderate".localized
        }
    }
    
    private var kalsarpaStatusColor: Color {
        let boyPresent = result.analysisData?.boy?.raw?.kalaSarpa?.present ?? false
        let girlPresent = result.analysisData?.girl?.raw?.kalaSarpa?.present ?? false
        
        if !boyPresent && !girlPresent {
            return AppTheme.Colors.success
        } else if boyPresent && girlPresent {
            return .orange
        } else {
            return .yellow
        }
    }
    
    init(
        result: CompatibilityResult,
        boyName: String,
        girlName: String,
        boyDob: String? = nil,
        girlDob: String? = nil,
        boyCity: String? = nil,
        girlCity: String? = nil,
        onNewAnalysis: @escaping () -> Void,
        onBack: (() -> Void)? = nil,
        onHistory: (() -> Void)? = nil,
        onCharts: (() -> Void)? = nil,
        onLoadHistory: ((CompatibilityHistoryItem) -> Void)? = nil
    ) {
        self.result = result
        self.boyName = boyName
        self.girlName = girlName
        self.boyDob = boyDob
        self.girlDob = girlDob
        self.boyCity = boyCity
        self.girlCity = girlCity
        self.onNewAnalysis = onNewAnalysis
        self.onBack = onBack
        self.onHistory = onHistory
        self.onCharts = onCharts
        self.onLoadHistory = onLoadHistory
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Background
                CosmicBackgroundView()
                    .ignoresSafeArea()
            
            // 2. Main Content
            VStack(spacing: 0) {
                // Fixed Header
                MatchResultHeader(
                    boyName: boyName,
                    girlName: girlName,
                    onBackTap: onBack,
                    onHistoryTap: { showHistorySheet = true },
                    onChartTap: onCharts,
                    onNewMatchTap: onNewAnalysis,
                    transparent: true
                )
                .accessibilityLabel("accessibility_birth_chart".localized)
                .accessibilityLabel("accessibility_new_analysis".localized)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) { // Reduced spacing to compact layout
                        
                        // 1. Hero: Planetary Orbit (v5) — with adjusted score & cancellation data
                        OrbitAshtakootView(
                            kutas: result.kutas,
                            centerView: {
                                AnyView(
                                    SynergyGaugeView(
                                        score: Double(result.totalScore),
                                        maxScore: Double(result.maxScore),
                                        boyName: boyName,
                                        girlName: girlName,
                                        size: 160,
                                        showAvatars: false,
                                        adjustedScore: result.adjustedScore != nil ? Double(result.adjustedScore!) : nil
                                    )
                                )
                            },
                            boyName: boyName,
                            girlName: girlName,
                            doshaSummary: result.doshaSummary,
                            selectedKuta: $selectedKuta
                        )
                        .padding(.bottom, 0) // Removed extra padding to close gap
                        
                        // 1.5. Recommendation + Dosha Summary Banner
                        RecommendationBannerView(result: result)
                        
                        // 2. Partners (Removed - Embedded in Orbit)
                        
                        // Section 2: System Checks (Doshas)
                        VStack(alignment: .leading, spacing: 12) {
                            // Header removed to save vertical space
                            
                            VStack(spacing: 12) {
                                // Mangal Dosha - NavigationLink
                                NavigationLink {
                                    mangalDoshaDestination
                                } label: {
                                    DoshaStatusRowLabel(
                                        title: "mangal_dosha_full".localized,
                                        icon: "flame.fill",
                                        statusText: result.analysisData?.joint?.mangalCompatibility?["compatibility_category"]?.value as? String ?? "view_action".localized,
                                        statusColor: (result.analysisData?.joint?.mangalCompatibility?["compatibility_category"]?.value as? String)?.lowercased() == "excellent" ? AppTheme.Colors.success : .orange
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityIdentifier("mangal_dosha_row")
                                
                                // Kalsarpa Dosha - NavigationLink
                                NavigationLink {
                                    KalsarpaDoshaSheet(
                                        boyData: result.analysisData?.boy?.raw?.kalaSarpa,
                                        girlData: result.analysisData?.girl?.raw?.kalaSarpa,
                                        boyName: boyName,
                                        girlName: girlName
                                    )
                                } label: {
                                    DoshaStatusRowLabel(
                                        title: "kaal_sarp_dosha_full".localized,
                                        icon: "tornado",
                                        statusText: kalsarpaStatusText,
                                        statusColor: kalsarpaStatusColor
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityIdentifier("kalsarpa_dosha_row")
                                
                                // Additional Yogas - NavigationLink
                                NavigationLink {
                                    AdditionalYogasSheet(
                                        boyData: result.analysisData?.boy?.raw?.yogas,
                                        girlData: result.analysisData?.girl?.raw?.yogas,
                                        boyName: boyName,
                                        girlName: girlName
                                    )
                                } label: {
                                    DoshaStatusRowLabel(
                                        title: "additional_yogas_title".localized,
                                        icon: "sparkles",
                                        statusText: "view_all_action".localized,
                                        statusColor: AppTheme.Colors.textSecondary
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 0)
                        }
                        .padding(.top, 20)
                        
                        ShimmerButton(
                            title: "view_full_report_action".localized,
                            icon: nil
                        ) {
                            HapticManager.shared.play(.medium)
                            showFullReport = true
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 10)
                        .padding(.bottom, 20) // Moved significantly up
                    }
                    .padding([.horizontal, .bottom], 16) // Removed top padding
                    .padding(.top, 0) // Explicit zero top padding
                    .opacity(contentOpacity)
                }
                .scrollIndicators(.hidden)
            }
            
            // 3. Floating Context Action (Ask)
            FloatingContextButton(
                icon: "bubble.left.and.bubble.right.fill",
                action: { askDestinyItem = AskDestinyItem(prompt: nil) }
            )
            .accessibilityIdentifier("ask_destiny_button")
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            
            // Kuta tooltip overlay — rendered here so it floats above the ScrollView and
            // recommendation banner without being clipped by scroll content layout.
            if let kuta = selectedKuta {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation { selectedKuta = nil } }
                    .ignoresSafeArea()

                OrbitTooltipView(
                    kuta: kuta,
                    boyName: boyName,
                    girlName: girlName,
                    onDismiss: { withAnimation { selectedKuta = nil } },
                    onClassicalAnalysis: { prompt in
                        withAnimation(.easeOut(duration: 0.2)) { selectedKuta = nil }
                        askDestinyItem = AskDestinyItem(prompt: prompt)
                    }
                )
                .transition(.scale(scale: 0.95).combined(with: .opacity))
                .zIndex(200)
            }

            } // End ZStack
            .navigationBarHidden(true)
        } // End NavigationStack
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                contentOpacity = 1.0
            }
            // Decode Mangal Dosha off the main thread — JSONSerialization + JSONDecoder
            // block for ~1-3s on complex Opus results, which compounds the markdown
            // parsing cost and pushes the total past the watchdog threshold.
            if !mangalDoshaCached {
                let mangalCompat = result.analysisData?.joint?.mangalCompatibility
                Task.detached(priority: .userInitiated) {
                    let boy = Self.extractMangalDoshaData(from: mangalCompat?["boy_dosha"])
                    let girl = Self.extractMangalDoshaData(from: mangalCompat?["girl_dosha"])
                    await MainActor.run {
                        cachedBoyMangalDosha = boy
                        cachedGirlMangalDosha = girl
                        mangalDoshaCached = true
                    }
                }
            }
        }
        // Sheets
        .sheet(isPresented: $showFullReport) {
            FullReportSheet(
                result: result,
                boyName: boyName,
                girlName: girlName,
                boyDob: boyDob,
                girlDob: girlDob
            )
        }
        .sheet(item: $askDestinyItem) { item in
            AskDestinySheet(result: result, boyName: boyName, girlName: girlName, initialPrompt: item.prompt, showFollowUpSuggestions: !isFromComparison)
        }
         .sheet(isPresented: $showHistorySheet) {
            CompatibilityHistorySheet { selectedItem in
                showHistorySheet = false
                onLoadHistory?(selectedItem)
            }
            .accessibilityLabel("accessibility_history_match".localized)
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openProfileSettings)) { _ in
            showProfile = true
        }
    }
    
    // Helper needed for Sheet Data Extraction
    static func extractMangalDoshaData(from anyCodable: AnyCodable?) -> MangalDoshaData? {
        guard let dict = anyCodable?.value as? [String: Any] else {
            return nil
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            let decoder = JSONDecoder()
            // NOTE: Do NOT use .convertFromSnakeCase here — MangalDoshaData
            // already has custom CodingKeys that map snake_case to camelCase.
            // Using both causes double-conversion and key lookup failures.
            return try decoder.decode(MangalDoshaData.self, from: jsonData)
        } catch {
            print("[MangalDosha] ❌ Failed to decode: \(error)")
            return nil
        }
    }
    
    // Computed property for Mangal Dosha NavigationLink destination (uses cached data)
    private var mangalDoshaDestination: some View {
        let mangalCompat = result.analysisData?.joint?.mangalCompatibility

        return MangalDoshaSheet(
            boyData: cachedBoyMangalDosha ?? result.analysisData?.boy?.raw?.mangalDosha,
            girlData: cachedGirlMangalDosha ?? result.analysisData?.girl?.raw?.mangalDosha,
            boyName: boyName,
            girlName: girlName,
            mangalCompatibility: mangalCompat
        )
    }
}

// MARK: - Recommendation Banner View

private struct RecommendationBannerView: View {
    let result: CompatibilityResult

    var body: some View {
        let score = result.adjustedScore ?? result.totalScore
        let borderColor = result.isRecommended ? AppTheme.Colors.success : AppTheme.Colors.error

        VStack(spacing: 0) {
            // ── Header ──
            HStack(spacing: 10) {
                Image(systemName: result.isRecommended ? "checkmark.seal.fill" : "exclamationmark.octagon.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(result.isRecommended ? AppTheme.Colors.success : AppTheme.Colors.error)

                Text(result.isRecommended ? "recommended".localized : "not_recommended".localized)
                    .font(AppTheme.Fonts.title(size: 16).weight(.bold))
                    .foregroundColor(result.isRecommended ? AppTheme.Colors.success : AppTheme.Colors.error)

                Spacer()

                HStack(spacing: 4) {
                    Text("\(score)")
                        .font(AppTheme.Fonts.title(size: 20).weight(.bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("/\(result.maxScore)")
                        .font(AppTheme.Fonts.title(size: 16))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .accessibilityIdentifier("compat_result_score")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(result.isRecommended
                          ? AppTheme.Colors.success.opacity(0.1)
                          : AppTheme.Colors.error.opacity(0.1))
            )

            // ── Body ──
            VStack(alignment: .leading, spacing: 12) {
                if result.isRecommended {
                    // Affirmation text (device-computed)
                    let affirmation = AffirmationBuilder(
                        kutas: result.kutas,
                        adjustedScore: result.adjustedScore,
                        totalScore: result.totalScore
                    ).affirmationText()

                    Text(affirmation)
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    // "Not recommended because:" bullets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("not_recommended_because".localized)
                            .font(AppTheme.Fonts.caption(size: 12).weight(.bold))
                            .foregroundColor(AppTheme.Colors.error)

                        ForEach(Array(result.rejectionReasons.enumerated()), id: \.offset) { _, reason in
                            reasonBullet(reason)
                        }
                    }
                }

                // ── Cancelled doshas row ──
                cancelledDoshasRow
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(borderColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: borderColor.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.top, 8)
    }

    // MARK: - Reason bullet

    @ViewBuilder
    private func reasonBullet(_ reason: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundColor(reasonIconColor(for: reason))
                .padding(.top, 2)

            reasonText(reason)
                .font(AppTheme.Fonts.caption(size: 13))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func reasonIconColor(for reason: String) -> Color {
        if reason.hasPrefix("Adjusted Ashtakoot score") { return .orange }
        return AppTheme.Colors.error
    }

    @ViewBuilder
    private func reasonText(_ reason: String) -> some View {
        // Backend format: "Nadi Dosha is active — same biological constitution. ..." (agent.py gate 1)
        if reason.hasPrefix("Nadi Dosha") {
            let suffix = reason.dropFirst("Nadi Dosha is active".count)
                .trimmingCharacters(in: .init(charactersIn: " —"))
            (Text("Nadi Dosha is active").bold().foregroundColor(AppTheme.Colors.textPrimary)
             + Text(" — \(suffix)"))
        // Backend format: "Bhakoot Dosha is active — Moon positions create..." (agent.py gate 2)
        } else if reason.hasPrefix("Bhakoot Dosha") {
            let suffix = reason.dropFirst("Bhakoot Dosha is active".count)
                .trimmingCharacters(in: .init(charactersIn: " —"))
            (Text("Bhakoot Dosha is active").bold().foregroundColor(AppTheme.Colors.textPrimary)
             + Text(" — \(suffix)"))
        // Backend format: "Mangal Dosha incompatibility — {boy}: {sev} (Mars in {house}), ..." (agent.py:155-161)
        } else if reason.hasPrefix("Mangal Dosha") {
            let suffix = reason.dropFirst("Mangal Dosha incompatibility — ".count)
                .trimmingCharacters(in: .whitespaces)
            (Text("Mangal Dosha incompatibility").bold().foregroundColor(AppTheme.Colors.textPrimary)
             + Text(" — \(suffix)"))
        // Backend format: "Adjusted Ashtakoot score {N}/36 — below the 18-point minimum threshold." (agent.py gate 3)
        } else if reason.hasPrefix("Adjusted Ashtakoot score") {
            scoreReasonText(reason)
        } else {
            Text(reason)
        }
    }

    /// Renders "Adjusted Ashtakoot score N/36 — …" with N/36 in orange bold.
    @ViewBuilder
    private func scoreReasonText(_ reason: String) -> some View {
        if let range = reason.range(of: #"\d+\.?\d*/36"#, options: .regularExpression) {
            let score = String(reason[range])
            let after = String(reason[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            let before = String(reason[..<range.lowerBound])
            (Text(before)
             + Text(score).bold().foregroundColor(.orange)
             + Text(" \(after)"))
        } else {
            Text(reason)
        }
    }

    // MARK: - Cancelled doshas row

    @ViewBuilder
    private var cancelledDoshasRow: some View {
        let cancelledCount = result.doshaSummary?.cancelledCount ?? 0
        if cancelledCount > 0 {
            let summaryText = result.cancelledDoshasSummary ?? fallbackCancelledText(count: cancelledCount)
            VStack(alignment: .leading, spacing: 0) {
                Divider()
                    .background(AppTheme.Colors.success.opacity(0.2))
                    .padding(.bottom, 10)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.success)
                        .padding(.top, 1)

                    Text(summaryText)
                        .font(AppTheme.Fonts.caption(size: 12))
                        .foregroundColor(AppTheme.Colors.success.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func fallbackCancelledText(count: Int) -> String {
        // Build a name-aware fallback from doshaSummary.details when cancelledDoshasSummary is nil
        let keyOrder = ["nadi", "bhakoot", "gana", "maitri", "yoni", "tara", "vashya", "varna"]
        let displayNames = ["nadi": "Nadi", "bhakoot": "Bhakoot", "gana": "Gana",
                            "maitri": "Maitri", "yoni": "Yoni", "tara": "Tara",
                            "vashya": "Vashya", "varna": "Varna"]
        let details = result.doshaSummary?.details ?? [:]
        let cancelledNames = keyOrder.compactMap { key -> String? in
            guard details[key]?.cancelled == true else { return nil }
            return displayNames[key]
        }
        let names = cancelledNames.isEmpty ? nil : cancelledNames

        if let names, !names.isEmpty {
            if names.count == 1 {
                return "\(names[0]) Dosha found and cancelled — it doesn't count against this match."
            } else {
                let joined = names.dropLast().joined(separator: ", ") + " and \(names.last!)"
                return "\(joined) Doshas found and cancelled — they don't count against this match."
            }
        }
        // Last resort: count-only
        let subject = count == 1 ? "it doesn't" : "they don't"
        return "\(count) \(count == 1 ? "dosha".localized : "doshas".localized) found and cancelled — \(subject) affect this match."
    }
}
