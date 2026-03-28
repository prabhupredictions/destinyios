import SwiftUI
import Combine

/// Premium "Sensory Home" Screen (Divine Luxury Edition)
struct HomeView: View {
    // MARK: - State & Dependencies
    var viewModel: HomeViewModel
    
    // MARK: - Callbacks
    var onQuestionSelected: ((String) -> Void)? = nil
    var onChatHistorySelected: ((String) -> Void)? = nil
    var onMatchHistorySelected: ((CompatibilityHistoryItem) -> Void)? = nil
    var onMatchGroupHistorySelected: ((ComparisonGroup) -> Void)? = nil
    
    // Local UI State
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
    
    // Notification Inbox State
    @State private var showNotificationInbox = false
    @ObservedObject private var notificationService = NotificationInboxService.shared
    
    
    // Environment for detecting app foreground/background
    @Environment(\.scenePhase) private var scenePhase
    
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
                    VStack(spacing: 20) { // Compact premium spacing between major sections
                        
                        // Offline indicator
                        OfflineBanner()
                        
                        // Error banner with retry option
                        if let errorMessage = viewModel.errorMessage {
                            VStack(spacing: 12) {
                                HStack(spacing: 10) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(AppTheme.Colors.gold)
                                    
                                    Text(errorMessage)
                                        .font(AppTheme.Fonts.body(size: 14))
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Button(action: {
                                    HapticManager.shared.play(.light)
                                    Task {
                                        await viewModel.loadHomeData(force: true)
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 12, weight: .semibold))
                                        Text("retry_action".localized)
                                            .font(AppTheme.Fonts.caption(size: 13))
                                    }
                                    .foregroundColor(AppTheme.Colors.textOnGold)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        AppTheme.Colors.premiumCardGradient
                                            .clipShape(Capsule())
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppTheme.Colors.error.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(AppTheme.Colors.error.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 4)
                        }
                        
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
                                    Text("almost_there".localized)
                                        .font(AppTheme.Fonts.caption(size: 14))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                                
                                ProgressView()
                                    .tint(AppTheme.Colors.gold)
                                    .scaleEffect(1.2)
                            }
                            .frame(maxWidth: .infinity, minHeight: 300)
                            .padding(.top, 60)
                        } else {
                            // 1. Life Area Story Orbs (Instagram-style, top of feed)
                            storyOrbsSection
                            
                            // 2. What's in my mind? (Quick Questions)
                            whatsInMyMindSection
                            
                            // 3. Current Dasha (Tappable → sends to chat)
                            if let dasha = viewModel.dashaInsight {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("current_dasha".localized)
                                        .font(AppTheme.Fonts.premiumDisplay(size: 18))
                                        .goldGradient()
                                    
                                    Button(action: {
                                        HapticManager.shared.play(.light)
                                        let localizedQuality = localizedDashaQuality(dasha.quality)
                                        let meaningPart = dasha.meaning != nil ? String(format: "context_dasha_phase_suggests".localized, dasha.meaning!) : ""
                                        let q = String(format: "context_dasha_question".localized, dasha.period, dasha.theme, localizedQuality, meaningPart)
                                        onQuestionSelected?(q)
                                    }) {
                                        DashaInsightCard(dasha: dasha)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            
                            // 4. Current Transit Influences (Tappable → sends to chat)
                            if !viewModel.transitInfluences.isEmpty {
                                TransitInfluencesSection(
                                    transits: viewModel.transitInfluences,
                                    onTransitTapped: { transit in
                                        HapticManager.shared.play(.light)
                                        let signName = localizedZodiacName(for: transit.sign)
                                        let localizedPlanet = localizedPlanetName(transit.planet)
                                        let q = String(format: "context_transit_question".localized, localizedPlanet, signName, transit.house, transit.description)
                                        onQuestionSelected?(q)
                                    }
                                )
                            }
                            
                            // 5. Dosha Status
                            // doshaStatusSection // Removed per user request
                            
                            // 6. Yoga Cards
                            yogaHighlightsSection
                            
                            Spacer(minLength: 20)
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 12) // 8pt grid: 1.5 units
                }
                .padding(.bottom, 90) // Reserve space for Transparent Tab Bar (Content won't scroll behind it)
                .refreshable {
                    await viewModel.loadHomeData(force: true)
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
                        let contextualQuestion = String(format: "context_life_area_question".localized, selected.status.brief, selected.area.localized)
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
                        let statusText = yoga.status == "A" ? "status_active".localized : (yoga.status == "R" ? "status_reduced".localized : "status_cancelled".localized)
                        let typeText = yoga.isDosha ? "type_dosha".localized : "type_yoga".localized
                        
                        var contextParts: [String] = [
                            String(format: "yoga_context_header".localized, yoga.localizedName),
                            "",
                            "yoga_context_details".localized,
                            String(format: "yoga_context_type".localized, typeText),
                            String(format: "yoga_context_category".localized, localizedYogaCategory(yoga.category)),
                            String(format: "yoga_context_status".localized, statusText),
                            String(format: "yoga_context_strength".localized, Int(yoga.strength * 100)),
                            String(format: "yoga_context_planets".localized, localizedPlanets(yoga.planets)),
                            String(format: "yoga_context_houses".localized, yoga.houses)
                        ]
                        
                        if let formation = yoga.formation, !formation.isEmpty {
                            contextParts.append(String(format: "yoga_context_formation".localized, formation))
                        }
                        
                        // Add outcome (What it means) if available
                        if let outcome = yoga.localizedOutcome, !outcome.isEmpty {
                            contextParts.append(String(format: "yoga_context_outcome".localized, outcome))
                        }
                        
                        if let reason = yoga.reason, !reason.isEmpty, yoga.status != "A" {
                            // Transform exception keys to human-readable text
                            let localizedReason = DoshaDescriptions.localizeExceptionKeys(in: reason)
                            let reasonKey = yoga.status == "R" ? "yoga_context_reduction_reason" : "yoga_context_cancellation_reason"
                            contextParts.append(String(format: reasonKey.localized, localizedReason))
                        }
                        
                        contextParts.append("")
                        contextParts.append("yoga_context_explain_header".localized)
                        contextParts.append(String(format: "yoga_context_question_1".localized, yoga.isDosha ? "dosha".localized : "yoga".localized))
                        
                        if yoga.status == "A" {
                            if yoga.isDosha {
                                contextParts.append("yoga_context_dosha_question_2".localized)
                            } else {
                                contextParts.append("yoga_context_yoga_question_2".localized)
                            }
                        } else {
                            contextParts.append(String(format: "yoga_context_inactive_question_2".localized, statusText.lowercased()))
                            contextParts.append("yoga_context_question_3".localized)
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
            // Single entry point for initial data load (runs once when view appears)
            await viewModel.loadHomeData()
            await notificationService.fetchUnreadCount()
        }
        .onAppear {
            startEntranceAnimation()
            
            // Request push notification permission
            PushNotificationService.shared.requestPermission()
            
        }
        .onReceive(NotificationCenter.default.publisher(for: .activeProfileChanged)) { _ in
            // Reset stale data + 24h cache guard so fresh data is fetched for new profile
            viewModel.resetForProfileSwitch()
            Task {
                await viewModel.loadHomeData()
                await notificationService.fetchUnreadCount()
            }
        }
        .onChange(of: scenePhase) {
            // Refresh notification badge when app returns to foreground
            if scenePhase == .active {
                Task {
                    await notificationService.fetchUnreadCount()
                    
                    // Only reload if the day changed across midnight.
                    // Same-day foreground returns rely on cached data — no network calls.
                    // Explicit events (pull-to-refresh, profile switch, premium upgrade) handle other refreshes.
                    if let cached = TodaysPredictionCache.shared.get() {
                        let fmt = DateFormatter()
                        fmt.dateFormat = "yyyy-MM-dd"
                        if let cachedDate = fmt.date(from: String(cached.targetDate.prefix(10))),
                           !Calendar.current.isDateInToday(cachedDate) {
                            print("[HomeView] App foregrounded on a new day. Refreshing predictions.")
                            await viewModel.loadHomeData(force: true)
                        }
                    }
                    // No cache: initial .task load will handle it on cold start
                }
            }
        }
        .onChange(of: quotaManager.isPremium) { newStatus in
            // Listen for subscription purchases: instantly unlock UI
            if newStatus {
                print("[HomeView] User upgraded to premium! Refreshing limits.")
                Task {
                    await viewModel.loadHomeData(force: true)
                }
            }
        }
        .sheet(isPresented: $showNotificationInbox) {
            NotificationInboxView(onNavigateToHome: {
                showNotificationInbox = false
                Task { await viewModel.loadHomeData(force: true) }
            })
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showHistorySheet) {
            HistoryView(
                onChatSelected: onChatHistorySelected,
                onMatchSelected: onMatchHistorySelected,
                onMatchGroupSelected: onMatchGroupHistorySelected
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
        .onReceive(NotificationCenter.default.publisher(for: .openProfileSettings)) { _ in
            showProfile = true
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
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            ZStack {
                // Center: "Destiny" Logo (always perfectly centered)
                Image("destiny_home")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 32)
                    .shadow(color: AppTheme.Colors.gold.opacity(0.5), radius: 10, x: 0, y: 5)
                    .premiumInertia(intensity: 15)
                
                // Left/Right buttons use HStack with Spacer
                HStack {
                    // History Button (Left)
                    Button(action: {
                        HapticManager.shared.play(.light)
                        showHistorySheet = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 44, height: 44)
                                .overlay(Circle().stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1))
                            
                            Image(systemName: "clock.arrow.circlepath")
                                .font(AppTheme.Fonts.title(size: 18))
                                .foregroundColor(AppTheme.Colors.gold)
                        }
                    }
                    .accessibilityLabel("history_title".localized)
                    
                    Spacer()
                    
                    // Right Side Buttons
                    HStack(spacing: 12) {
                        // Notification Bell
                        Button(action: {
                            HapticManager.shared.play(.light)
                            showNotificationInbox = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 44, height: 44)
                                    .overlay(Circle().stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1))
                                
                                Image(systemName: notificationService.unreadCount > 0 ? "bell.badge.fill" : "bell.fill")
                                    .font(AppTheme.Fonts.body(size: 16))
                                    .foregroundColor(AppTheme.Colors.gold)
                            }
                            .overlay(
                                // Badge
                                Group {
                                    if notificationService.unreadCount > 0 {
                                        Text(notificationService.unreadCount > 99 ? "99+" : "\(notificationService.unreadCount)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(AppTheme.Colors.error)
                                            .clipShape(Capsule())
                                            .offset(x: 12, y: -12)
                                            .accessibilityHidden(true)
                                    }
                                }
                            )
                        }
                        .accessibilityLabel(notificationService.unreadCount > 0 ? "Notifications, \(notificationService.unreadCount) unread" : "Notifications")
                        
                        // Sound Toggle
                        if AppTheme.Features.showSoundToggle {
                            Button(action: {
                                HapticManager.shared.play(.light)
                                soundManager.toggleSound()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: 44, height: 44)
                                        .overlay(Circle().stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1))
                                    
                                    Image(systemName: soundManager.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                        .font(AppTheme.Fonts.body(size: 16))
                                        .foregroundColor(AppTheme.Colors.gold)
                                        .contentTransition(.symbolEffect(.replace))
                                }
                            }
                            .accessibilityLabel(soundManager.isSoundEnabled ? "Sound on" : "Sound off")
                            .accessibilityHint("Double tap to toggle sound")
                        }
                        
                        // Profile Button
                        Button(action: {
                            HapticManager.shared.play(.light)
                            showProfile = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.Colors.gold)
                                    .frame(width: 44, height: 44)
                                
                                Text(userInitials)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                            }
                        }
                        .accessibilityLabel(String(format: "a11y_profile_name_format".localized, profileContext.activeProfileName))
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
                Text("todays_cosmic_vibe".localized)
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
                    
                    Text("asc_label".localized)
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
        .accessibilityHidden(true)
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
    
    /// Returns localized zodiac sign name using sign_* keys
    private func localizedZodiacName(for sign: String) -> String {
        let keyMap: [String: String] = [
            "Ar": "sign_ar", "Aries": "sign_ar",
            "Ta": "sign_ta", "Taurus": "sign_ta",
            "Ge": "sign_ge", "Gemini": "sign_ge",
            "Cn": "sign_ca", "Cancer": "sign_ca",
            "Le": "sign_le", "Leo": "sign_le",
            "Vi": "sign_vi", "Virgo": "sign_vi",
            "Li": "sign_li", "Libra": "sign_li",
            "Sc": "sign_sc", "Scorpio": "sign_sc",
            "Sg": "sign_sg", "Sagittarius": "sign_sg", "Sag": "sign_sg",
            "Cp": "sign_cp", "Capricorn": "sign_cp", "Cap": "sign_cp",
            "Aq": "sign_aq", "Aquarius": "sign_aq",
            "Pi": "sign_pi", "Pisces": "sign_pi"
        ]
        if let key = keyMap[sign] {
            return key.localized
        }
        return sign
    }
    
    /// Returns localized dasha quality string
    private func localizedDashaQuality(_ quality: String) -> String {
        switch quality.lowercased() {
        case "good": return "dasha_quality_good".localized
        case "steady": return "dasha_quality_steady".localized
        case "caution": return "dasha_quality_caution".localized
        default: return quality
        }
    }
    
    /// Returns localized yoga category name
    private func localizedYogaCategory(_ category: String?) -> String {
        guard let cat = category, !cat.isEmpty else { return "yoga_context_unknown".localized }
        let key = "yoga_cat_" + cat.lowercased().replacingOccurrences(of: " ", with: "_")
        let localized = key.localized
        // If key not found (returns same string), fall back to original
        return localized == key ? cat : localized
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
    
    // E. Instagram-style Story Orbs (Life Areas)
    private var storyOrbsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Greeting + subtitle
            VStack(alignment: .leading, spacing: 6) {
                Text(timeBasedGreeting + ", " + profileContext.activeProfileName)
                    .font(AppTheme.Fonts.premiumDisplay(size: 22))
                    .goldGradient()
                
                HStack(spacing: 6) {
                    Text(localizedAscendant)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .padding(.top, 16)
            
            // Horizontal story orbs — Instagram-style: last orb cropped as scroll hint
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(allAreas, id: \.area) { item in
                        StoryOrbView(
                            icon: iconName(for: item.area),
                            title: item.area,
                            status: item.status.status
                        ) {
                            HapticManager.shared.play(.light)
                            withAnimation(.spring(response: 0.4)) {
                                selectedLifeArea = item
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
            .padding(.horizontal, -12)
            
            // Guide text (centered, like Match screen)
            HStack(spacing: 5) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.Colors.gold.opacity(0.6))
                Text("tap_to_explore_day".localized)
                    .font(AppTheme.Fonts.caption(size: 11))
                    .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.8))
                    .italic()
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "good_morning".localized      // Until noon (12:00)
        case 12..<18: return "good_afternoon".localized    // Noon to 6pm
        default: return "good_evening".localized          // 6pm onward through the night
        }
    }
    
    private var localizedAscendant: String {
        let signKey = viewModel.ascendantSign.lowercased()
        let localizedSign: String
        switch signKey {
        case "aries": localizedSign = "sign_ar".localized
        case "taurus": localizedSign = "sign_ta".localized
        case "gemini": localizedSign = "sign_ge".localized
        case "cancer": localizedSign = "sign_ca".localized
        case "leo": localizedSign = "sign_le".localized
        case "virgo": localizedSign = "sign_vi".localized
        case "libra": localizedSign = "sign_li".localized
        case "scorpio": localizedSign = "sign_sc".localized
        case "sagittarius": localizedSign = "sign_sg".localized
        case "capricorn": localizedSign = "sign_cp".localized
        case "aquarius": localizedSign = "sign_aq".localized
        case "pisces": localizedSign = "sign_pi".localized
        default: localizedSign = viewModel.ascendantSign
        }
        return localizedSign + " " + "Ascendant".localized
    }
    
    // F. What's in my mind? (2×2 Golden Gradient Grid)
    private var whatsInMyMindSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("what_in_my_mind".localized)
                .font(AppTheme.Fonts.premiumDisplay(size: 18))
                .goldGradient()
                .accessibilityAddTraits(.isHeader)
            
            let questions = viewModel.suggestedQuestions.isEmpty ?
                ["When will I get married?", "Best career direction?", "Financial outlook?", "Health check"] :
                Array(viewModel.suggestedQuestions.prefix(4))
            
            // 2×2 Grid
            let rows = stride(from: 0, to: questions.count, by: 2).map { i in
                Array(questions[i..<min(i + 2, questions.count)])
            }
            
            VStack(spacing: 10) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { question in
                            Button(action: {
                                HapticManager.shared.play(.light)
                                onQuestionSelected?(question)
                            }) {
                                QuickQuestionCard(question: question)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
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
    
    // MARK: - Helper Functions for Localization
    
    /// Localizes a single planet name
    private func localizedPlanetName(_ planet: String) -> String {
        let key = planet.lowercased()
        switch key {
        case "sun": return "planet_sun".localized
        case "moon": return "planet_moon".localized
        case "mars": return "planet_mars".localized
        case "mercury": return "planet_mercury".localized
        case "jupiter": return "planet_jupiter".localized
        case "venus": return "planet_venus".localized
        case "saturn": return "planet_saturn".localized
        case "rahu": return "planet_rahu".localized
        case "ketu": return "planet_ketu".localized
        default: return planet
        }
    }
    
    /// Localizes a comma-separated list of planet names
    private func localizedPlanets(_ planets: String) -> String {
        let planetNames = planets.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let localized = planetNames.map { planet -> String in
            let key = planet.lowercased()
            switch key {
            case "sun": return "planet_sun".localized
            case "moon": return "planet_moon".localized
            case "mars": return "planet_mars".localized
            case "mercury": return "planet_mercury".localized
            case "jupiter": return "planet_jupiter".localized
            case "venus": return "planet_venus".localized
            case "saturn": return "planet_saturn".localized
            case "rahu": return "planet_rahu".localized
            case "ketu": return "planet_ketu".localized
            default: return planet
            }
        }
        return localized.joined(separator: ", ")
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
    HomeView(viewModel: HomeViewModel())
}

/// Standalone Quick Question Card — battery-optimized (static border, no pulse)
struct QuickQuestionCard: View {
    let question: String
    
    var body: some View {
        HStack(spacing: 10) {
            // Question text
            Text(question)
                .font(AppTheme.Fonts.caption(size: 13))
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(3)
                .minimumScaleFactor(0.9)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
            
            // Arrow CTA (static — pulse removed for battery optimization)
            Image(systemName: "arrow.forward.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.Colors.goldLight, AppTheme.Colors.gold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    AppTheme.Colors.gold.opacity(0.5),
                    lineWidth: 2
                )
        )
        .shadow(color: AppTheme.Colors.gold.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}
