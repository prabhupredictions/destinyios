import SwiftUI

/// Professional Profile screen with account info, settings navigation, and subscription status
/// Follows standard iOS design patterns with Midnight Gold theme
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var quotaManager = QuotaManager.shared
    @State private var profileContext = ProfileContextManager.shared
    @State private var authViewModel = AuthViewModel()
    
    // User preferences from storage
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("chartStyle") private var chartStyle: String = "north"
    @AppStorage("isGuest") private var isGuest: Bool = false
    @AppStorage("appLanguageCode") private var appLanguageCode: String = "en"
    
    // Navigation states for settings sheets
    @State private var showBirthDetails = false
    @State private var showLanguageSettings = false
    @State private var showAstrologySettings = false
    @State private var showChartStylePicker = false
    @State private var showSubscription = false
    @State private var showSignOutAlert = false
    @State private var showGuestSignInSheet = false  // Guest sign-in prompt for subscription
    @State private var showProfileSwitcher = false  // Switch Birth Chart sheet
    @State private var showUpgradePrompt = false  // Upgrade prompt for Switch Profile feature
    @State private var showGuestSignInForSwitch = false  // Guest sign-in prompt for Switch Profile
    @State private var showNotificationPreferences = false  // Notification preferences sheet
    @State private var showPartnerManager = false  // Partner manager sheet (Plus-only)
    @State private var showDeleteAccountSheet = false  // Delete account confirmation
    @State private var isDeletingAccount = false
    @State private var deleteErrorMessage: String? = nil
    
    // History settings
    @State private var historySettings = HistorySettingsManager.shared
    @State private var showTurnOffHistoryAlert = false
    @State private var showClearHistoryAlert = false
    
    /// Check if current user is a guest (generated email with @daa.com or legacy @gen.com)
    private var isGuestUser: Bool {
        // Guest emails use format: YYYYMMDD_HHMM_CityPrefix_LatInt_LngInt@daa.com
        userEmail.isEmpty || userEmail.contains("guest") || userEmail.hasSuffix("@daa.com") || userEmail.hasSuffix("@gen.com")
    }
    
    /// Text for pending upgrade display (e.g., "Upgrading to Plus on Feb 15, 2026")
    private var pendingUpgradeDisplayText: String? {
        guard let pendingPlanId = subscriptionManager.pendingUpgradePlanId,
              let pendingDate = subscriptionManager.pendingUpgradeEffectiveDate else {
            return nil
        }
        let planName = pendingPlanId == "plus" ? "Plus" : "Core"
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Upgrading to \(planName) on \(formatter.string(from: pendingDate))"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark Midnight Background
                // Dark Midnight Background
                CosmicBackgroundView()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Account Section
                        accountSection
                        
                        // MARK: - Subscription Banner
                        subscriptionSection
                        
                        // MARK: - Profile Settings
                        profileSection
                        
                        // MARK: - Astrology Settings
                        astrologySection
                        
                        // MARK: - History Settings
                        historySection
                        
                        // MARK: - Support
                        supportSection
                        
                        // MARK: - App Info
                        appInfoSection
                        
                        // MARK: - Sign Out
                        signOutSection
                        
                        // MARK: - Delete Account (registered users only)
                        if !isGuestUser {
                            deleteAccountSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                     Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.Colors.gold)
                }
            }
            .sheet(isPresented: $showBirthDetails) {
                BirthDetailsView()
            }
            .sheet(isPresented: $showLanguageSettings) {
                LanguageSettingsSheet()
            }
            .sheet(isPresented: $showAstrologySettings) {
                AstrologySettingsSheet()
            }
            .sheet(isPresented: $showChartStylePicker) {
                ChartStylePickerSheet(chartStyle: $chartStyle)
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
            .sheet(isPresented: $showGuestSignInSheet) {
                GuestSignInPromptView(
                    message: "sign_in_to_view_plans".localized,
                    onBack: { showGuestSignInSheet = false }
                )
                .environment(authViewModel)
            }
            .sheet(isPresented: $showProfileSwitcher) {
                ProfileSwitcherSheet()
            }
            .sheet(isPresented: $showUpgradePrompt) {
                SubscriptionView()
            }
            .sheet(isPresented: $showGuestSignInForSwitch) {
                GuestSignInPromptView(
                    message: "sign_in_to_switch_profiles".localized,
                    onBack: { showGuestSignInForSwitch = false }
                )
                .environment(authViewModel)
            }
            .sheet(isPresented: $showNotificationPreferences) {
                NotificationPreferencesSheet(userEmail: userEmail)
            }
            .sheet(isPresented: $showPartnerManager) {
                NavigationStack {
                    PartnerManagerView()
                }
            }
            .sheet(isPresented: $showDeleteAccountSheet) {
                DeleteAccountSheet(
                    isDeleting: $isDeletingAccount,
                    errorMessage: $deleteErrorMessage,
                    hasActiveSubscription: hasActivePaidSubscription,
                    onConfirmDelete: {
                        performAccountDeletion()
                    }
                )
            }
            .preferredColorScheme(.dark)
            .alert("Turn off history?", isPresented: $showTurnOffHistoryAlert) {
                Button("Cancel", role: .cancel) {
                    // Revert toggle back to ON
                    historySettings.isHistoryEnabled = true
                }
                Button("Turn Off", role: .destructive) {
                    historySettings.isHistoryEnabled = false
                    HapticManager.shared.play(.heavy)
                }
            } message: {
                Text("New chats and matches won't be saved. You can turn this back on anytime.")
            }
            .alert("Clear history?", isPresented: $showClearHistoryAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    Task {
                        await historySettings.clearAllHistory(dataManager: DataManager.shared)
                        HapticManager.shared.play(.heavy)
                    }
                }
            } message: {
                Text("This will remove saved chats and match history. This can't be undone.")
            }
        }
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        PremiumCard {
            HStack(spacing: 16) {
                // Avatar with gradient
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.premiumGradient)
                        .frame(width: 70, height: 70)
                        .shadow(color: AppTheme.Colors.gold.opacity(0.3), radius: 8)
                    
                    Text(avatarInitials)
                        .font(AppTheme.Fonts.display(size: 26))
                        .foregroundColor(AppTheme.Colors.mainBackground)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(userName.isEmpty ? "Guest User" : userName)
                        .font(AppTheme.Fonts.title(size: 20))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if !userEmail.isEmpty {
                        Text(userEmail)
                            .font(AppTheme.Fonts.body(size: 14))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    
                    // Display Active Chart
                    HStack(spacing: 4) {
                        Image(systemName: "person.text.rectangle")
                            .font(AppTheme.Fonts.caption(size: 11))
                        Text("Viewing Birth Chart : \(profileContext.activeProfileName)")
                            .font(AppTheme.Fonts.caption(size: 11))
                    }
                    .foregroundColor(AppTheme.Colors.gold)
                    .padding(.top, 4)
                    
                    // Plan badge - Only show for free users (Premium users have the large card below)
                    if !quotaManager.isPremium {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(AppTheme.Fonts.caption(size: 10))
                            Text(quotaManager.planDisplayName)
                                .font(AppTheme.Fonts.title(size: 11))
                        }
                        .foregroundColor(AppTheme.Colors.gold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.gold.opacity(0.2))
                        )
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Profile Settings
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profile")
                .font(AppTheme.Fonts.title(size: 18))
                .foregroundColor(AppTheme.Colors.gold)
                .padding(.leading, 4)
            
            VStack(spacing: 12) {
                PremiumListItem(
                    title: "Birth Details",
                    subtitle: "Date, time, and place of birth",
                    icon: "calendar.circle.fill",
                    action: { showBirthDetails = true }
                )
                
                // Manage Birth Charts (Plus-only)
                PremiumListItem(
                    title: "Manage Birth Charts",
                    subtitle: quotaManager.hasFeature(.maintainProfile) ? "Manage birth charts" : "Plus plan feature",
                    icon: "person.2.fill",
                    isPremiumFeature: true,
                    premiumBadgeText: "Core",
                    action: {
                        if isGuestUser {
                            showGuestSignInForSwitch = true
                        } else if quotaManager.hasFeature(.maintainProfile) {
                            showPartnerManager = true
                        } else {
                            showUpgradePrompt = true
                        }
                    }
                )
                
                // Switch Birth Chart - moved from HomeView header
                PremiumListItem(
                    title: "Switch Birth Chart",
                    subtitle: quotaManager.hasFeature(.switchProfile)
                        ? (ProfileContextManager.shared.isUsingSelf 
                            ? "Viewing as \(ProfileContextManager.shared.activeProfileName)" 
                            : "Using \(ProfileContextManager.shared.activeProfileName)'s chart")
                        : "Plus plan feature",
                    icon: "arrow.triangle.2.circlepath",
                    isPremiumFeature: true,
                    action: {
                        // GUEST RULE: Guests must sign in first
                        if isGuestUser {
                            showGuestSignInForSwitch = true
                        } else if quotaManager.hasFeature(.switchProfile) {
                            showProfileSwitcher = true
                        } else {
                            showUpgradePrompt = true
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Astrology Settings
    private var astrologySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferences")
                .font(AppTheme.Fonts.title(size: 18))
                .foregroundColor(AppTheme.Colors.gold)
                .padding(.leading, 4)
            
            VStack(spacing: 12) {
                PremiumListItem(
                    title: "Language",
                    subtitle: currentLanguageDisplay,
                    icon: "globe",
                    action: { showLanguageSettings = true }
                )
                
                if AppTheme.Features.showAstrologySettings {
                    PremiumListItem(
                        title: "Astrology Settings",
                        subtitle: "Ayanamsa & House System",
                        icon: "star.circle.fill",
                        action: { showAstrologySettings = true }
                    )
                }
                
                PremiumListItem(
                    title: "Chart Style",
                    subtitle: chartStyle == "north" ? "North Indian" : "South Indian",
                    icon: "square.grid.3x3.fill",
                    action: { showChartStylePicker = true }
                )
                
                // Notification Preferences (Plus-only)
                PremiumListItem(
                    title: "Notification Preferences",
                    subtitle: quotaManager.hasFeature(.alerts) ? "Customize your alerts" : "Plus plan feature",
                    icon: "bell.badge.fill",
                    isPremiumFeature: true,
                    action: {
                        if quotaManager.hasFeature(.alerts) {
                            showNotificationPreferences = true
                        } else {
                            showUpgradePrompt = true
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - History Settings
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(AppTheme.Fonts.title(size: 18))
                .foregroundColor(AppTheme.Colors.gold)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                // Save history toggle
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.Colors.gold.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "clock.arrow.circlepath")
                            .font(AppTheme.Fonts.title(size: 16))
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Save conversation history")
                            .font(AppTheme.Fonts.body(size: 16))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text(historySettings.isHistoryEnabled ? "Chats and matches are saved" : "History is turned off")
                            .font(AppTheme.Fonts.caption(size: 12))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { historySettings.isHistoryEnabled },
                        set: { newValue in
                            if !newValue {
                                // Show confirmation before turning off
                                showTurnOffHistoryAlert = true
                            } else {
                                historySettings.isHistoryEnabled = true
                                HapticManager.shared.play(.light)
                            }
                        }
                    ))
                    .labelsHidden()
                    .tint(AppTheme.Colors.gold)
                }
                .padding(16)
                .background(AppTheme.Colors.cardBackground)
                
                Divider()
                    .background(AppTheme.Colors.separator)
                
                // Clear history button
                Button(action: {
                    showClearHistoryAlert = true
                }) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppTheme.Colors.error.opacity(0.15))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "trash")
                                .font(AppTheme.Fonts.title(size: 16))
                                .foregroundColor(AppTheme.Colors.error)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clear history")
                                .font(AppTheme.Fonts.body(size: 16))
                                .foregroundColor(AppTheme.Colors.error)
                            
                            Text("Remove all saved chats and matches")
                                .font(AppTheme.Fonts.caption(size: 12))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(AppTheme.Fonts.caption(size: 14))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    .padding(16)
                    .background(AppTheme.Colors.cardBackground)
                }
                .buttonStyle(.plain)
            }
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.Colors.separator, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Subscription Section
    private var subscriptionSection: some View {
        Group {
            if quotaManager.isPremium {
                // Paid user: Show current plan details
                paidSubscriptionCard
            } else {
                // Free user: Show upgrade CTA
                freeUpgradeCard
            }
        }
    }
    
    /// Card for free users showing upgrade CTA
    private var freeUpgradeCard: some View {
        Button(action: { 
            // Guest users must sign in first to view plans
            if isGuestUser {
                showGuestSignInSheet = true
            } else {
                showSubscription = true
            }
        }) {
            PremiumCard(style: .hero) {
                HStack(spacing: 14) {
                    // Premium icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "crown.fill")
                            .font(AppTheme.Fonts.title(size: 18))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upgrade to Premium")
                            .font(AppTheme.Fonts.title(size: 16))
                            .foregroundColor(.white)
                        
                        Text("Unlock unlimited insights")
                            .font(AppTheme.Fonts.body(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(AppTheme.Fonts.title(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    /// Card for paid users showing current plan and manage option
    private var paidSubscriptionCard: some View {
        VStack(spacing: 12) {
            // Current plan card
            PremiumCard(style: .hero) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 14) {
                        // Premium icon
                        ZStack {
                            // Dark backdrop for contrast against any background
                            Circle()
                                .fill(AppTheme.Colors.mainBackground.opacity(0.3))
                                .frame(width: 44, height: 44)
                            
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "crown.fill")
                                .font(AppTheme.Fonts.title(size: 18))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(quotaManager.planDisplayName)
                                .font(AppTheme.Fonts.title(size: 18))
                                .foregroundColor(.white)
                            
                            // Show pending upgrade info if scheduled
                            if let pendingText = pendingUpgradeDisplayText {
                                Text(pendingText)
                                    .font(AppTheme.Fonts.body(size: 12))
                                    .foregroundColor(Color.orange)
                            } else if let expiryText = quotaManager.subscriptionExpiryDisplayText {
                                Text(expiryText)
                                    .font(AppTheme.Fonts.body(size: 13))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        Spacer()
                        
                        // Active badge
                        Text(quotaManager.subscriptionStatusDisplayText)
                            .font(AppTheme.Fonts.caption(size: 11))
                            .foregroundColor(AppTheme.Colors.mainBackground)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.9))
                            )
                    }
                }
            }
            
            // Manage subscription button - opens App Store subscriptions
            Button(action: {
                // Open Apple's subscription management page
                if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                    openURL(url)
                }
            }) {
                HStack {
                    Image(systemName: "gear")
                        .font(AppTheme.Fonts.body(size: 14))
                    Text("Manage Subscription")
                        .font(AppTheme.Fonts.body(size: 15))
                }
                .foregroundColor(AppTheme.Colors.gold)
            }
            
            // View plans button
            Button(action: { showSubscription = true }) {
                Text("View All Plans")
                    .font(AppTheme.Fonts.body(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    // MARK: - Support Section
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Support")
                .font(AppTheme.Fonts.title(size: 18))
                .foregroundColor(AppTheme.Colors.gold)
                .padding(.leading, 4)
            
            VStack(spacing: 12) {
                NavigationLink {
                    FAQHelpView()
                } label: {
                    PremiumListItem<EmptyView>(
                        title: "FAQ & Help",
                        icon: "questionmark.circle.fill",
                        showChevron: true // NavigationLink handles click, but visual needs chevron
                    )
                }
                .buttonStyle(PlainButtonStyle()) // Important for NavLink wrap
                
                PremiumListItem<EmptyView>(
                    title: "Contact Us",
                    icon: "envelope.fill",
                    action: {
                        if let url = URL(string: "https://www.destinyaiastrology.com/#contact") {
                            openURL(url)
                        }
                    }
                )
                
                PremiumListItem<EmptyView>(
                    title: "Privacy Policy",
                    icon: "hand.raised.fill",
                    action: {
                        if let url = URL(string: "https://www.destinyaiastrology.com/privacy-policy/") {
                            openURL(url)
                        }
                    }
                )
                
                PremiumListItem<EmptyView>(
                    title: "Terms of Service",
                    icon: "doc.text.fill",
                    action: {
                        if let url = URL(string: "https://www.destinyaiastrology.com/terms-of-service/") {
                            openURL(url)
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(spacing: 8) {
            Text("Destiny AI Astrology")
                .font(AppTheme.Fonts.title(size: 14))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Version \(appVersion)")
                .font(AppTheme.Fonts.body(size: 12))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("© 2026 Destiny AI. All rights reserved.")
                .font(AppTheme.Fonts.body(size: 11))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Sign Out Section
    private var signOutSection: some View {
        Button(action: { showSignOutAlert = true }) {
            Text(isGuest ? "sign_out".localized : "sign_out".localized)
                .font(AppTheme.Fonts.title(size: 16))
                .foregroundColor(AppTheme.Colors.error)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.Colors.error.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .alert("sign_out".localized, isPresented: $showSignOutAlert) {
            Button("cancel".localized, role: .cancel) { }
            Button("sign_out".localized, role: .destructive) {
                Task {
                    await authViewModel.signOutAsync()
                    dismiss()
                }
            }
        } message: {
            Text(isGuest ? "sign_out_guest_message".localized : "sign_out_message".localized)
        }
    }
    
    // MARK: - Delete Account Section
    private var deleteAccountSection: some View {
        Button(action: {
            deleteErrorMessage = nil
            showDeleteAccountSheet = true
        }) {
            Text("Delete Account")
                .font(AppTheme.Fonts.title(size: 16))
                .foregroundColor(AppTheme.Colors.error.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.clear)
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.top, -12)
    }
    
    /// Whether the user has an active paid subscription (must cancel before deleting)
    private var hasActivePaidSubscription: Bool {
        quotaManager.isPremium && subscriptionManager.hasActiveSubscription
    }
    
    /// Perform the account deletion API call, then sign out locally
    private func performAccountDeletion() {
        isDeletingAccount = true
        deleteErrorMessage = nil
        
        Task {
            do {
                try await ProfileService.shared.deleteAccount(email: userEmail)
                
                // Success — close sheet, sign out, and dismiss profile
                await MainActor.run {
                    isDeletingAccount = false
                    showDeleteAccountSheet = false
                }
                
                // Small delay for sheet dismissal animation
                try? await Task.sleep(nanoseconds: 400_000_000)
                
                await authViewModel.signOutAsync()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeletingAccount = false
                    deleteErrorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var avatarInitials: String {
        if userName.isEmpty { return "G" }
        let components = userName.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(userName.prefix(2)).uppercased()
    }
    
    private var currentLanguageDisplay: String {
        let languageNames: [String: String] = [
            "en": "English", "hi": "हिंदी", "ta": "தமிழ்", "te": "తెలుగు",
            "kn": "ಕನ್ನಡ", "ml": "മലയാളം", "es": "Español", "pt": "Português",
            "de": "Deutsch", "fr": "Français", "zh-Hans": "中文", "ja": "日本語", "ru": "Русский"
        ]
        return languageNames[appLanguageCode] ?? "English"
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        var text = "\(version) (\(build))"
        
        if AppEnvironment.current != .production {
            text += " [\(AppEnvironment.current.rawValue.uppercased())]"
        }
        // Force test build trigger
        // Build timestamp: 2026-01-06T16:28
        return text
    }
}

// MARK: - FAQ & Help View
struct FAQHelpView: View {
    var body: some View {
        ZStack {
            CosmicBackgroundView()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("Common Questions")
                        .font(AppTheme.Fonts.title(size: 18))
                        .foregroundColor(AppTheme.Colors.gold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        ForEach(faqItems, id: \.question) { item in
                            FAQItem(question: item.question, answer: item.answer)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("FAQ & Help")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // START: Merged FAQ Data
    private var faqItems: [(question: String, answer: String)] {
        [
            // 1. Accuracy (Updated from Web)
            ("How accurate are Destiny's insights?", "By combining the precision of our proprietary AI algorithm with traditional astrological expertise, Destiny's insights have been highly accurate."),
            
            // 2. AI vs Human (from Web)
            ("How is AI astrology different from consulting a human astrologer?", "AI astrology provides objective insights quickly using sophisticated algorithms and extensive databases. In contrast, traditional astrologers offer personalized interpretations based on their experience and manual analysis of astrological charts."),
            
            // 3. App Specific: Updating Details (Preserved)
            ("How do I update my birth details?", "Go to Profile → Birth Details. You can edit your name and gender directly. For date, time, or place changes, please contact support as these affect all your readings."),
            
            // 4. Required Info (from Web)
            ("What information is required to start using Destiny?", "To use Destiny, you'll need to provide your birth date, time, and place. This information allows us to provide highly accurate and personalized astrological advice."),
            
            // 5. App Specific: Systems (Preserved)
            ("What astrological systems are supported?", "We use Vedic (Jyotish) astrology with Lahiri Ayanamsa and Whole Sign house system for accurate calculations."),
            
            // 6. App Specific: Chart Styles (Preserved)
            ("What's the difference between chart styles?", "North Indian style uses a diamond layout where houses are fixed and signs rotate. South Indian style uses a grid layout where signs are fixed and houses rotate."),
            
            // 7. Data Safety (Updated from Web)
            ("Is my data safe with Destiny?", "Absolutely. Destiny employs robust security measures to ensure that your personal information is protected and kept confidential."),
            
            // 8. Question Scope (from Web)
            ("Can I ask any question on Destiny?", "Yes, Destiny is equipped to handle a broad range of questions, whether they are about personal relationships, career choices, or daily life decisions."),
            
            // 9. Value Proposition (from Web)
            ("Why should I consider astrology as a decision-making tool?", "Astrology provides valuable insights into personality traits and life patterns, helping you to better prepare for future opportunities and challenges."),
            
            // 10. Data Freshness (from Web)
            ("How often is the astrological data updated?", "The astrological data used by the AI Astrologer is regularly updated to reflect current cosmic movements and planetary alignments, ensuring that your readings are always up-to-date and relevant."),
             
            // 11. Predictive Nature (from Web)
            ("Can astrology predict my future?", "While astrology does not provide definitive predictions, it offers insights into potential life trends and upcoming opportunities, assisting you in making proactive and informed decisions."),
            
            // 12. Real-time (from Web)
            ("Are the astrological insights provided in real-time?", "Yes, Destiny delivers astrological insights in real-time, enabling you to make informed decisions swiftly based on the latest astrological conditions."),
            
            // 13. App Specific: Subscription (Preserved)
            ("How do I cancel my subscription?", "You can manage your subscription through the App Store. Go to Settings → Apple ID → Subscriptions on your device."),
            
            // 14. Terms (from Web)
            ("Are there any terms and conditions I should be aware of?", "Prior to utilizing Destiny AI Astrology services, please ensure you have reviewed our Privacy Policy and Terms of Service.")
        ]
    }

}

// MARK: - FAQ Item Component
struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 10) {
                Button(action: { 
                    HapticManager.shared.play(.light)
                    withAnimation(.spring(response: 0.3)) { isExpanded.toggle() } 
                }) {
                    HStack {
                        Text(question)
                            .font(AppTheme.Fonts.title(size: 15))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(AppTheme.Fonts.title(size: 12))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                
                if isExpanded {
                    Text(answer)
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
}
