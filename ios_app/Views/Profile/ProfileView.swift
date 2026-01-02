import SwiftUI

/// Professional Profile screen with account info, settings navigation, and subscription status
/// Follows standard iOS design patterns with Midnight Gold theme
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // User preferences from storage
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("chartStyle") private var chartStyle: String = "north"
    
    // Navigation states for settings sheets
    @State private var showBirthDetails = false
    @State private var showLanguageSettings = false
    @State private var showAstrologySettings = false
    @State private var showChartStylePicker = false
    @State private var showSubscription = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark Midnight Background
                AppTheme.Colors.mainBackground
                    .ignoresSafeArea()
                
                List {
                    // MARK: - Account Section
                    accountSection
                        .listRowBackground(AppTheme.Colors.cardBackground)
                    
                    // MARK: - Profile Settings Section
                    profileSection
                        .listRowBackground(AppTheme.Colors.cardBackground)
                    
                    // MARK: - Astrology Settings Section
                    astrologySection
                        .listRowBackground(AppTheme.Colors.cardBackground)
                    
                    // MARK: - Subscription Section
                    subscriptionSection
                        .listRowBackground(AppTheme.Colors.cardBackground)
                    
                    // MARK: - Support Section
                    supportSection
                        .listRowBackground(AppTheme.Colors.cardBackground)
                    
                    // MARK: - App Info Section
                    appInfoSection
                        .listRowBackground(AppTheme.Colors.cardBackground)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.Colors.mainBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.Colors.gold)
                        .fontWeight(.semibold)
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
        }
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        Section {
            HStack(spacing: 16) {
                // Avatar with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color("GoldAccent").opacity(0.3),
                                    Color("GoldAccent").opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    Text(avatarInitials)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundColor(Color("GoldAccent"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(userName.isEmpty ? "Guest User" : userName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if !userEmail.isEmpty {
                        Text(userEmail)
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    // Premium badge if subscribed
                    if subscriptionManager.isPremium {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                            Text("Premium")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(AppTheme.Colors.gold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.gold.opacity(0.15))
                        )
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Profile Settings Section
    private var profileSection: some View {
        Section {
            // Birth Details
            SettingsRow(
                icon: "calendar.circle.fill",
                iconColor: .orange,
                title: "Birth Details",
                subtitle: "Date, time, and place of birth"
            ) {
                showBirthDetails = true
            }
        } header: {
            Text("Profile")
        }
    }
    
    // MARK: - Astrology Settings Section
    private var astrologySection: some View {
        Section {
            // Language
            SettingsRow(
                icon: "globe",
                iconColor: .blue,
                title: "Language",
                subtitle: currentLanguageDisplay
            ) {
                showLanguageSettings = true
            }
            
            // Astrology Settings (Ayanamsa, House System)
            SettingsRow(
                icon: "star.circle.fill",
                iconColor: .purple,
                title: "Astrology Settings",
                subtitle: "Ayanamsa & House System"
            ) {
                showAstrologySettings = true
            }
            
            // Chart Style
            SettingsRow(
                icon: "square.grid.3x3.fill",
                iconColor: .indigo,
                title: "Chart Style",
                subtitle: chartStyle == "north" ? "North Indian" : "South Indian"
            ) {
                showChartStylePicker = true
            }
        } header: {
            Text("Preferences")
        }
    }
    
    // MARK: - Subscription Section
    private var subscriptionSection: some View {
        Section {
            Button(action: { showSubscription = true }) {
                HStack(spacing: 14) {
                    // Premium icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color("GoldAccent"), Color("GoldAccent").opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(subscriptionManager.isPremium ? "Manage Subscription" : "Upgrade to Premium")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text(subscriptionManager.isPremium ? "View your subscription details" : "Unlock unlimited questions")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
                }
            }
            .buttonStyle(.plain)
        } header: {
            Text("Subscription")
        }
    }
    
    // MARK: - Support Section
    private var supportSection: some View {
        Section {
            // FAQ & Help
            NavigationLink {
                FAQHelpView()
            } label: {
                SettingsRowLabel(
                    icon: "questionmark.circle.fill",
                    iconColor: .green,
                    title: "FAQ & Help"
                )
            }
            
            // Contact Support
            Link(destination: URL(string: "mailto:support@destinyai.app")!) {
                SettingsRowLabel(
                    icon: "envelope.fill",
                    iconColor: .cyan,
                    title: "Contact Support"
                )
            }
            
            // Privacy Policy
            Link(destination: URL(string: "https://destinyai.app/privacy")!) {
                SettingsRowLabel(
                    icon: "hand.raised.fill",
                    iconColor: .gray,
                    title: "Privacy Policy"
                )
            }
            
            // Terms of Service
            Link(destination: URL(string: "https://destinyai.app/terms")!) {
                SettingsRowLabel(
                    icon: "doc.text.fill",
                    iconColor: .gray,
                    title: "Terms of Service"
                )
            }
        } header: {
            Text("Support")
        }
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        Section {
            HStack {
                Text("Version")
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
                Text(appVersion)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        } footer: {
            VStack(spacing: 8) {
                Text("Destiny AI Astrology")
                    .font(.system(size: 13, weight: .medium))
                Text("© 2026 Destiny AI. All rights reserved.")
                    .font(.system(size: 11))
            }
            .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
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
        return "\(version) (\(build))"
    }
}

// MARK: - Settings Row Component
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let action: () -> Void
    
    init(icon: String, iconColor: Color, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Row Label (for NavigationLink/Link)
struct SettingsRowLabel: View {
    let icon: String
    let iconColor: Color
    let title: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
}

// MARK: - FAQ & Help View
struct FAQHelpView: View {
    var body: some View {
        List {
            Section("Common Questions") {
                FAQItem(
                    question: "How accurate are the predictions?",
                    answer: "Destiny AI uses authentic Vedic astrology calculations based on your exact birth time and location, combined with AI for personalized insights. The accuracy depends heavily on the precision of your birth data."
                )
                
                FAQItem(
                    question: "How do I update my birth details?",
                    answer: "Go to Profile → Birth Details. You can edit your name and gender directly. For date, time, or place changes, please contact support as these affect all your readings."
                )
                
                FAQItem(
                    question: "What astrological systems are supported?",
                    answer: "We currently support Vedic (Jyotish) astrology with multiple Ayanamsa options including Lahiri, Raman, and Krishnamurti. You can change these in Astrology Settings."
                )
                
                FAQItem(
                    question: "What's the difference between chart styles?",
                    answer: "North Indian style uses a diamond layout where houses are fixed and signs rotate. South Indian style uses a grid layout where signs are fixed and houses rotate."
                )
                
                FAQItem(
                    question: "Is my data secure?",
                    answer: "Yes, all your personal data including birth information is stored securely and encrypted. We never share your data with third parties."
                )
                
                FAQItem(
                    question: "How do I cancel my subscription?",
                    answer: "You can manage your subscription through the App Store. Go to Settings → Apple ID → Subscriptions on your device."
                )
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("FAQ & Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - FAQ Item Component
struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: { withAnimation(.spring(response: 0.3)) { isExpanded.toggle() } }) {
                HStack {
                    Text(question)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color("NavyPrimary"))
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color("TextDark").opacity(0.4))
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                Text(answer)
                    .font(.system(size: 14))
                    .foregroundColor(Color("TextDark").opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
}
