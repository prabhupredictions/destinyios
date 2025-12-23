import SwiftUI

/// Placeholder home screen (to be fully implemented in Phase 3)
struct HomeView: View {
    // MARK: - State
    @AppStorage("userEmail") private var userEmail = ""
    @AppStorage("userName") private var userName = ""
    @AppStorage("isGuest") private var isGuest = false
    @State private var viewModel = AuthViewModel()
    
    // Animation
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.95, blue: 0.98),
                        Color(red: 0.92, green: 0.92, blue: 0.96)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Success animation
                    ZStack {
                        Circle()
                            .fill(Color("GoldAccent").opacity(0.1))
                            .frame(width: 140, height: 140)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color("GoldAccent"), Color("GoldAccent").opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: Color("GoldAccent").opacity(0.3), radius: 15)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundColor(Color("NavyPrimary"))
                    }
                    
                    // Welcome text
                    VStack(spacing: 8) {
                        Text("Welcome to Destiny!")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color("NavyPrimary"))
                        
                        if isGuest {
                            Text("You're signed in as a Guest")
                                .font(.system(size: 16))
                                .foregroundColor(Color("TextDark").opacity(0.6))
                        } else if !userName.isEmpty {
                            Text("Hello, \(userName)")
                                .font(.system(size: 16))
                                .foregroundColor(Color("TextDark").opacity(0.6))
                        } else if !userEmail.isEmpty {
                            Text("Signed in as \(userEmail)")
                                .font(.system(size: 14))
                                .foregroundColor(Color("TextDark").opacity(0.5))
                        }
                    }
                    
                    // Coming soon card
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 24))
                            .foregroundColor(Color("GoldAccent"))
                        
                        Text("Full experience coming in Phase 3")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color("TextDark").opacity(0.6))
                        
                        Text("Home screen, Chat, and Match features\nwill be available soon!")
                            .font(.system(size: 13))
                            .foregroundColor(Color("TextDark").opacity(0.4))
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 10)
                    )
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Sign out button
                    Button(action: {
                        viewModel.signOut()
                        // Reset app state
                        UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
                        UserDefaults.standard.set(false, forKey: "isAuthenticated")
                        UserDefaults.standard.set(false, forKey: "hasBirthData")
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left.circle")
                                .font(.system(size: 16))
                            Text("Sign Out & Reset")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color("NavyPrimary").opacity(0.7))
                    }
                    .padding(.bottom, 40)
                }
                .opacity(contentOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                contentOpacity = 1.0
            }
        }
    }
}

#Preview {
    HomeView()
}
