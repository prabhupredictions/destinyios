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
    
    // Sheet States
    @State private var showFullReport = false
    @State private var showAskDestiny = false
    @State private var showHistorySheet = false
    @State private var showProfile = false
    
    // Animation State
    @State private var contentOpacity: Double = 0
    
    // Status Logic Helpers
    private var isMangalEffective: Bool {
        // Simple logic: if present in result data as "Present" or "Effective"
        // For MVP, we'll check the summary text or assume based on score if data missing
        // Better: check result.analysisData?.joint?.mangalCompatibility
        return false // Default safe, effectively handled by sheet logic usually
    }
    
    // Computed Data for Grid
    private var ashtakootPoints: [String: Double] {
        Dictionary<String, Double>(uniqueKeysWithValues: result.kutas.map { ($0.name.lowercased(), Double($0.points)) })
    }
    
    // Kalsarpa Dosha Status
    private var kalsarpaStatusText: String {
        let boyPresent = result.analysisData?.boy?.raw?.kalaSarpa?.present ?? false
        let girlPresent = result.analysisData?.girl?.raw?.kalaSarpa?.present ?? false
        
        if !boyPresent && !girlPresent {
            return "Clear"
        } else if boyPresent && girlPresent {
            return "Both Present"
        } else {
            return "Moderate"
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
                            doshaSummary: result.doshaSummary
                        )
                        .padding(.bottom, 0) // Removed extra padding to close gap
                        
                        // 1.5. Recommendation + Dosha Summary Banner
                        recommendationBanner
                        
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
                                        title: "Mangal Dosha (Manglik/Kuja)",
                                        icon: "flame.fill",
                                        statusText: result.analysisData?.joint?.mangalCompatibility?["compatibility_category"]?.value as? String ?? "View",
                                        statusColor: (result.analysisData?.joint?.mangalCompatibility?["compatibility_category"]?.value as? String)?.lowercased() == "excellent" ? AppTheme.Colors.success : .orange
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
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
                                        title: "Kaal Sarp Dosha (Kalasarpa)",
                                        icon: "tornado",
                                        statusText: kalsarpaStatusText,
                                        statusColor: kalsarpaStatusColor
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
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
                                        title: "Additional Yogas",
                                        icon: "sparkles",
                                        statusText: "View All",
                                        statusColor: AppTheme.Colors.textSecondary
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 0)
                        }
                        .padding(.top, 20)
                        
                        ShimmerButton(
                            title: "View Full Report",
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
                action: { showAskDestiny = true }
            )
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            
            } // End ZStack
            .navigationBarHidden(true)
        } // End NavigationStack
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                contentOpacity = 1.0
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
        .sheet(isPresented: $showAskDestiny) {
            AskDestinySheet(result: result, boyName: boyName, girlName: girlName)
        }
         .sheet(isPresented: $showHistorySheet) {
            CompatibilityHistorySheet { selectedItem in
                showHistorySheet = false
                onLoadHistory?(selectedItem)
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openProfileSettings)) { _ in
            showProfile = true
        }
    }
    
    // MARK: - Recommendation + Dosha Summary Banner
    @ViewBuilder
    private var recommendationBanner: some View {
        let hasDosha = (result.doshaSummary?.activeCount ?? 0) > 0
        let cancelledCount = result.doshaSummary?.cancelledCount ?? 0
        let activeCount = result.doshaSummary?.activeCount ?? 0
        let borderColor = result.isRecommended ? AppTheme.Colors.success : AppTheme.Colors.error
        
        if hasDosha || !result.isRecommended || !result.rejectionReasons.isEmpty {
            VStack(spacing: 0) {
                // ─── Header Band ───
                HStack(spacing: 10) {
                    Image(systemName: result.isRecommended ? "checkmark.seal.fill" : "exclamationmark.octagon.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(result.isRecommended ? AppTheme.Colors.success : AppTheme.Colors.error)
                    
                    Text(result.isRecommended ? "recommended".localized : "not_recommended".localized)
                        .font(AppTheme.Fonts.title(size: 16).weight(.bold))
                        .foregroundColor(result.isRecommended ? AppTheme.Colors.success : AppTheme.Colors.error)
                    
                    Spacer()
                    
                    // Score moved to header — show adjusted score when available
                    HStack(spacing: 4) {
                        Text("\(result.adjustedScore ?? result.totalScore)")
                            .font(AppTheme.Fonts.title(size: 20).weight(.bold))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("/\(result.maxScore)")
                            .font(AppTheme.Fonts.title(size: 16))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(result.isRecommended ? AppTheme.Colors.success.opacity(0.1) : AppTheme.Colors.error.opacity(0.1))
                )
                
                // ─── Content Area ───
                VStack(alignment: .leading, spacing: 12) {
                    // ─── Recommendation Text ───
                    Text(result.recommendation.localized)
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // ─── Active Doshas (including those in rejection reasons) ───
                    if let details = result.doshaSummary?.details, activeCount > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("active_doshas".localized)
                                    .font(AppTheme.Fonts.caption(size: 12).weight(.bold))
                                    .foregroundColor(AppTheme.Colors.warning)
                                
                                // Count badge
                                Text("\(activeCount)")
                                    .font(AppTheme.Fonts.caption(size: 11).weight(.bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.Colors.warning)
                                    .clipShape(Capsule())
                                
                                if cancelledCount > 0 {
                                    Text("(\(cancelledCount) " + "cancelled".localized + ")")
                                        .font(AppTheme.Fonts.caption(size: 11))
                                        .foregroundColor(AppTheme.Colors.success)
                                }
                                
                                Spacer()
                            }
                            
                            // Show all active doshas in order
                            let doshaOrder = ["nadi", "bhakoot", "gana", "maitri", "yoni", "vashya", "tara", "varna"]
                            let doshaNames: [String: String] = [
                                "nadi": "Nadi", "bhakoot": "Bhakoot", "gana": "Gana",
                                "maitri": "Maitri", "yoni": "Yoni", "vashya": "Vashya",
                                "tara": "Tara", "varna": "Varna"
                            ]
                            
                            ForEach(doshaOrder, id: \.self) { key in
                                if let detail = details[key],
                                   detail.present == true {
                                    HStack(spacing: 8) {
                                        Image(systemName: detail.cancelled == true ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(detail.cancelled == true ? AppTheme.Colors.success : AppTheme.Colors.warning)
                                        
                                        Text("\(doshaNames[key] ?? key.capitalized) " + "dosha_label".localized)
                                            .font(AppTheme.Fonts.caption(size: 12).weight(.semibold))
                                            .foregroundColor(AppTheme.Colors.textPrimary)
                                        
                                        if detail.cancelled == true {
                                            Text("cancelled".localized)
                                                .font(AppTheme.Fonts.caption(size: 10))
                                                .foregroundColor(AppTheme.Colors.success)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    
                    // ─── Additional Notes (if any) ───
                    if !result.rejectionReasons.isEmpty {
                        Divider()
                            .background(AppTheme.Colors.textTertiary.opacity(0.2))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("additional_notes".localized)
                                .font(AppTheme.Fonts.caption(size: 12).weight(.bold))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            ForEach(Array(result.rejectionReasons.enumerated()), id: \.offset) { _, reason in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                        .font(AppTheme.Fonts.caption(size: 12))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                    
                                    Text(replaceNamesInBanner(reason))
                                        .font(AppTheme.Fonts.caption(size: 12))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
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
    }
    
    // MARK: - Active Dosha Row
    @ViewBuilder
    private func activeDoshaRow(_ dosha: (name: String, detail: DoshaDetail)) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundColor(AppTheme.Colors.warning)
            
            Text("\(dosha.name) " + "dosha_label".localized)
                .font(AppTheme.Fonts.caption(size: 12).weight(.semibold))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            if let severity = dosha.detail.severity {
                severityBadge(severity)
            }
            Spacer()
        }
    }
    
    // MARK: - Severity Badge
    private func severityBadge(_ severity: String) -> some View {
        let color: Color = severity.lowercased() == "high"
            ? AppTheme.Colors.error
            : severity.lowercased() == "medium"
                ? AppTheme.Colors.gold
                : AppTheme.Colors.textTertiary
        return Text(severity.capitalized)
            .font(AppTheme.Fonts.caption(size: 9).weight(.bold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(color.opacity(0.12))
            )
            .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 0.5))
    }
    
    // MARK: - Rejection Reason Card
    @ViewBuilder
    private func rejectionReasonCard(_ reason: String) -> some View {
        let cleaned = replaceNamesInBanner(reason)
        let isMangal = cleaned.localizedCaseInsensitiveContains("Mangal Dosha")
        
        VStack(alignment: .leading, spacing: 6) {
            // Header: dosha name with icon
            let doshaLabel = extractDoshaLabel(from: cleaned)
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.error)
                Text(doshaLabel ?? "rejection_reason_label".localized)
                    .font(AppTheme.Fonts.caption(size: 12).weight(.bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
            }
            
            // Body: format differently for Mangal vs other doshas
            if isMangal {
                mangalDoshaFormattedView(cleaned)
            } else {
                // Split into structured lines at sentence boundaries
                let lines = splitIntoLines(cleaned)
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    HStack(alignment: .top, spacing: 6) {
                        Circle()
                            .fill(AppTheme.Colors.textTertiary.opacity(0.5))
                            .frame(width: 4, height: 4)
                            .padding(.top, 5)
                        Text(line)
                            .font(AppTheme.Fonts.caption(size: 11))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(1.5)
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.Colors.error.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppTheme.Colors.error.opacity(0.12), lineWidth: 0.5)
        )
    }
    
    // MARK: - Mangal Dosha Formatted View (separate lines per partner)
    @ViewBuilder
    private func mangalDoshaFormattedView(_ text: String) -> some View {
        // Split by common delimiters: ", House:" or ". Mangal" to get per-partner info
        // Pattern: "...Prabhu: Mild (Mars in 4th house), Smita: Cancelled (Mars in 3rd house)..."
        let parts = text.components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
            // Check if this part contains per-partner info
            let containsPartnerInfo = part.contains(boyName) || part.contains(girlName)
            
            if containsPartnerInfo {
                // Try to split at partner name boundaries
                let perPartner = splitByPartnerNames(part)
                ForEach(Array(perPartner.enumerated()), id: \.offset) { _, partnerLine in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 9))
                            .foregroundColor(AppTheme.Colors.gold.opacity(0.7))
                            .padding(.top, 3)
                        Text(partnerLine)
                            .font(AppTheme.Fonts.caption(size: 11))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                HStack(alignment: .top, spacing: 6) {
                    Circle()
                        .fill(AppTheme.Colors.textTertiary.opacity(0.5))
                        .frame(width: 4, height: 4)
                        .padding(.top, 5)
                    Text(part)
                        .font(AppTheme.Fonts.caption(size: 11))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    // MARK: - Helper: Split text by partner names into separate lines
    private func splitByPartnerNames(_ text: String) -> [String] {
        // Try to split at ", <girlName>" or ", <boyName>" boundaries
        var lines: [String] = []
        let separators = [", \(girlName):", ", \(girlName) ", "), \(girlName)"]
        
        var remaining = text
        for sep in separators {
            if let range = remaining.range(of: sep) {
                let first = String(remaining[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let second = String(remaining[range.lowerBound...]).trimmingCharacters(in: CharacterSet(charactersIn: ", "))
                if !first.isEmpty { lines.append(first) }
                if !second.isEmpty { lines.append(second) }
                remaining = ""
                break
            }
        }
        
        if lines.isEmpty {
            // Fallback: return as single line
            return [text]
        }
        return lines
    }
    
    // MARK: - Helpers
    
    private func extractDoshaLabel(from text: String) -> String? {
        let patterns = ["Mangal Dosha", "Bhakoot Dosha", "Nadi Dosha", "Gana Dosha",
                        "Maitri Dosha", "Yoni Dosha", "Vashya Dosha", "Tara Dosha", "Varna Dosha",
                        "Ashtakoot"]
        for p in patterns {
            if text.localizedCaseInsensitiveContains(p) { return p }
        }
        return nil
    }
    
    private func splitIntoLines(_ text: String) -> [String] {
        text.components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { $0.hasSuffix(".") ? $0 : $0 + "." }
    }
    
    private func replaceNamesInBanner(_ text: String) -> String {
        text
            .replacingOccurrences(of: "Groom's", with: "\(boyName)'s")
            .replacingOccurrences(of: "Bride's", with: "\(girlName)'s")
            .replacingOccurrences(of: "Groom:", with: "\(boyName):")
            .replacingOccurrences(of: "Bride:", with: "\(girlName):")
            .replacingOccurrences(of: "Boy ", with: "\(boyName) ")
            .replacingOccurrences(of: "Girl ", with: "\(girlName) ")
            .replacingOccurrences(of: "Boy's", with: "\(boyName)'s")
            .replacingOccurrences(of: "Girl's", with: "\(girlName)'s")
            .replacingOccurrences(of: "Boy:", with: "\(boyName):")
            .replacingOccurrences(of: "Girl:", with: "\(girlName):")
    }
    
    // Helper needed for Sheet Data Extraction
    static func extractMangalDoshaData(from anyCodable: AnyCodable?) -> MangalDoshaData? {
        guard let dict = anyCodable?.value as? [String: Any] else {
            print("[MangalDosha] ❌ anyCodable?.value is not [String: Any], type=\(type(of: anyCodable?.value)) value=\(String(describing: anyCodable?.value))")
            return nil
        }
        
        // Debug: Print all keys and their types
        print("[MangalDosha] 📋 Dictionary keys: \(Array(dict.keys).sorted())")
        if let doshaFromVal = dict["dosha_from"] {
            print("[MangalDosha] 📋 dosha_from value: \(String(describing: doshaFromVal)), type: \(type(of: doshaFromVal))")
        } else {
            print("[MangalDosha] ❌ dosha_from key NOT FOUND in dict")
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            
            // Debug: Print the JSON that was serialized
            if let jsonStr = String(data: jsonData, encoding: .utf8) {
                // Find dosha_from in the JSON string
                if let range = jsonStr.range(of: "dosha_from") {
                    let start = jsonStr.index(range.upperBound, offsetBy: 0)
                    let end = jsonStr.index(start, offsetBy: min(200, jsonStr.distance(from: start, to: jsonStr.endIndex)))
                    print("[MangalDosha] 📋 JSON dosha_from snippet: \(jsonStr[start..<end])")
                } else {
                    print("[MangalDosha] ❌ dosha_from not found in serialized JSON")
                }
            }
            
            let decoder = JSONDecoder()
            // NOTE: Do NOT use .convertFromSnakeCase here — MangalDoshaData
            // already has custom CodingKeys that map snake_case to camelCase.
            // Using both causes double-conversion and key lookup failures.
            let result = try decoder.decode(MangalDoshaData.self, from: jsonData)
            print("[MangalDosha] ✅ Decoded successfully - doshaFrom has \(result.doshaFrom?.count ?? 0) keys")
            return result
        } catch {
            print("[MangalDosha] ❌ Failed to decode: \(error)")
            if let jsonStr = String(data: (try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)) ?? Data(), encoding: .utf8) {
                print("[MangalDosha] 📋 Full JSON: \(jsonStr)")
            }
            return nil
        }
    }
    
    // Computed property for Mangal Dosha NavigationLink destination
    private var mangalDoshaDestination: some View {
        let mangalCompat = result.analysisData?.joint?.mangalCompatibility
        let boyDosha = Self.extractMangalDoshaData(from: mangalCompat?["boy_dosha"])
        let girlDosha = Self.extractMangalDoshaData(from: mangalCompat?["girl_dosha"])
        
        return MangalDoshaSheet(
            boyData: boyDosha ?? result.analysisData?.boy?.raw?.mangalDosha,
            girlData: girlDosha ?? result.analysisData?.girl?.raw?.mangalDosha,
            boyName: boyName,
            girlName: girlName,
            mangalCompatibility: mangalCompat
        )
    }
}
