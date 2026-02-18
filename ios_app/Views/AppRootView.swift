import SwiftUI
import SwiftData

/// Main app container that handles routing between authentication flows
struct AppRootView: View {
    // MARK: - Persisted State
    @AppStorage("hasCompletedLanguageSelection") private var hasCompletedLanguageSelection = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @AppStorage("hasBirthData") private var hasBirthData = false
    
    // MARK: - Model Container
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Local State
    @State private var showSplash = true
    @State private var languageRefreshID = UUID()
    
    // Computed property to check if guest needs birth data
    private var guestNeedsBirthData: Bool {
        let isGuest = UserDefaults.standard.bool(forKey: "isGuest")
        let hasBirthData = UserDefaults.standard.bool(forKey: "hasBirthData")
        // Guest users: always show birth data view on fresh session
        // (hasBirthData gets cleared on app start for guests)
        return isGuest && !hasBirthData
    }
    
    var body: some View {
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
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageChanged)) { _ in
            // Force UI refresh when language changes
            withAnimation(.easeOut(duration: 0.3)) {
                languageRefreshID = UUID()
            }
        }
        .id(languageRefreshID)
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
