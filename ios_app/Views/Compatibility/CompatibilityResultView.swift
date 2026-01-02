import SwiftUI

/// Results view for compatibility analysis - Compact Premium Design
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
    
    @State private var contentOpacity: Double = 0
    @State private var showFullReport = false
    @State private var showAskDestiny = false
    @State private var showMangalDosha = false
    @State private var showKalsarpaDosha = false
    @State private var showAdditionalYoga = false
    @State private var showHistorySheet = false
    
    // Premium Animation States
    @State private var scoreProgress: CGFloat = 0
    @State private var heartScale: CGFloat = 1.0
    @State private var kutaItemsVisible: [Bool] = Array(repeating: false, count: 8)
    
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
        ZStack {
            Color(red: 0.97, green: 0.96, blue: 0.98)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 5) { // 5px gaps between cards
                    // Header
                    MatchResultHeader(
                        onBackTap: onBack,
                        onHistoryTap: { showHistorySheet = true },
                        onChartTap: onCharts,
                        onNewMatchTap: onNewAnalysis
                    )
                    
                    // Partner Cards
                    partnerCardsSection
                    
                    // Score Card
                    mainScoreCard
                    
                    // Kuta Grid
                    kutaGridSection
                    
                    // Dosha Buttons (Row 1)
                    doshaButtonsRow
                    
                    // Report & Ask Buttons (Row 2)
                    secondaryActionsRow
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 12)
                .opacity(contentOpacity)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            // Fade in content
            withAnimation(.easeOut(duration: 0.4)) {
                contentOpacity = 1.0
            }
            
            // Animated score ring fill
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                scoreProgress = result.percentage
            }
            
            // Staggered Kuta grid reveal
            for i in 0..<min(result.kutas.count, 8) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + Double(i) * 0.08) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        kutaItemsVisible[i] = true
                    }
                }
            }
            
            // Heart pulse animation (continuous)
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(0.5)) {
                heartScale = 1.15
            }
        }
        .sheet(isPresented: $showFullReport) {
            FullReportSheet(result: result, boyName: boyName, girlName: girlName)
        }
        .sheet(isPresented: $showAskDestiny) {
            AskDestinySheet(result: result, boyName: boyName, girlName: girlName)
        }
        .sheet(isPresented: $showMangalDosha) {
            // Extract mangal data from joint.mangal_compatibility since boy.raw is empty
            let mangalCompat = result.analysisData?.joint?.mangalCompatibility
            let boyDosha = Self.extractMangalDoshaData(from: mangalCompat?["boy_dosha"])
            let girlDosha = Self.extractMangalDoshaData(from: mangalCompat?["girl_dosha"])
            
            MangalDoshaSheet(
                boyData: boyDosha ?? result.analysisData?.boy?.raw?.mangalDosha,
                girlData: girlDosha ?? result.analysisData?.girl?.raw?.mangalDosha,
                boyName: boyName,
                girlName: girlName,
                mangalCompatibility: mangalCompat
            )
        }
        .sheet(isPresented: $showKalsarpaDosha) {
            KalsarpaDoshaSheet(
                boyData: result.analysisData?.boy?.raw?.kalaSarpa,
                girlData: result.analysisData?.girl?.raw?.kalaSarpa,
                boyName: boyName,
                girlName: girlName
            )
        }
        .sheet(isPresented: $showAdditionalYoga) {
            AdditionalYogasSheet(
                boyData: result.analysisData?.boy?.raw?.yogas,
                girlData: result.analysisData?.girl?.raw?.yogas,
                boyName: boyName,
                girlName: girlName
            )
        }
        .sheet(isPresented: $showHistorySheet) {
            CompatibilityHistorySheet { selectedItem in
                showHistorySheet = false
                onLoadHistory?(selectedItem)
            }
        }
    }
    
    // MARK: - Partner Cards
    private var partnerCardsSection: some View {
        HStack(spacing: 0) {
            CompactPartnerCard(name: boyName, dob: boyDob, city: boyCity, isMale: true)
            
            ZStack {
                // Glassmorphism background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 36, height: 36)
                    .shadow(color: Color(red: 0.95, green: 0.45, blue: 0.55).opacity(0.3), radius: 8, y: 2)
                
                // Pulsing heart
                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.45, blue: 0.55), Color(red: 0.85, green: 0.3, blue: 0.45)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(heartScale)
            }
            .offset(y: -12)
            .zIndex(1)
            .frame(width: 24)
            
            CompactPartnerCard(name: girlName, dob: girlDob, city: girlCity, isMale: false)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Score Card
    private var mainScoreCard: some View {
        VStack(spacing: 14) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [levelColor.opacity(0.15), levelColor.opacity(0.02)],
                            center: .center,
                            startRadius: 40,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                
                // Background track
                Circle()
                    .stroke(Color("NavyPrimary").opacity(0.06), lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                // Animated progress ring with gradient
                Circle()
                    .trim(from: 0, to: scoreProgress)
                    .stroke(
                        AngularGradient(
                            colors: [levelColor.opacity(0.6), levelColor, levelColor.opacity(0.8)],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: levelColor.opacity(0.4), radius: 6, y: 2)
                
                // Score text
                VStack(spacing: 2) {
                    Text("\(result.totalScore)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color("NavyPrimary"))
                    
                    Text("out_of".localized + " \(result.maxScore)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color("TextDark").opacity(0.45))
                        .tracking(-0.3)
                }
            }
            
            VStack(spacing: 4) {
                Text(compatibilityLevel)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(levelColor)
                    .tracking(-0.5)
                
                Text("\(Int(result.percentage * 100))%")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(Color("TextDark").opacity(0.35))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            ZStack {
                // Glassmorphism base
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                
                // White overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.85))
            }
            .shadow(color: Color("NavyPrimary").opacity(0.08), radius: 16, y: 6)
        )
    }
    
    private var compatibilityLevel: String {
        if result.percentage >= 0.75 { return "excellent_match".localized }
        else if result.percentage >= 0.5 { return "good_match".localized }
        else { return "moderate_match".localized }
    }
    
    private var levelColor: Color {
        if result.percentage >= 0.75 { return Color(red: 0.2, green: 0.7, blue: 0.4) }
        else if result.percentage >= 0.5 { return Color("GoldAccent") }
        else { return .orange }
    }

    // MARK: - Dosha Buttons Row
    private var doshaButtonsRow: some View {
        HStack(spacing: 12) {
            ActionButton(
                icon: "flame.fill",
                label: "mangal_dosha".localized,
                action: { showMangalDosha = true }
            )
            
            ActionButton(
                icon: "tornado",
                label: "kalsarpa_dosha".localized,
                action: { showKalsarpaDosha = true }
            )
            
            ActionButton(
                icon: "sparkles",
                label: "additional_yoga".localized,
                isPrimary: true,
                action: { showAdditionalYoga = true }
            )
        }
    }
    
    // MARK: - Secondary Actions Row (Report & Ask)
    private var secondaryActionsRow: some View {
        HStack(spacing: 12) {
            // View Full Report
            ActionButton(
                icon: "doc.text.fill",
                label: "view_full_report".localized,
                action: { showFullReport = true }
            )
            
            // Ask More
            ActionButton(
                icon: "bubble.left.and.bubble.right.fill",
                label: "ask_more_match".localized,
                action: { showAskDestiny = true }
            )
        }
    }
    
    // MARK: - Kuta Grid
    private var kutaGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("ashtakoot_grid".localized)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color("TextDark").opacity(0.45))
                .tracking(0.5)
                .padding(.horizontal, 4)
            
            // Staggered animated grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(Array(result.kutas.enumerated()), id: \.offset) { index, kuta in
                    CompactKutaBox(
                        kuta: kuta,
                        isVisible: index < kutaItemsVisible.count ? kutaItemsVisible[index] : true
                    )
                }
            }
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.85))
                
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color("NavyPrimary").opacity(0.04), lineWidth: 1)
            }
            .shadow(color: Color("NavyPrimary").opacity(0.06), radius: 12, y: 4)
        )
    }
    
    // MARK: - Helper to extract MangalDoshaData from AnyCodable
    /// Converts AnyCodable containing dosha dict to MangalDoshaData
    static func extractMangalDoshaData(from anyCodable: AnyCodable?) -> MangalDoshaData? {
        guard let dict = anyCodable?.value as? [String: Any] else { return nil }
        
        // Re-encode to JSON and decode to MangalDoshaData
        do {
            // Convert [String: Any] to JSON Data
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            // Decode to MangalDoshaData
            let decoder = JSONDecoder()
            return try decoder.decode(MangalDoshaData.self, from: jsonData)
        } catch {
            print("Failed to decode MangalDoshaData: \(error)")
            return nil
        }
    }
}

// MARK: - Action Button (Premium with Haptics)
struct ActionButton: View {
    let icon: String
    let label: String
    var isPrimary: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("NavyPrimary"), Color("NavyPrimary").opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolEffect(.bounce, value: isPressed)
                
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color("NavyPrimary").opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.9))
                    
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color("NavyPrimary").opacity(0.06), lineWidth: 1)
                }
                .shadow(color: Color("NavyPrimary").opacity(isPressed ? 0.02 : 0.08), radius: isPressed ? 4 : 10, y: isPressed ? 1 : 4)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Compact Partner Card (Premium)
struct CompactPartnerCard: View {
    let name: String
    let dob: String?
    let city: String?
    let isMale: Bool
    
    private var initial: String {
        guard let first = name.first else { return "?" }
        return String(first).uppercased()
    }
    
    private var avatarGradient: LinearGradient {
        if isMale {
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.7, blue: 0.7), Color(red: 0.15, green: 0.55, blue: 0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color(red: 0.95, green: 0.5, blue: 0.6), Color(red: 0.85, green: 0.35, blue: 0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(isMale ? Color(red: 0.2, green: 0.7, blue: 0.7).opacity(0.2) : Color(red: 0.95, green: 0.5, blue: 0.6).opacity(0.2))
                    .frame(width: 54, height: 54)
                    .blur(radius: 4)
                
                // Avatar circle with gradient
                Circle()
                    .fill(avatarGradient)
                    .frame(width: 48, height: 48)
                    .shadow(color: (isMale ? Color(red: 0.2, green: 0.7, blue: 0.7) : Color(red: 0.95, green: 0.5, blue: 0.6)).opacity(0.4), radius: 6, y: 3)
                
                Text(initial)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color("NavyPrimary"))
                    .lineLimit(1)
                    .tracking(-0.3)
                
                if let dob = dob, !dob.isEmpty {
                    Text(dob)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color("TextDark").opacity(0.5))
                }
                
                if let city = city, !city.isEmpty {
                    Text(city)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color("TextDark").opacity(0.35))
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.88))
                
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            }
            .shadow(color: Color("NavyPrimary").opacity(0.06), radius: 12, y: 4)
        )
    }
}

// MARK: - Compact Kuta Box (Premium)
struct CompactKutaBox: View {
    let kuta: KutaDetail
    var isVisible: Bool = true
    
    private var bgGradient: LinearGradient {
        let pct = kuta.percentage
        let baseColor: Color
        if pct >= 0.75 { baseColor = Color(red: 0.2, green: 0.7, blue: 0.4) }
        else if pct >= 0.50 { baseColor = Color("GoldAccent") }
        else if pct >= 0.25 { baseColor = .orange }
        else { baseColor = .red }
        
        return LinearGradient(
            colors: [baseColor.opacity(0.12), baseColor.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var textColor: Color {
        let pct = kuta.percentage
        if pct >= 0.75 { return Color(red: 0.2, green: 0.65, blue: 0.4) }
        else if pct >= 0.50 { return Color("GoldAccent") }
        else if pct >= 0.25 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(kuta.points)/\(kuta.maxPoints)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
            
            Text(kuta.name.prefix(4).uppercased())
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(Color("TextDark").opacity(0.4))
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(bgGradient)
                
                RoundedRectangle(cornerRadius: 10)
                    .stroke(textColor.opacity(0.15), lineWidth: 1)
            }
        )
        .scaleEffect(isVisible ? 1.0 : 0.7)
        .opacity(isVisible ? 1.0 : 0)
    }
}

// MARK: - Full Report Sheet
struct FullReportSheet: View {
    let result: CompatibilityResult
    let boyName: String
    let girlName: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(boyName) & \(girlName)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color("NavyPrimary"))
                            
                            Text("\(result.totalScore)/\(result.maxScore) \("points".localized)")
                                .font(.system(size: 11))
                                .foregroundColor(Color("TextDark").opacity(0.5))
                        }
                        
                        Spacer()
                        
                        Text("\(Int(result.percentage * 100))%")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(result.percentage >= 0.75 ? Color(red: 0.2, green: 0.7, blue: 0.4) : Color("GoldAccent"))
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(result.kutas) { kuta in
                            HStack {
                                Text(kuta.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color("NavyPrimary"))
                                
                                Spacer()
                                
                                Text("\(kuta.points)/\(kuta.maxPoints)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(kutaColor(kuta.percentage))
                            }
                            .padding(.vertical, 5)
                            
                            if kuta.id != result.kutas.last?.id { Divider() }
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                    
                    if !result.summary.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("summary".localized)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color("TextDark").opacity(0.5))
                            
                            

                            // Preprocess markdown for better display
                            let processedSummary = preprocessMarkdownForReport(result.summary)
                            
                            if let attrString = try? AttributedString(
                                markdown: processedSummary,
                                options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
                            ) {
                                Text(attrString)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color("NavyPrimary"))
                                    .lineSpacing(4)
                            } else {
                                Text(result.summary)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color("NavyPrimary"))
                                    .lineSpacing(4)
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                    }
                }
                .padding(14)
            }
            .background(Color(red: 0.96, green: 0.95, blue: 0.97))
            .navigationTitle("full_compatibility_report".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color("TextDark").opacity(0.25))
                    }
                }
            }
        }
    }
    
    private func kutaColor(_ pct: Double) -> Color {
        if pct >= 0.75 { return Color(red: 0.2, green: 0.7, blue: 0.4) }
        else if pct >= 0.50 { return Color("GoldAccent") }
        else if pct >= 0.25 { return .orange }
        else { return .red }
    }
}

// MARK: - Ask Destiny Sheet (Premium Dark Theme)
struct AskDestinySheet: View {
    let result: CompatibilityResult
    let boyName: String
    let girlName: String
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var message = ""
    @State private var messages: [CompatChatMessage] = []
    @FocusState private var isInputFocused: Bool
    private let service = CompatibilityService()
    private let predictionService = PredictionService()
    
    // Premium Dark Theme Colors
    private let darkBg = Color(red: 0.08, green: 0.08, blue: 0.14)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.20)
    private let accentGold = Color(red: 0.90, green: 0.72, blue: 0.35)
    private let accentPurple = Color(red: 0.55, green: 0.36, blue: 0.96)
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [darkBg, Color(red: 0.10, green: 0.08, blue: 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Premium Header
                premiumHeader
                
                // Quick Action Chips
                quickActionChips
                
                // Chat Messages Area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Welcome Message
                            welcomeCard
                            
                            // Chat Messages
                            ForEach(messages) { msg in
                                CompatMessageBubble(message: msg, accentGold: accentGold, accentPurple: accentPurple)
                                    .id(msg.id)
                            }
                            
                            // Typing Indicator
                            if isLoading {
                                CompatTypingIndicator(accentPurple: accentPurple)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: messages.count) { _ in
                        if let lastId = messages.last?.id {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Premium Input Area
                premiumInputArea
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadChatHistory()
        }
        .onDisappear {
            saveChatHistory()
        }
        .onChange(of: messages.count) { _ in
            saveChatHistory()
        }
    }
    
    // MARK: - Persistence
    private func loadChatHistory() {
        guard let sessionId = result.sessionId else { return }
        if let item = CompatibilityHistoryService.shared.get(sessionId: sessionId) {
            // Only load if local messages are empty (fresh open), otherwise keep current
            if messages.isEmpty {
                self.messages = item.chatMessages.map { $0.toMessage() }
            }
        }
    }
    
    private func saveChatHistory() {
        guard let sessionId = result.sessionId, !messages.isEmpty else { return }
        CompatibilityHistoryService.shared.updateChatMessages(sessionId: sessionId, messages: messages)
    }
    
    // MARK: - Premium Header
    private var premiumHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(cardBg))
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Ask Destiny")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text("\(boyName) & \(girlName)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Score Badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentPurple.opacity(0.3), accentGold.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Text("\(result.totalScore)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(accentGold)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(cardBg.opacity(0.8))
    }
    
    // MARK: - Quick Action Chips
    private var quickActionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                PremiumActionChip(icon: "✨", label: "Overall Match", gradient: [accentPurple, accentGold]) {
                    sendQuickQuestion("How is our overall compatibility?")
                }
                PremiumActionChip(icon: "⚠️", label: "Doshas", gradient: [.red.opacity(0.8), .orange]) {
                    sendQuickQuestion("Are there any doshas affecting this match?")
                }
                PremiumActionChip(icon: "💍", label: "Marriage", gradient: [.pink, accentPurple]) {
                    sendQuickQuestion("Is this a good match for marriage?")
                }
                PremiumActionChip(icon: "🔮", label: "Timing", gradient: [.blue, accentPurple]) {
                    sendQuickQuestion("What is the best time for our relationship?")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(cardBg.opacity(0.5))
    }
    
    // MARK: - Welcome Card
    private var welcomeCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // AI Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentPurple, accentGold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Text("✦")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Destiny AI")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Your Vedic Astrology Guide")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Match Score
                VStack(spacing: 2) {
                    Text("\(result.totalScore)/\(result.maxScore)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(accentGold)
                    Text("Score")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Text("I have analyzed the compatibility between **\(boyName)** and **\(girlName)**. Ask me anything about this match - predictions, doshas, timing, or remedies!")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [accentPurple.opacity(0.15), accentGold.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentPurple.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Premium Input Area
    private var premiumInputArea: some View {
        HStack(spacing: 12) {
            // Text Input
            HStack {
                TextField("Ask about this match...", text: $message)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .focused($isInputFocused)
                    .disabled(isLoading)
                
                if !message.isEmpty {
                    Button(action: { message = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(isInputFocused ? accentPurple.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )
            
            // Send Button
            Button(action: sendMessage) {
                ZStack {
                    Group {
                        if message.isEmpty || isLoading {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        } else {
                            Circle()
                                .fill(LinearGradient(colors: [accentPurple, accentGold], startPoint: .topLeading, endPoint: .bottomTrailing))
                        }
                    }
                    .frame(width: 48, height: 48)
                    
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .shadow(color: message.isEmpty ? .clear : accentPurple.opacity(0.4), radius: 8, y: 4)
            }
            .disabled(message.isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(cardBg.opacity(0.95))
    }
    
    // MARK: - Quick Question
    private func sendQuickQuestion(_ question: String) {
        message = question
        sendMessage()
    }
    
    // MARK: - Send Message
    private func sendMessage() {
        guard !message.isEmpty else { return }
        
        // Validate session ID
        guard let sessionId = result.sessionId, !sessionId.isEmpty else {
            messages.append(CompatChatMessage(
                content: "Session not available. Please run a new compatibility analysis first.",
                isUser: false,
                type: .error
            ))
            return
        }
        
        // Add user message
        let userQuestion = message
        messages.append(CompatChatMessage(content: userQuestion, isUser: true, type: .user))
        message = ""
        isLoading = true
        
        // Call API
        Task {
            do {
                let request = CompatibilityFollowUpRequest(
                    query: userQuestion,
                    sessionId: sessionId,
                    userEmail: "user@example.com"
                )
                
                let response = try await service.followUp(request: request)
                
                // Handle response
                if response.status == "redirect" {
                    await handleRedirect(query: userQuestion, target: response.target ?? "Person", birthData: response.birthData)
                } else if response.status == "blocked" {
                    await MainActor.run {
                        isLoading = false
                        messages.append(CompatChatMessage(content: response.message ?? "Query not allowed", isUser: false, type: .error))
                    }
                } else if let answer = response.answer {
                    await MainActor.run {
                        isLoading = false
                        messages.append(CompatChatMessage(content: answer, isUser: false, type: .ai))
                    }
                } else if let msg = response.message {
                    await MainActor.run {
                        isLoading = false
                        messages.append(CompatChatMessage(content: msg, isUser: false, type: .info))
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                        messages.append(CompatChatMessage(content: "I couldn't process that. Please try again.", isUser: false, type: .error))
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    messages.append(CompatChatMessage(content: "Error: \(error.localizedDescription)", isUser: false, type: .error))
                }
            }
        }
    }
    
    // MARK: - Handle Redirect
    private func handleRedirect(query: String, target: String, birthData: BirthDetails?) async {
        await MainActor.run {
            messages.append(CompatChatMessage(content: "Analyzing \(target)'s chart individually...", isUser: false, type: .info))
        }
        
        let details: BirthDetails?
        if let bd = birthData {
            details = bd
        } else {
            if target.lowercased().contains("boy") {
                details = result.analysisData?.boy?.details
            } else {
                details = result.analysisData?.girl?.details
            }
        }
        
        guard let bd = details else {
            await MainActor.run {
                isLoading = false
                messages.append(CompatChatMessage(content: "Birth data not available for \(target).", isUser: false, type: .error))
            }
            return
        }
        
        do {
            let predictionBirthData = BirthData(
                dob: bd.dob,
                time: bd.time,
                latitude: bd.lat,
                longitude: bd.lon,
                cityOfBirth: bd.place,
                ayanamsa: "lahiri",
                houseSystem: "equal"
            )
            
            let predictionRequest = PredictionRequest(query: query, birthData: predictionBirthData)
            let predictionResponse = try await predictionService.predict(request: predictionRequest)
            
            await MainActor.run {
                isLoading = false
                messages.append(CompatChatMessage(content: "**\(target)'s Analysis:**\n\n\(predictionResponse.answer)", isUser: false, type: .ai))
            }
        } catch {
            await MainActor.run {
                isLoading = false
                messages.append(CompatChatMessage(content: "Error analyzing \(target): \(error.localizedDescription)", isUser: false, type: .error))
            }
        }
    }
}

// MARK: - Compat Chat Message Model
struct CompatChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let type: MessageType
    let timestamp = Date()
    
    enum MessageType: String, Codable {
        case user, ai, info, error
    }
}

// MARK: - Compat Message Bubble
struct CompatMessageBubble: View {
    let message: CompatChatMessage
    let accentGold: Color
    let accentPurple: Color
    
    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 50) }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                if message.isUser {
                    Text(message.content)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                } else {
                    MarkdownTextView(
                        content: message.content,
                        textColor: textColor,
                        fontSize: 14
                    )
                }
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(bubbleBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            if !message.isUser { Spacer(minLength: 50) }
        }
    }
    
    private var textColor: Color {
        switch message.type {
        case .error: return .red.opacity(0.9)
        case .info: return accentGold
        default: return .white.opacity(0.9)
        }
    }
    
    @ViewBuilder
    private var bubbleBackground: some View {
        if message.isUser {
            LinearGradient(colors: [accentPurple, accentPurple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            Color(red: 0.15, green: 0.15, blue: 0.22)
        }
    }
}

// MARK: - Compat Typing Indicator
struct CompatTypingIndicator: View {
    let accentPurple: Color
    @State private var dotScale: [CGFloat] = [1, 1, 1]
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(accentPurple)
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotScale[i])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(red: 0.15, green: 0.15, blue: 0.22))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Spacer()
        }
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        for i in 0..<3 {
            withAnimation(.easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15)) {
                dotScale[i] = 1.4
            }
        }
    }
}

// MARK: - Premium Action Chip
struct PremiumActionChip: View {
    let icon: String
    let label: String
    let gradient: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                LinearGradient(colors: gradient.map { $0.opacity(0.25) }, startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(colors: gradient.map { $0.opacity(0.5) }, startPoint: .leading, endPoint: .trailing),
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Quick Chip
struct QuickChip: View {
    let emoji: String
    let text: String
    
    var body: some View {
        HStack(spacing: 3) {
            Text(emoji).font(.system(size: 10))
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color("NavyPrimary"))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 12).stroke(Color("GoldAccent").opacity(0.25), lineWidth: 1))
    }
}

// MARK: - Markdown Preprocessor for Reports
/// Converts markdown headers and tables to inline-compatible format
/// Swift's AttributedString only supports inline markdown (bold, italic)
private func preprocessMarkdownForReport(_ text: String) -> String {
    var result = text
    
    // Convert headers to bold: ### Header -> **Header**
    let lines = result.components(separatedBy: "\n")
    var processedLines: [String] = []
    
    for line in lines {
        var processedLine = line
        
        // Skip table separator lines (|---|---|)
        if line.contains("|--") || line.contains("--|") {
            continue
        }
        
        // Remove leading/trailing pipes from table rows and format as readable text
        if line.hasPrefix("|") && line.hasSuffix("|") {
            processedLine = line
                .dropFirst()
                .dropLast()
                .replacingOccurrences(of: "|", with: "  •  ")
                .trimmingCharacters(in: .whitespaces)
        }
        
        // Convert ### Header to **Header** (bold)
        if processedLine.hasPrefix("#### ") {
            processedLine = "**" + String(processedLine.dropFirst(5)) + "**"
        } else if processedLine.hasPrefix("### ") {
            processedLine = "\n**" + String(processedLine.dropFirst(4)) + "**"
        } else if processedLine.hasPrefix("## ") {
            processedLine = "\n**" + String(processedLine.dropFirst(3)) + "**"
        } else if processedLine.hasPrefix("# ") {
            processedLine = "\n**" + String(processedLine.dropFirst(2)) + "**"
        }
        
        // Remove horizontal rules
        if processedLine.trimmingCharacters(in: .whitespaces) == "---" {
            processedLine = ""
        }
        
        processedLines.append(processedLine)
    }
    
    return processedLines.joined(separator: "\n")
}

// MARK: - Preview
#Preview {
    CompatibilityResultView(
        result: CompatibilityResult(
            totalScore: 31,
            maxScore: 36,
            kutas: [
                KutaDetail(name: "Varna", maxPoints: 1, points: 1),
                KutaDetail(name: "Vashya", maxPoints: 2, points: 2),
                KutaDetail(name: "Tara", maxPoints: 3, points: 2),
                KutaDetail(name: "Yoni", maxPoints: 4, points: 3),
                KutaDetail(name: "Maitri", maxPoints: 5, points: 0),
                KutaDetail(name: "Gana", maxPoints: 6, points: 5),
                KutaDetail(name: "Bhakoot", maxPoints: 7, points: 2),
                KutaDetail(name: "Nadi", maxPoints: 8, points: 7)
            ],
            summary: "Excellent match.",
            recommendation: ""
        ),
        boyName: "Prabhu",
        girlName: "Guru",
        boyDob: "28/12/2001",
        girlDob: "28/12/2025",
        boyCity: "Tendukheda",
        girlCity: "Raghuji Nagar",
        onNewAnalysis: {},
        onBack: {}
    )
}
