import SwiftUI
import Combine

/// Premium "Sensory Home" Screen (Divine Luxury Edition)
struct HomeView: View {
    // MARK: - Callbacks
    var onQuestionSelected: ((String) -> Void)? = nil
    var onChatHistorySelected: ((String) -> Void)? = nil
    var onMatchHistorySelected: ((CompatibilityHistoryItem) -> Void)? = nil
    
    // MARK: - State
    @State private var viewModel = HomeViewModel()
    @State private var showProfile = false
    @State private var contentOpacity: Double = 0
    @State private var headerOffset: CGFloat = -20
    
    // Sound Manager
    @ObservedObject private var soundManager = SoundManager.shared
    
    // Profile Context
    let profileContext = ProfileContextManager.shared
    @ObservedObject private var quotaManager = QuotaManager.shared
    @State private var showProfileSwitcher = false
    @State private var showUpgradePrompt = false
    @State private var showGuestSignInSheet = false  // Guest sign-in prompt for Switch Profile
    
    /// Check if current user is a guest (generated email with @daa.com or legacy @gen.com)
    private var isGuestUser: Bool {
        let email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        // Guest emails use format: YYYYMMDD_HHMM_CityPrefix_LatInt_LngInt@daa.com
        return email.isEmpty || email.contains("guest") || email.hasSuffix("@daa.com") || email.hasSuffix("@gen.com")
    }
    
    /// User initials for profile avatar (e.g., "PK" for "Prabhu Kushwaha", "P" for "Prabhu")
    private var userInitials: String {
        let name = profileContext.activeProfileName
        let words = name.split(separator: " ")
        if words.isEmpty {
            return "?"
        } else if words.count == 1 {
            // Single name: show first letter
            return String(words[0].prefix(1)).uppercased()
        } else {
            // Multiple words: show first letter of first two words
            let first = String(words[0].prefix(1)).uppercased()
            let second = String(words[1].prefix(1)).uppercased()
            return first + second
        }
    }
    
    // Menu Sheet States
    @State private var showHistorySheet = false
    @State private var selectedFilter: String = "All" // Filter State
    private let filterOptions = ["All", "Good", "Steady", "Caution"]
    
    // Life Area Popup State
    @State private var selectedLifeArea: LifeAreaItem? = nil
    
    // Yoga Detail Popup State (presented at ZStack level to avoid clipping)
    @State private var selectedYogaForPopup: YogaDetail? = nil
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // 1. Theme Background (Cosmic/Parallax)
            // Background
            CosmicBackgroundView()
                .ignoresSafeArea()
            
            // GLOBAL AMBIENT SPOTLIGHT REMOVED
            // Returning to crisp black background for professional contrast.
            
            VStack(spacing: 0) {
                // A. STICKY Header (Fixed at Top - iOS HIG)
                headerSection
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .background(Color.clear) // Transparent header
                    .offset(y: headerOffset)
                
                // 2. Scrollable Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) { // iOS HIG: 24pt between major sections
                        
                        // Offline indicator
                        OfflineBanner()
                        
                        if viewModel.isLoading {
                            VStack(spacing: 20) {
                                // Animated cosmic icon
                                Image(systemName: "sparkles")
                                    .font(.system(size: 36, weight: .light))
                                    .foregroundColor(AppTheme.Colors.gold)
                                    .symbolEffect(.pulse, options: .repeating)
                                
                                VStack(spacing: 8) {
                                    Text("syncing_cosmic_data".localized)
                                        .font(AppTheme.Fonts.title(size: 18))
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    
                                    Text("restoring_your_insights".localized)
                                        .font(AppTheme.Fonts.body(size: 14))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                                
                                ProgressView()
                                    .tint(AppTheme.Colors.gold)
                                    .scaleEffect(1.2)
                            }
                            .frame(maxWidth: .infinity, minHeight: 300)
                            .padding(.top, 60)
                        } else {
                            // 1. Hero: Cosmic Vibe
                            insightHeroSection
                            
                            // 2. How is my day today? (Life Areas with filters)
                            lifeAreasGridSection
                            
                            // 3. What's in my mind? (Quick Questions)
                            whatsInMyMindSection
                            
                            // 4. Current Dasha
                            if let dasha = viewModel.dashaInsight {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Current Dasha")
                                        .font(AppTheme.Fonts.premiumDisplay(size: 18))
                                        .goldGradient()
                                    
                                    DashaInsightCard(dasha: dasha)
                                }
                            }
                            
                            // 5. Current Transit Influences (Horizontal Scroll)
                            if !viewModel.transitInfluences.isEmpty {
                                TransitInfluencesSection(transits: viewModel.transitInfluences)
                            }
                            
                            // 6. Dosha Status
                            // doshaStatusSection // Removed per user request
                            
                            // 7. Yoga Cards
                            yogaHighlightsSection
                            
                            Spacer(minLength: 20)
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 12) // 8pt grid: 1.5 units
                }
                .padding(.bottom, 90) // Reserve space for Transparent Tab Bar (Content won't scroll behind it)
                .refreshable {
                    await viewModel.loadHomeData()
                }
            }
            .opacity(contentOpacity)
            // Life Area Brief Popup Overlay
            if let selected = selectedLifeArea {
                LifeAreaBriefPopup(
                    area: selected.area,
                    status: selected.status.status,
                    brief: selected.status.brief,
                    iconName: iconName(for: selected.area),
                    onAskMore: {
                        let contextualQuestion = "You predicted: '\(selected.status.brief)' for my \(selected.area) today. Can you provide more detailed insights and guidance?"
                        selectedLifeArea = nil
                        onQuestionSelected?(contextualQuestion)
                    },
                    onDismiss: {
                        selectedLifeArea = nil
                    }
                )
                .transition(.opacity)
            }
            
            // Yoga Detail Popup Overlay (presented at ZStack level to avoid ScrollView clipping)
            if let yoga = selectedYogaForPopup {
                YogaDetailPopup(
                    yoga: yoga,
                    onAskMore: {
                        // Build rich LLM context
                        let statusText = yoga.status == "A" ? "Active" : (yoga.status == "R" ? "Reduced" : "Cancelled")
                        let typeText = yoga.isDosha ? "dosha (negative combination)" : "yoga (positive combination)"
                        
                        var contextParts: [String] = [
                            "I have \(yoga.displayName) in my birth chart.",
                            "",
                            "Details:",
                            "- Type: \(typeText)",
                            "- Category: \(yoga.category ?? "Unknown")",
                            "- Status: \(statusText)",
                            "- Strength: \(Int(yoga.strength * 100))%",
                            "- Planets Involved: \(yoga.planets)",
                            "- Houses Involved: \(yoga.houses)"
                        ]
                        
                        if let formation = yoga.formation, !formation.isEmpty {
                            contextParts.append("- Formation: \(formation)")
                        }
                        
                        if let reason = yoga.reason, !reason.isEmpty, yoga.status != "A" {
                            // Transform exception keys to human-readable text
                            let localizedReason = DoshaDescriptions.localizeExceptionKeys(in: reason)
                            contextParts.append("- \(yoga.status == "R" ? "Reduction" : "Cancellation") Reason: \(localizedReason)")
                        }
                        
                        contextParts.append("")
                        contextParts.append("Please explain:")
                        contextParts.append("1. What this \(yoga.isDosha ? "dosha" : "yoga") means for my life")
                        
                        if yoga.status == "A" {
                            if yoga.isDosha {
                                contextParts.append("2. What challenges it may bring and any remedies")
                            } else {
                                contextParts.append("2. How to maximize its benefits")
                            }
                        } else {
                            contextParts.append("2. Why it is \(statusText.lowercased()) and what this means")
                            contextParts.append("3. Any remedies or actions I can take")
                        }
                        
                        let contextualQuestion = contextParts.joined(separator: "\n")
                        
                        selectedYogaForPopup = nil
                        onQuestionSelected?(contextualQuestion)
                    },
                    onDismiss: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedYogaForPopup = nil
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadHomeData()
        }
        .onAppear {
            startEntranceAnimation()
        }
        .onReceive(NotificationCenter.default.publisher(for: .activeProfileChanged)) { _ in
            // Reload home data when profile switches
            // Uses profile-scoped cache, so API only called once/day per profile
            Task {
                await viewModel.loadHomeData()
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showHistorySheet) {
            HistoryView(
                onChatSelected: onChatHistorySelected,
                onMatchSelected: onMatchHistorySelected
            )
        }
        .sheet(isPresented: $showProfileSwitcher) {
            ProfileSwitcherSheet()
        }
        .sheet(isPresented: $showUpgradePrompt) {
            SubscriptionView()
        }
        .sheet(isPresented: $showGuestSignInSheet) {
            GuestSignInPromptView(
                message: "sign_in_to_switch_profiles".localized,
                onBack: { showGuestSignInSheet = false }
            )
        }
    }
    
    // MARK: - Animations
    private func startEntranceAnimation() {
        withAnimation(.easeOut(duration: 0.8)) {
            contentOpacity = 1.0
            headerOffset = 0
        }
    }
    
    // MARK: - Components
    
    // A. 3D Gold Header
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Profile Context Indicator (always visible - shows active profile)
            Button(action: {
                HapticManager.shared.play(.light)
                // GUEST RULE: Guests must sign in first, not upgrade
                if isGuestUser {
                    showGuestSignInSheet = true
                } else if quotaManager.hasFeature(.switchProfile) {
                    showProfileSwitcher = true
                } else {
                    showUpgradePrompt = true
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: profileContext.isUsingSelf ? "person.crop.circle" : "person.crop.circle.badge.checkmark")
                        .font(.caption)
                    
                    Text(profileContext.isUsingSelf ? profileContext.activeProfileName : "Viewing as \(profileContext.activeProfileName)")
                        .font(AppTheme.Fonts.caption())
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(AppTheme.Colors.gold)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(AppTheme.Colors.gold.opacity(0.15))
                        .overlay(Capsule().stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1))
                )
            }
            .padding(.bottom, 8)
            
            HStack {
                // History Button (Left)
                Button(action: {
                    HapticManager.shared.play(.light)
                    showHistorySheet = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.clear) // Transparent
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1))
                        
                        Image(systemName: "clock.arrow.circlepath")
                            .font(AppTheme.Fonts.title(size: 18))
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                }
                
                Spacer()
                
                // "Destiny" Logo (always shown)
                Image("destiny_home")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 32)
                    .shadow(color: AppTheme.Colors.gold.opacity(0.5), radius: 10, x: 0, y: 5)
                    .premiumInertia(intensity: 15)
                
                Spacer()
                
                // Right Side Buttons
                HStack(spacing: 12) {
                    // Sound Toggle
                    if AppTheme.Features.showSoundToggle {
                        Button(action: {
                            HapticManager.shared.play(.light)
                            soundManager.toggleSound()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.clear) // Transparent
                                    .frame(width: 44, height: 44)
                                    .overlay(Circle().stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1))
                                
                                Image(systemName: soundManager.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                    .font(AppTheme.Fonts.body(size: 16))
                                    .foregroundColor(AppTheme.Colors.gold)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                        }
                    }
                    
                    // Profile Button
                    Button(action: {
                        HapticManager.shared.play(.light)
                        showProfile = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.gold) // Filled gold background
                                .frame(width: 44, height: 44)
                            
                            // User initials
                            Text(userInitials)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2)) // Dark text on gold
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
        }
    }
    
    // B. Hero Section (Divine Glass Slab - Visual First)
    private var insightHeroSection: some View {
        ZStack(alignment: .topTrailing) {
            // Card Content
            VStack(alignment: .leading, spacing: 8) {
                // Title - needs extra padding to clear orb
                Text("Today's Cosmic Vibe")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.88, blue: 0.51), Color(red: 0.72, green: 0.54, blue: 0.27)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                    .padding(.trailing, 48) // Just enough to clear the orb
                
                // Body Text - minimal padding, flows naturally below orb
                Text(viewModel.dailyInsight.isEmpty ? "With Mercury and Venus active in the dasha, communication and relationships will play a significant role today. Focus on maintaining harmony..." : viewModel.dailyInsight)
                    .font(AppTheme.Fonts.body(size: 13))
                    .foregroundColor(Color.white.opacity(0.95))
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 20) // Minimal buffer around orb area
            }
            .padding(24)
            
            // Floating Orb (overlayed, doesn't affect text flow)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1.0, green: 0.95, blue: 0.7),
                                Color(red: 1.0, green: 0.85, blue: 0.45)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 35
                        )
                    )
                    .shadow(color: AppTheme.Colors.gold.opacity(0.6), radius: 10, x: 0, y: 0)
                
                VStack(spacing: 0) {
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(red: 0.2, green: 0.15, blue: 0.05))
                        .padding(.top, 4)
                    
                    Text("ASC")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(Color(red: 0.2, green: 0.15, blue: 0.05))
                    
                    Text(viewModel.ascendantSign)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Color(red: 0.2, green: 0.15, blue: 0.05))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.bottom, 3)
                }
            }
            .frame(width: 60, height: 60) // Slightly smaller orb
            .offset(x: -8, y: 8) // Optimized corner placement
        }
        // Background container
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.29, green: 0.29, blue: 0.33), location: 0.0),
                            .init(color: Color(red: 0.56, green: 0.50, blue: 0.37), location: 0.5),
                            .init(color: Color(red: 0.72, green: 0.54, blue: 0.27), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 15, x: 0, y: 8)
        )
        .padding(.horizontal, 0)
        .padding(.top, 20)
        .onAppear {
            HapticManager.shared.playHeartbeat()
        }
    }
    
    // Decorative sparkles for hero card
    private var sparkleDecorations: some View {
        ZStack {
            Image(systemName: "sparkle")
                .font(.system(size: 10))
                .foregroundColor(AppTheme.Colors.goldLight.opacity(0.7))
                .offset(x: -120, y: -50)
            
            Image(systemName: "sparkle")
                .font(.system(size: 8))
                .foregroundColor(AppTheme.Colors.gold.opacity(0.5))
                .offset(x: 130, y: -40)
            
            Image(systemName: "sparkle")
                .font(.system(size: 6))
                .foregroundColor(AppTheme.Colors.goldLight.opacity(0.6))
                .offset(x: -100, y: 45)
            
            Image(systemName: "sparkle")
                .font(.system(size: 7))
                .foregroundColor(AppTheme.Colors.gold.opacity(0.4))
                .offset(x: 110, y: 50)
        }
    }
    
    // Helper to get zodiac symbol and full name
    private func zodiacSymbol(for sign: String) -> String {
        let map: [String: String] = [
            "Ar": "♈\u{FE0E}", "Aries": "♈\u{FE0E}",
            "Ta": "♉\u{FE0E}", "Taurus": "♉\u{FE0E}",
            "Ge": "♊\u{FE0E}", "Gemini": "♊\u{FE0E}",
            "Cn": "♋\u{FE0E}", "Cancer": "♋\u{FE0E}", "Ca": "♋\u{FE0E}",
            "Le": "♌\u{FE0E}", "Leo": "♌\u{FE0E}",
            "Vi": "♍\u{FE0E}", "Virgo": "♍\u{FE0E}",
            "Li": "♎\u{FE0E}", "Libra": "♎\u{FE0E}",
            "Sc": "♏\u{FE0E}", "Scorpio": "♏\u{FE0E}",
            "Sg": "♐\u{FE0E}", "Sagittarius": "♐\u{FE0E}", "Sag": "♐\u{FE0E}",
            "Cp": "♑\u{FE0E}", "Capricorn": "♑\u{FE0E}", "Cap": "♑\u{FE0E}",
            "Aq": "♒\u{FE0E}", "Aquarius": "♒\u{FE0E}",
            "Pi": "♓\u{FE0E}", "Pisces": "♓\u{FE0E}"
        ]
        return map[sign] ?? map[sign.prefix(2).capitalized] ?? "☽"
    }
    
    private func fullZodiacName(for sign: String) -> String {
        let fullMap: [String: String] = [
            "Ar": "Aries", "Aries": "Aries",
            "Ta": "Taurus", "Taurus": "Taurus",
            "Ge": "Gemini", "Gemini": "Gemini",
            "Cn": "Cancer", "Cancer": "Cancer",
            "Le": "Leo", "Leo": "Leo",
            "Vi": "Virgo", "Virgo": "Virgo",
            "Li": "Libra", "Libra": "Libra",
            "Sc": "Scorpio", "Scorpio": "Scorpio",
            "Sg": "Sagittarius", "Sagittarius": "Sagittarius", "Sag": "Sagittarius",
            "Cp": "Capricorn", "Capricorn": "Capricorn", "Cap": "Capricorn",
            "Aq": "Aquarius", "Aquarius": "Aquarius",
            "Pi": "Pisces", "Pisces": "Pisces"
        ]
        return fullMap[sign] ?? sign
    }
    
    // C. Cosmic Status Strip
    private var cosmicStatusStrip: some View {
        let transits = viewModel.currentTransits.map { transit in
            (planet: transit.planet, sign: transit.sign)
        }
        return CosmicStatusStrip(
            currentDasha: viewModel.currentDasha,
            transits: transits.isEmpty ? [
                ("Sun", "Leo"), ("Moon", "Capricorn"), ("Mars", "Scorpio")
            ] : transits
        )
        .premiumInertia(intensity: 0.5)
    }
    
    // E. How is my day today? (formerly Life Areas)
    // selectedFilter and filterOptions already declared at top of struct
    
    private var lifeAreasGridSection: some View {
        VStack(spacing: 8) { // iOS HIG: 8pt internal spacing
            // Header (no extra padding - parent handles it)
            Text("How is my day today?")
                .font(AppTheme.Fonts.premiumDisplay(size: 18))
                .goldGradient()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Filter Tabs (Compact)
            HStack(spacing: 8) {
                ForEach(filterOptions, id: \.self) { filter in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                        HapticManager.shared.play(.light)
                    }) {
                        Text(filter)
                            .font(AppTheme.Fonts.caption(size: 11))
                            .fontWeight(selectedFilter == filter ? .semibold : .regular)
                            .foregroundColor(selectedFilter == filter ? AppTheme.Colors.gold : AppTheme.Colors.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter ?
                                          AppTheme.Colors.gold.opacity(0.1) : Color.clear)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                selectedFilter == filter ?
                                                AppTheme.Colors.gold.opacity(0.5) :
                                                AppTheme.Colors.textSecondary.opacity(0.2),
                                                lineWidth: 1
                                            )
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            
            // Horizontal Scrolling Celestial Orbs (filtered)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) { // Edge-to-edge orbs
                    // Calculate dynamic size for 3.5 items visible
                    let screenWidth = UIScreen.main.bounds.width
                    // Total width available minus padding (if any significant padding exists, but here we want edge-to-edge calculation)
                    // We target 3.5 items visible. Item width = orbSize * 1.4
                    // So visibleWidth = 3.5 * (orbSize * 1.4)
                    // orbSize = visibleWidth / (3.5 * 1.4)
                    let dynamicSize = screenWidth / (3.5 * 1.4)
                    
                    ForEach(filteredAreas, id: \.area) { item in
                        CelestialOrbView(
                            icon: iconName(for: item.area),
                            title: item.area,
                            status: item.status.status,
                            size: dynamicSize
                        ) {
                            HapticManager.shared.play(.light)
                            withAnimation(.spring(response: 0.4)) {
                                selectedLifeArea = item
                            }
                        }
                    }
                }
                .padding(.horizontal, 12) // Match parent edge
                .padding(.vertical, 2)
            }
            .padding(.horizontal, -12) // Negative margin to extend to edges
        }
    }
    
    // F. What's in my mind? (Quick Questions - taps go to Chat)
    // F. What's in my mind? (Compact List View)
    private var whatsInMyMindSection: some View {
        VStack(alignment: .leading, spacing: 8) { // iOS HIG: 8pt internal spacing
            // Header (no extra padding - parent handles it)
            Text("What's in my mind?")
                .font(AppTheme.Fonts.premiumDisplay(size: 18))
                .goldGradient()
            
            // Quick Questions (Compact List)
            let questions = viewModel.suggestedQuestions.isEmpty ?
                ["When will I get married?", "Best career direction?", "Financial outlook?", "Health check"] :
                Array(viewModel.suggestedQuestions.prefix(4))
            
            VStack(spacing: 8) { // iOS HIG: 8pt grid
                ForEach(questions, id: \.self) { question in
                    Button(action: {
                        HapticManager.shared.play(.light)
                        onQuestionSelected?(question)
                    }) {
                        HStack {
                            Text(question)
                                .font(AppTheme.Fonts.caption(size: 13))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AppTheme.Colors.gold.opacity(0.6))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(AppTheme.Colors.gold.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // G. Transit Alerts
    private var transitAlertsSection: some View {
        TransitAlertCard(transits: viewModel.currentTransits)
            .padding(.horizontal, 12)
    }
    
    // H. Dosha Status
    private var doshaStatusSection: some View {
        DoshaStatusSection(
            mangalDosha: viewModel.doshaStatus.mangal,
            kalaSarpa: viewModel.doshaStatus.kalaSarpa
        )
    }
    
    // I. Yoga Highlights
    private var yogaHighlightsSection: some View {
        YogaHighlightCard(
            yogas: viewModel.yogaCombinations,
            onQuestionSelected: onQuestionSelected,
            onYogaTapped: { yoga in
                withAnimation(.spring(response: 0.35)) {
                    selectedYogaForPopup = yoga
                }
            }
        )
    }
    
    // J. Dasha Widget
    private var dashaWidgetSection: some View {
        DashaProgressWidget(
            currentPeriod: viewModel.currentDashaPeriod,
            upcomingPeriod: viewModel.upcomingDashaPeriod
        )
    }
    
    // Icon helper for orbs
    private func iconName(for area: String) -> String {
        switch area.lowercased() {
        case "career": return "briefcase.fill"
        case "relationship": return "heart.fill"
        case "finance": return "banknote.fill"
        case "health": return "cross.case.fill"
        case "family": return "house.fill"
        case "education": return "book.fill"
        case "investment": return "chart.line.uptrend.xyaxis"
        case "sudden events": return "star.fill"
        default: return "star.fill"
        }
    }
    
    // MARK: - Filtering Helpers
    struct LifeAreaItem {
        let area: String
        let status: LifeAreaStatus
    }
    
    var allAreas: [LifeAreaItem] {
        let areas = viewModel.lifeAreas
        if areas.isEmpty { return [] }
        
        // Helper to safely get status (API uses lowercase keys)
        func getStatus(_ key: String) -> LifeAreaStatus {
            return areas[key.lowercased()] ?? areas[key] ?? LifeAreaStatus(status: "Neutral", brief: "Balanced energy")
        }
        
        // API keys are lowercase, but we display Title Case
        return [
            LifeAreaItem(area: "Career", status: getStatus("career")),
            LifeAreaItem(area: "Relationship", status: getStatus("relationship")),
            LifeAreaItem(area: "Finance", status: getStatus("finance")),
            LifeAreaItem(area: "Health", status: getStatus("health")),
            LifeAreaItem(area: "Family", status: getStatus("family")),
            LifeAreaItem(area: "Education", status: getStatus("education")),
            LifeAreaItem(area: "Investment", status: getStatus("investment")),
            LifeAreaItem(area: "Sudden Events", status: getStatus("sudden_events"))
        ]
    }
    
    var filteredAreas: [LifeAreaItem] {
        if selectedFilter == "All" { return allAreas }
        return allAreas.filter { item in
            let s = item.status.status.lowercased()
            if selectedFilter == "Good" { return s == "good" || s == "excellent" }
            if selectedFilter == "Steady" { return s == "steady" || s == "neutral" }
            if selectedFilter == "Caution" { return s == "caution" || s == "difficult" || s == "challenging" }
            return false
        }
    }
}

// MARK: - Subviews

/// Luxury 3-Column Tile (Compact Crystal)
struct LifeAreaLuxuryTile: View {
    let area: String
    let status: LifeAreaStatus
    let action: (String) -> Void
    
    var body: some View {
        Button(action: {
            action("Tell me about \(area)")
        }) {
            // WRAPPER: The Deep 3D Crystal
            DivineGlassCard(cornerRadius: 16) {
                VStack(spacing: 8) {
                    // Icon
                    Image(systemName: iconName)
                        .font(.system(size: 24, weight: .semibold)) // Slightly smaller for 3-col
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Colors.goldLight, AppTheme.Colors.gold],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: AppTheme.Colors.gold.opacity(0.3), radius: 5)
                    
                    // Title
                    Text(area.localized)
                        .font(AppTheme.Fonts.caption(size: 12))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80) // Compact Square-ish
                .overlay(alignment: .bottomTrailing) {
                    // Chat Indicator (Sparkle/Bubble) with Gold Gradient
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Colors.goldLight, AppTheme.Colors.gold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(6)
                        .offset(x: 4, y: 4)
                        .opacity(0.9)
                        .shadow(color: AppTheme.Colors.gold.opacity(0.5), radius: 2)
                }
                .overlay(alignment: .topTrailing) {
                    // Status Dot (Subtle)
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                        .padding(8)
                        .shadow(color: statusColor.opacity(0.8), radius: 3)
                }
            }
            .frame(height: 110)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // Helpers
    var iconName: String {
        switch area.lowercased() {
        case "career": return "briefcase.fill"
        case "relationship": return "heart.fill"
        case "finance": return "banknote.fill"
        case "health": return "heart.text.square.fill"
        case "family": return "house.fill"
        case "education": return "book.fill"
        case "investment": return "chart.line.uptrend.xyaxis"
        case "sudden events": return "star.fill"
        default: return "star.fill"
        }
    }
    
    var statusColor: Color {
        switch status.status.lowercased() {
        case "good", "excellent": return AppTheme.Colors.success
        case "steady", "neutral": return AppTheme.Colors.warning
        case "caution", "difficult", "challenging": return AppTheme.Colors.error
        default: return AppTheme.Colors.textSecondary
        }
    }
}

#Preview {
    HomeView()
}
