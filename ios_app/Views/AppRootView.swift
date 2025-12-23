import SwiftUI

/// Main app container that handles routing between authentication flows
struct AppRootView: View {
    // MARK: - Persisted State
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @AppStorage("hasBirthData") private var hasBirthData = false
    
    // MARK: - Local State
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            // Main content
            Group {
                if !hasSeenOnboarding {
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
                } else if !hasBirthData {
                    BirthDataView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                } else {
                    HomeView()
                        .transition(.opacity)
                }
            }
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
    }
}

#Preview {
    AppRootView()
}
