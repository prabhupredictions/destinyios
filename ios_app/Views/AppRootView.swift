import SwiftUI
import SwiftData

/// Main app container that handles routing between authentication flows
struct AppRootView: View {
    // MARK: - Persisted State
    @AppStorage("hasCompletedLanguageSelection") private var hasCompletedLanguageSelection = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @AppStorage("hasBirthData") private var hasBirthData = false
    @AppStorage("lastAccessState") private var lastAccessState = "unknown"
    @AppStorage("userEmail") private var userEmail = ""

    // MARK: - Model Container
    @Environment(\.modelContext) private var modelContext

    // MARK: - Local State
    @State private var showSplash = true
    @State private var languageRefreshID = UUID()
    @State private var appStartup = AppStartupService.shared
    /// Observed singleton so AppRootView can react to subscriptionConflict
    /// changes (cross-account Apple ID detection during sign-in).
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    // Computed property to check if guest needs birth data
    private var guestNeedsBirthData: Bool {
        let isGuest = UserDefaults.standard.bool(forKey: "isGuest")
        let hasBirthData = UserDefaults.standard.bool(forKey: "hasBirthData")
        // Guest users: always show birth data view on fresh session
        // (hasBirthData gets cleared on app start for guests)
        return isGuest && !hasBirthData
    }
    
    // MARK: - E2E Test Session Injection
    #if DEBUG
    private func injectE2ESession() {
        guard ProcessInfo.processInfo.arguments.contains("UI_TEST_MODE") else { return }
        let env = ProcessInfo.processInfo.environment
        UserDefaults.standard.set(true,  forKey: "hasCompletedLanguageSelection")
        UserDefaults.standard.set(true,  forKey: "hasSeenOnboarding")
        UserDefaults.standard.set(true,  forKey: "isAuthenticated")
        UserDefaults.standard.set(true,  forKey: "hasBirthData")
        UserDefaults.standard.set(false, forKey: "isGuest")
        UserDefaults.standard.set("granted", forKey: "lastAccessState")
        UserDefaults.standard.set(
            env["E2E_USER_EMAIL"] ?? "prabhukushwaha@gmail.com",
            forKey: "userEmail"
        )
        UserDefaults.standard.set(env["E2E_DOB"]       ?? "1980-07-01", forKey: "dateOfBirth")
        UserDefaults.standard.set(env["E2E_TIME"]      ?? "06:32",      forKey: "timeOfBirth")
        UserDefaults.standard.set(env["E2E_CITY"]      ?? "Bhilai",     forKey: "cityOfBirth")
        UserDefaults.standard.set(env["E2E_LATITUDE"]  ?? "21.2138",    forKey: "latitude")
        UserDefaults.standard.set(env["E2E_LONGITUDE"] ?? "81.3943",    forKey: "longitude")
    }
    #endif

    var body: some View {
        #if DEBUG
        let _ = { injectE2ESession() }()
        #endif
        ZStack {
            // Main content
            Group {
                if !hasCompletedLanguageSelection {
                    LanguageSelectionView(isCompleted: $hasCompletedLanguageSelection)
                        .transition(.opacity)
                } else if !hasSeenOnboarding {
                    OnboardingView(onComplete: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            hasSeenOnboarding = true
                        }
                    })
                    .transition(.opacity)
                } else if !isAuthenticated {
                    AuthView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                } else if lastAccessState == "waitlist_pending" {
                    WaitlistPendingView(userEmail: userEmail)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                        .task {
                            await recheckWaitlistStatus()
                        }
                } else if !hasBirthData || guestNeedsBirthData {
                    // Both new users AND guest users (each session) must enter birth data
                    BirthDataView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                } else {
                    MainTabView()
                        .transition(.opacity)
                        .onAppear {
                            // Load active profile context on main app view
                            loadProfileContext()
                        }
                }
            }
            .animation(.easeInOut(duration: 0.4), value: hasCompletedLanguageSelection)
            .animation(.easeInOut(duration: 0.4), value: hasSeenOnboarding)
            .animation(.easeInOut(duration: 0.4), value: isAuthenticated)
            .animation(.easeInOut(duration: 0.4), value: hasBirthData)
            .animation(.easeInOut(duration: 0.4), value: lastAccessState)
            
            // Splash overlay
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // Dismiss splash after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showSplash = false
                }
            }
        }
        .task {
            await appStartup.fetchConfig()
            await recheckWaitlistStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageChanged)) { _ in
            // Force UI refresh when language changes
            withAnimation(.easeOut(duration: 0.3)) {
                languageRefreshID = UUID()
            }
        }
        .id(languageRefreshID)
        // Cross-account subscription conflict alert — duplicate of the
        // alert wired in MainTabView, attached here at root level too
        // because the conflict can be detected during the AuthView →
        // MainTabView transition (sign-in fires reconcile immediately;
        // backend returns the conflict before MainTabView has mounted
        // and observed `subscriptionConflict`). SwiftUI doesn't queue
        // alerts across view-hierarchy changes, so without a root-level
        // binding the alert silently drops. .alert(item:) auto-clears
        // the binding on dismiss, so only ONE of (root, MainTabView)
        // will fire — whichever observes the change first.
        .alert(item: $subscriptionManager.subscriptionConflict) { _ in
            Alert(
                title: Text("Apple ID Already Linked"),
                message: Text(
                    "Your Apple ID has an active subscription that is already linked " +
                    "to a different Destiny account.\n\n" +
                    "This was detected automatically while checking your subscription " +
                    "status.\n\n" +
                    "To use this subscription, sign in with the original email. " +
                    "If you need help recovering access, contact support@destinyaiastrology.com."
                ),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Waitlist Recheck

    private func recheckWaitlistStatus() async {
        guard isAuthenticated else { return }
        let storedEmail = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        let appleId = UserDefaults.standard.string(forKey: "appleUserID")
        let googleId = UserDefaults.standard.string(forKey: "googleUserID")
        guard !storedEmail.isEmpty else { return }

        do {
            let response = try await ProfileService.shared.registerUser(
                email: storedEmail,
                isGeneratedEmail: false,
                appleId: appleId,
                googleId: googleId
            )
            if let state = response?.accessState {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        lastAccessState = state
                    }
                }
            }
        } catch {
            // silently ignore — keep existing access state on network failure
        }
    }

    // MARK: - Profile Context

    /// Load active profile from persistence
    private func loadProfileContext() {
        ProfileContextManager.shared.loadActiveProfile(context: modelContext)
    }
}

#Preview {
    AppRootView()
}
