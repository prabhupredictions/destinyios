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
    }
    
    // MARK: - Recommendation + Dosha Summary Banner
    @ViewBuilder
    private var recommendationBanner: some View {
        let hasDosha = (result.doshaSummary?.totalDoshas ?? 0) > 0
        let cancelledCount = result.doshaSummary?.cancelledCount ?? 0
        let activeCount = result.doshaSummary?.activeCount ?? 0
        
        if hasDosha || !result.isRecommended || !result.rejectionReasons.isEmpty {
            VStack(spacing: 8) {
                // Recommendation status
                HStack(spacing: 8) {
                    Image(systemName: result.isRecommended ? "checkmark.seal.fill" : "exclamationmark.octagon.fill")
                        .font(.system(size: 16))
                        .foregroundColor(result.isRecommended ? AppTheme.Colors.success : AppTheme.Colors.error)
                    
                    Text(result.isRecommended ? "marriage_recommended".localized : "not_recommended".localized)
                        .font(AppTheme.Fonts.body(size: 14).weight(.semibold))
                        .foregroundColor(result.isRecommended ? AppTheme.Colors.success : AppTheme.Colors.error)
                    
                    Spacer()
                }
                
                // Dosha summary counts
                if hasDosha {
                    HStack(spacing: 12) {
                        doshaPill(count: result.doshaSummary?.totalDoshas ?? 0, label: "doshas".localized, color: AppTheme.Colors.warning)
                        if cancelledCount > 0 {
                            doshaPill(count: cancelledCount, label: "cancelled".localized, color: AppTheme.Colors.success)
                        }
                        if activeCount > 0 {
                            doshaPill(count: activeCount, label: "active".localized, color: AppTheme.Colors.error)
                        }
                        Spacer()
                    }
                }
                
                // Rejection reasons (if not recommended)
                if !result.rejectionReasons.isEmpty {
                    ForEach(result.rejectionReasons, id: \.self) { reason in
                        let displayReason = reason
                            .replacingOccurrences(of: "Boy:", with: "\(boyName):")
                            .replacingOccurrences(of: "Girl:", with: "\(girlName):")
                            .replacingOccurrences(of: "Boy ", with: "\(boyName) ")
                            .replacingOccurrences(of: "Girl ", with: "\(girlName) ")
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.Colors.error.opacity(0.8))
                                .padding(.top, 2)
                            Text(displayReason)
                                .font(AppTheme.Fonts.caption(size: 12))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.bottom, 4)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        result.isRecommended
                            ? AppTheme.Colors.success.opacity(0.2)
                            : AppTheme.Colors.error.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .padding(.horizontal, 0)
            .padding(.top, 8)
        }
    }
    
    private func doshaPill(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .font(AppTheme.Fonts.caption(size: 12).weight(.bold))
                .foregroundColor(color)
            Text(label)
                .font(AppTheme.Fonts.caption(size: 11))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(color.opacity(0.25), lineWidth: 0.5)
        )
    }
    
    // Helper needed for Sheet Data Extraction
    static func extractMangalDoshaData(from anyCodable: AnyCodable?) -> MangalDoshaData? {
        guard let dict = anyCodable?.value as? [String: Any] else { return nil }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            let decoder = JSONDecoder()
            return try decoder.decode(MangalDoshaData.self, from: jsonData)
        } catch {
            print("Failed to decode MangalDoshaData: \(error)")
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
