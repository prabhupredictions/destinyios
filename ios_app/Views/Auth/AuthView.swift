import SwiftUI

/// Premium authentication screen with multiple sign-in options
struct AuthView: View {
    // MARK: - State
    @State private var viewModel = AuthViewModel()
    @AppStorage("isAuthenticated") private var isAuthenticatedStorage = false
    
    // Animation states
    @State private var logoScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            // Content
            VStack(spacing: 0) {
                Spacer()
                
                // Logo section
                logoSection
                    .scaleEffect(logoScale)
                
                // Welcome text
                welcomeSection
                    .opacity(contentOpacity)
                    .padding(.top, 24)
                
                Spacer()
                
                // Auth buttons
                authButtonsSection
                    .opacity(contentOpacity)
                
                // Guest option
                guestSection
                    .opacity(contentOpacity)
                
                Spacer()
                
                // Terms
                termsSection
                    .opacity(contentOpacity)
            }
            
            // Loading overlay
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .onAppear {
            animateIn()
        }
        .onChange(of: viewModel.isAuthenticated) { _, isAuth in
            if isAuth {
                isAuthenticatedStorage = true
            }
        }
    }
    
    // MARK: - Background
    private var backgroundView: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.95, blue: 0.98),
                    Color(red: 0.94, green: 0.94, blue: 0.97),
                    Color(red: 0.92, green: 0.92, blue: 0.96)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Decorative circles
            GeometryReader { geo in
                Circle()
                    .fill(Color("NavyPrimary").opacity(0.03))
                    .frame(width: 500, height: 500)
                    .offset(x: geo.size.width - 150, y: -200)
                
                Circle()
                    .fill(Color("GoldAccent").opacity(0.05))
                    .frame(width: 400, height: 400)
                    .offset(x: -150, y: geo.size.height - 300)
            }
        }
    }
    
    // MARK: - Logo Section
    private var logoSection: some View {
        ZStack {
            // Glow
            Circle()
                .fill(Color("GoldAccent").opacity(0.15))
                .frame(width: 130, height: 130)
                .blur(radius: 20)
            
            // Logo
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color("GoldAccent"), Color("GoldAccent").opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .shadow(color: Color("GoldAccent").opacity(0.4), radius: 15)
            
            Text("D")
                .font(.system(size: 48, weight: .light, design: .serif))
                .foregroundColor(Color("NavyPrimary"))
        }
    }
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        VStack(spacing: 12) {
            Text("Welcome to Destiny")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color("NavyPrimary"))
            
            Text("Your personal astrology companion")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color("TextDark").opacity(0.6))
        }
    }
    
    // MARK: - Auth Buttons
    private var authButtonsSection: some View {
        VStack(spacing: 14) {
            // Apple Sign In
            AuthButton(
                icon: "apple.logo",
                title: "Continue with Apple",
                style: .dark
            ) {
                Task { await viewModel.signInWithApple() }
            }
            
            // Google Sign In
            AuthButton(
                icon: "g.circle.fill",
                title: "Continue with Google",
                style: .light
            ) {
                Task { await viewModel.signInWithGoogle() }
            }
            
            // Email Sign In (placeholder)
            AuthButton(
                icon: "envelope.fill",
                title: "Continue with Email",
                style: .light
            ) {
                // TODO: Email sign in
            }
            
            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, 28)
        .disabled(viewModel.isLoading)
    }
    
    // MARK: - Guest Section
    private var guestSection: some View {
        VStack(spacing: 12) {
            // Divider
            HStack {
                Rectangle()
                    .fill(Color("TextDark").opacity(0.2))
                    .frame(height: 1)
                Text("or")
                    .font(.system(size: 13))
                    .foregroundColor(Color("TextDark").opacity(0.4))
                Rectangle()
                    .fill(Color("TextDark").opacity(0.2))
                    .frame(height: 1)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            // Guest button
            Button(action: {
                viewModel.continueAsGuest()
            }) {
                Text("Continue as Guest")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("NavyPrimary"))
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Terms Section
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("By continuing, you agree to our")
                .font(.system(size: 12))
                .foregroundColor(Color("TextDark").opacity(0.5))
            
            HStack(spacing: 4) {
                Button("Terms of Service") {
                    // TODO: Open terms
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color("NavyPrimary"))
                
                Text("and")
                    .font(.system(size: 12))
                    .foregroundColor(Color("TextDark").opacity(0.5))
                
                Button("Privacy Policy") {
                    // TODO: Open privacy
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color("NavyPrimary"))
            }
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.3)
                
                Text("Signing in...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("NavyPrimary").opacity(0.95))
            )
        }
    }
    
    // MARK: - Animations
    private func animateIn() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            logoScale = 1.0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            contentOpacity = 1.0
        }
    }
}

// MARK: - Auth Button Component
struct AuthButton: View {
    enum Style {
        case dark, light
    }
    
    let icon: String
    let title: String
    let style: Style
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(style == .dark ? .white : Color("NavyPrimary"))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(style == .dark ? Color("NavyPrimary") : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        style == .light ? Color("NavyPrimary").opacity(0.2) : Color.clear,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: style == .dark ? Color("NavyPrimary").opacity(0.2) : Color.black.opacity(0.05),
                radius: style == .dark ? 8 : 4,
                y: style == .dark ? 4 : 2
            )
        }
    }
}

#Preview {
    AuthView()
}
