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
            AppTheme.Colors.mainBackground.ignoresSafeArea()
            
            // Cosmic background effect
            GeometryReader { geo in
                Circle()
                    .fill(AppTheme.Colors.premiumGradient.opacity(0.1))
                    .frame(width: 500, height: 500)
                    .blur(radius: 100)
                    .offset(x: geo.size.width - 150, y: -200)
                
                Circle()
                    .fill(AppTheme.Colors.purpleAccent.opacity(0.1))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: -150, y: geo.size.height - 300)
            }
            
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
    
    // MARK: - Logo Section
    private var logoSection: some View {
        // Destiny logo from assets
        Image("logo")
            .resizable()
            .scaledToFit()
            .frame(width: 180, height: 180)
            .shadow(color: AppTheme.Colors.gold.opacity(0.3), radius: 20, x: 0, y: 0)
    }
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        VStack(spacing: 12) {
            Text("welcome_to_destiny".localized)
                .font(AppTheme.Fonts.display(size: 32))
                .foregroundColor(AppTheme.Colors.gold)
            
            Text("sign_in_save".localized)
                .font(AppTheme.Fonts.body(size: 16))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Auth Buttons
    private var authButtonsSection: some View {
        VStack(spacing: 16) {
            // Apple Sign In (first per iOS HIG)
            AuthButton(
                icon: "apple.logo",
                iconImage: nil,
                title: "Continue with Apple",
                style: .primary
            ) {
                Task { await viewModel.signInWithApple() }
            }
            
            // Google Sign In
            AuthButton(
                icon: nil,
                iconImage: "google_logo",
                title: "Continue with Google",
                style: .secondary
            ) {
                Task { await viewModel.signInWithGoogle() }
            }
            
            // Email Sign In
            AuthButton(
                icon: "envelope.fill",
                iconImage: nil,
                title: "Continue with Email",
                style: .secondary
            ) {
                // TODO: Email sign in
            }
            
            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(AppTheme.Fonts.caption(size: 13))
                    .foregroundColor(AppTheme.Colors.error)
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
                    .fill(AppTheme.Colors.separator)
                    .frame(height: 1)
                Text("or".localized)
                    .font(AppTheme.Fonts.caption(size: 13))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                Rectangle()
                    .fill(AppTheme.Colors.separator)
                    .frame(height: 1)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            // Guest button
            Button(action: {
                viewModel.continueAsGuest()
            }) {
                Text("continue_as_guest".localized)
                    .font(AppTheme.Fonts.body(size: 16))
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.gold)
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Terms Section
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("by_continuing".localized)
                .font(AppTheme.Fonts.caption(size: 12))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            HStack(spacing: 4) {
                Button("Terms of Service") {
                    // TODO: Open terms
                }
                .font(AppTheme.Fonts.caption(size: 12))
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.goldDim)
                
                Text("and".localized)
                    .font(AppTheme.Fonts.caption(size: 12))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                
                Button("Privacy Policy") {
                    // TODO: Open privacy
                }
                .font(AppTheme.Fonts.caption(size: 12))
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.goldDim)
            }
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.gold))
                    .scaleEffect(1.3)
                
                Text("signing_in".localized)
                    .font(AppTheme.Fonts.body(size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
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
        case primary, secondary
    }
    
    let icon: String?          // SF Symbol name (optional)
    let iconImage: String?     // Asset image name (optional)
    let title: String
    let style: Style
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.play(.light)
            action()
        }) {
            HStack(spacing: 12) {
                // Show either SF Symbol or asset image
                if let iconImage = iconImage {
                    Image(iconImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(AppTheme.Fonts.title(size: 18))
                }
                
                Text(title)
                    .font(AppTheme.Fonts.body(size: 16).weight(.semibold))
            }
            .foregroundColor(style == .primary ? AppTheme.Colors.mainBackground : AppTheme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                Group {
                    if style == .primary {
                        AppTheme.Colors.premiumGradient
                    } else {
                        AppTheme.Colors.inputBackground
                    }
                }
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        style == .secondary ? AppTheme.Colors.gold.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: style == .primary ? AppTheme.Colors.gold.opacity(0.3) : Color.black.opacity(0.1),
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    AuthView()
}
