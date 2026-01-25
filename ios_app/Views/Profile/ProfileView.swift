import SwiftUI

/// Professional Profile screen with account info, settings navigation, and subscription status
/// Follows standard iOS design patterns with Midnight Gold theme
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var quotaManager = QuotaManager.shared
    @State private var authViewModel = AuthViewModel()
    
    // User preferences from storage
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("chartStyle") private var chartStyle: String = "north"
    @AppStorage("isGuest") private var isGuest: Bool = false
    
    // Navigation states for settings sheets
    @State private var showBirthDetails = false
    @State private var showLanguageSettings = false
    @State private var showAstrologySettings = false
    @State private var showChartStylePicker = false
    @State private var showSubscription = false
    @State private var showSignOutAlert = false
    @State private var showGuestSignInSheet = false  // Guest sign-in prompt for subscription
    
    /// Check if current user is a guest (generated email with @daa.com or legacy @gen.com)
    private var isGuestUser: Bool {
        // Guest emails use format: YYYYMMDD_HHMM_CityPrefix_LatInt_LngInt@daa.com
        userEmail.isEmpty || userEmail.contains("guest") || userEmail.hasSuffix("@daa.com") || userEmail.hasSuffix("@gen.com")
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
                        
                        // MARK: - Support
                        supportSection
                        
                        // MARK: - App Info
                        appInfoSection
                        
                        // MARK: - Sign Out
                        signOutSection
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
            .preferredColorScheme(.dark)
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
                    }
                    
                    // Premium badge if subscribed
                    if quotaManager.isPremium {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(AppTheme.Fonts.caption(size: 10))
                            Text("Premium")
                                .font(AppTheme.Fonts.title(size: 11))
                        }
                        .foregroundColor(AppTheme.Colors.mainBackground)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.gold)
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
                
                NavigationLink {
                    PartnerManagerView()
                } label: {
                    PremiumListItem<EmptyView>(
                        title: "Manage Birth Charts",
                        subtitle: "Manage birth charts",
                        icon: "person.2.fill",
                        showChevron: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
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
            }
        }
    }
    
    // MARK: - Subscription Section
    private var subscriptionSection: some View {
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
                        Text(quotaManager.isPremium ? "Manage Subscription" : "Upgrade to Premium")
                            .font(AppTheme.Fonts.title(size: 16))
                            .foregroundColor(.white)
                        
                        Text(quotaManager.isPremium ? "View details" : "Unlock unlimited insights")
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
        let code = UserDefaults.standard.string(forKey: "appLanguageCode") ?? "en"
        let languageNames: [String: String] = [
            "en": "English", "hi": "हिंदी", "ta": "தமிழ்", "te": "తెలుగు",
            "kn": "ಕನ್ನಡ", "ml": "മലയാളം", "es": "Español", "pt": "Português",
            "de": "Deutsch", "fr": "Français", "zh-Hans": "中文", "ja": "日本語", "ru": "Русский"
        ]
        return languageNames[code] ?? "English"
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
