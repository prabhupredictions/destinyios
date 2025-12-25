import SwiftUI

/// Home screen showing greeting, quota, daily insight, and suggested questions
struct HomeView: View {
    // MARK: - State
    @State private var viewModel = HomeViewModel()
    @State private var showMenu = false
    @State private var showProfile = false
    @State private var showSubscription = false
    @State private var selectedQuestion: String? = nil
    @State private var navigateToChat = false
    
    // For sign out / sign in
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @AppStorage("hasBirthData") private var hasBirthData = false
    @AppStorage("isGuest") private var isGuestStorage = false
    
    // Animation
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Animated orbital background with rotating planets
            MinimalOrbitalBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    AppHeader(
                        onMenuTap: { showMenu = true },
                        onProfileTap: { showProfile = true }
                    )
                    
                    // Greeting section
                    greetingSection
                        .padding(.horizontal, 20)
                    
                    // NOTE: QuotaWidget removed - following modern UX best practice
                    // Users don't see quota limits (like OpenAI/Gemini)
                    // Paywall appears only when quota is exhausted
                    
                    // Daily Insight Card
                    InsightCard(
                        insight: viewModel.dailyInsight,
                        isLoading: viewModel.isLoading
                    )
                    .padding(.horizontal, 20)
                    
                    // Suggested Questions
                    if !viewModel.suggestedQuestions.isEmpty {
                        SuggestedQuestions(
                            questions: viewModel.suggestedQuestions
                        ) { question in
                            selectedQuestion = question
                            // TODO: Navigate to chat with this question
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Spacer for tab bar
                    Spacer(minLength: 120)
                }
                .padding(.top, 8)
            }
            .opacity(contentOpacity)
            .refreshable {
                await viewModel.loadHomeData()
            }
        }
        .task {
            await viewModel.loadHomeData()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                contentOpacity = 1.0
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileSheet()
        }
        .sheet(isPresented: $showMenu) {
            HistoryView()
        }
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
        }
    }
    
    // MARK: - Sign Out and Re-auth (for guest → sign in flow)
    private func signOutAndReauth() {
        // Clear guest session to show auth screen
        isGuestStorage = false
        isAuthenticated = false
        hasBirthData = false
        
        // Clear stored data
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "quotaUsed")
    }
    
    // MARK: - Greeting Section
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(viewModel.greetingMessage), \(viewModel.displayName)!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color("NavyPrimary"))
            
            Text("Let's explore what the stars have for you.")
                .font(.system(size: 16))
                .foregroundColor(Color("TextDark").opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Profile Sheet
struct ProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userName") private var userName = ""
    @AppStorage("userEmail") private var userEmail = ""
    @AppStorage("isGuest") private var isGuest = false
    @AppStorage("isPremium") private var isPremium = false
    @AppStorage("astrologySystem") private var astrologySystem = "Vedic"
    @AppStorage("appLanguage") private var appLanguage = "English"
    @State private var authViewModel = AuthViewModel()
    @State private var showSubscription = false
    @State private var showBirthDataEdit = false
    @State private var birthDataDisplay: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    profileHeader
                    
                    // Upgrade banner (for non-premium)
                    if !isPremium {
                        upgradeBanner
                    }
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Birth Details Section
                    birthDetailsSection
                    
                    // Preferences Section
                    preferencesSection
                    
                    // Support Section
                    supportSection
                    
                    // Sign out button
                    signOutButton
                }
                .padding(.bottom, 40)
            }
            .background(Color(red: 0.96, green: 0.95, blue: 0.98))
            .navigationTitle("Profile")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color("NavyPrimary"))
                }
                #else
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color("NavyPrimary"))
                }
                #endif
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
            .onAppear {
                loadBirthDataDisplay()
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color("GoldAccent").opacity(0.2))
                    .frame(width: 80, height: 80)
                
                if isPremium {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color("GoldAccent"))
                } else {
                    Image(systemName: isGuest ? "person.fill.questionmark" : "person.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color("NavyPrimary"))
                }
            }
            
            VStack(spacing: 4) {
                Text(isGuest ? "Guest User" : (userName.isEmpty ? "User" : userName))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color("NavyPrimary"))
                
                if !isGuest && !userEmail.isEmpty {
                    Text(userEmail)
                        .font(.system(size: 14))
                        .foregroundColor(Color("TextDark").opacity(0.6))
                }
                
                if isPremium {
                    Text("Premium Member")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("GoldAccent"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color("GoldAccent").opacity(0.15))
                        )
                }
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Upgrade Banner
    private var upgradeBanner: some View {
        Button(action: { showSubscription = true }) {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color("GoldAccent"))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upgrade to Premium")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color("NavyPrimary"))
                    
                    Text("Get unlimited questions & matches")
                        .font(.system(size: 12))
                        .foregroundColor(Color("TextDark").opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("NavyPrimary").opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("GoldAccent").opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Birth Details Section
    private var birthDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Birth Details")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color("TextDark").opacity(0.5))
                .padding(.horizontal, 20)
            
            ProfileMenuItem(
                icon: "calendar.badge.clock",
                title: "View Birth Details",
                subtitle: birthDataDisplay.isEmpty ? "Not set" : birthDataDisplay,
                action: { showBirthDataEdit = true }
            )
        }
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferences")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color("TextDark").opacity(0.5))
                .padding(.horizontal, 20)
            
            ProfileMenuItem(
                icon: "globe",
                title: "Astrology System",
                subtitle: astrologySystem,
                action: { /* TODO: Show picker */ }
            )
            
            ProfileMenuItem(
                icon: "textformat",
                title: "Language",
                subtitle: appLanguage,
                action: { /* TODO: Show picker */ }
            )
        }
    }
    
    // MARK: - Support Section
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Support")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color("TextDark").opacity(0.5))
                .padding(.horizontal, 20)
            
            ProfileMenuItem(
                icon: "questionmark.circle",
                title: "Help & FAQ",
                action: { /* TODO: Open help */ }
            )
        }
    }
    
    // MARK: - Sign Out Button
    private var signOutButton: some View {
        Button(action: {
            authViewModel.signOut()
            UserDefaults.standard.set(false, forKey: "isAuthenticated")
            UserDefaults.standard.set(false, forKey: "hasBirthData")
            dismiss()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.red.opacity(0.8))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Load Birth Data Display
    private func loadBirthDataDisplay() {
        if let data = UserDefaults.standard.data(forKey: "birthData"),
           let decoded = try? JSONDecoder().decode(BirthData.self, from: data) {
            birthDataDisplay = "\(decoded.dob), \(decoded.time)"
            if let city = decoded.cityOfBirth {
                birthDataDisplay += " • \(city)"
            }
        }
    }
}

// MARK: - Profile Menu Item
struct ProfileMenuItem: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color("NavyPrimary"))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundColor(Color("NavyPrimary"))
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(Color("TextDark").opacity(0.5))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("TextDark").opacity(0.3))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    HomeView()
}
