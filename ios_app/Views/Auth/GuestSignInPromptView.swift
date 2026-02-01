import SwiftUI

/// Full-screen prompt view shown to guest users when they try to access restricted features
/// Displays a centered message with Google and Apple sign-in buttons
/// Theme matches AuthView for visual consistency
struct GuestSignInPromptView: View {
    let message: String
    var provider: String? = nil  // "apple" or "google" - when set, only show that provider's button
    var onBack: (() -> Void)? = nil
    
    // Use @State viewModel like AuthView does (own instance, not injected)
    @State private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss  // For sheet presentation
    
    // Also observe @AppStorage to detect auth state changes (persistence layer)
    @AppStorage("isAuthenticated") private var isAuthenticatedStorage = false
    
    @State private var isSigningIn = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Animation states (matching AuthView)
    @State private var logoScale: CGFloat = 0.6
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    @State private var orbitRotation: Double = 0
    
    var body: some View {
        ZStack {
            // Layer 1: Cosmic Background (matching AuthView)
            CosmicBackgroundView()
                .ignoresSafeArea()
            
            // Layer 2: Orbital Rings (Ambient decoration)
            OrbitalRingsView(rotation: orbitRotation)
                .opacity(0.25)
            
            // Layer 3: Content
            VStack(spacing: 0) {
                Spacer()
                
                // Logo section with animated glow (matching AuthView)
                logoSection
                    .scaleEffect(logoScale)
                
                // Message section
                messageSection
                    .opacity(contentOpacity)
                    .offset(y: contentOffset)
                    .padding(.top, 28)
                
                Spacer()
                
                // Auth buttons (matching AuthView styling)
                authButtonsSection
                    .opacity(contentOpacity)
                    .offset(y: contentOffset)
                
                Spacer()
                
                // Back button (optional)
                if onBack != nil {
                    backButton
                        .opacity(contentOpacity)
                }
            }
            .padding(.bottom, 20)
            
            // Loading overlay (matching AuthView)
            if isSigningIn {
                loadingOverlay
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: isAuthenticatedStorage) { _, isAuth in
            // Navigate away when sign-in succeeds (observed via AppStorage persistence)
            if isAuth {
                handleSuccess()
            }
        }
        .onChange(of: viewModel.isAuthenticated) { _, isAuth in
            // Navigate away when sign-in succeeds (observed via local ViewModel)
            if isAuth {
                handleSuccess()
            }
        }
        .alert("error".localized, isPresented: $showError) {
            Button("ok".localized, role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Logo Section (Matching AuthView)
    private var logoSection: some View {
        ZStack {
            // Outer pulsing glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppTheme.Colors.gold.opacity(0.25), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: AppTheme.Auth.glowSize, height: AppTheme.Auth.glowSize)
                .blur(radius: AppTheme.Auth.glowBlur)
            
            // Rotating orbit ring
            Circle()
                .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                .frame(width: AppTheme.Auth.ringSize, height: AppTheme.Auth.ringSize)
                .rotationEffect(.degrees(orbitRotation))
            
            // Small orbiting dot
            Circle()
                .fill(AppTheme.Colors.goldLight)
                .frame(width: AppTheme.Auth.dotSize, height: AppTheme.Auth.dotSize)
                .offset(x: AppTheme.Auth.ringSize / 2)
                .rotationEffect(.degrees(orbitRotation))
            
            // Logo with shadow
            Image("logo_gold")
                .resizable()
                .scaledToFit()
                .frame(width: AppTheme.Auth.logoSize, height: AppTheme.Auth.logoSize)
                .offset(x: AppTheme.Auth.logoOpticalOffset.x, y: AppTheme.Auth.logoOpticalOffset.y)
                .shadow(color: AppTheme.Colors.gold.opacity(0.5), radius: 15, x: 0, y: 0)
        }
        .bioRhythm(bpm: 60, intensity: 1.05, active: !isSigningIn)
        .tilt3D(intensity: 10)
    }
    
    // MARK: - Message Section
    private var messageSection: some View {
        VStack(spacing: AppTheme.Auth.logoToTextSpacing) {
            Text("sign_in_required".localized)
                .font(AppTheme.Fonts.display(size: AppTheme.Auth.titleSize))
                .goldGradient()
            
            Text(message)
                .font(AppTheme.Fonts.body(size: AppTheme.Auth.subtitleSize))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Auth.textPadding)
        }
    }
    
    // MARK: - Auth Buttons (Matching AuthView)
    private var authButtonsSection: some View {
        VStack(spacing: 14) {
            // Show Apple button only if provider is nil or "apple"
            if provider == nil || provider == "apple" {
                AuthButton(
                    icon: "apple.logo",
                    iconImage: nil,
                    title: "Continue with Apple",
                    style: provider == "apple" ? .goldSlab : (provider == nil ? .goldSlab : .glassSlab),
                    iconScale: 1.15
                ) {
                    signInWithApple()
                }
            }
            
            // Show Google button only if provider is nil or "google"
            if provider == nil || provider == "google" {
                AuthButton(
                    icon: nil,
                    iconImage: "google_logo",
                    title: "Continue with Google",
                    style: provider == "google" ? .goldSlab : .glassSlab,
                    iconScale: 1.0
                ) {
                    signInWithGoogle()
                }
            }
            
            // Error message
            if !errorMessage.isEmpty && showError {
                Text(errorMessage)
                    .font(AppTheme.Fonts.caption(size: 13))
                    .foregroundColor(AppTheme.Colors.error)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 32)
        .disabled(isSigningIn)
    }
    
    // MARK: - Back Button
    private var backButton: some View {
        Button(action: { onBack?() }) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                Text("back".localized)
                    .font(AppTheme.Fonts.body(size: 15))
                    .fontWeight(.medium)
            }
            .foregroundColor(AppTheme.Colors.gold)
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Loading Overlay (Matching AuthView)
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
    
    // MARK: - Animations (Matching AuthView)
    private func startAnimations() {
        // Logo spring
        withAnimation(AppTheme.Auth.logoSpring) {
            logoScale = 1.0
        }
        
        // Content fade + slide
        withAnimation(.easeOut(duration: AppTheme.Auth.entranceDuration).delay(AppTheme.Auth.entranceDelay)) {
            contentOpacity = 1.0
            contentOffset = 0
        }
        
        // Continuous orbit rotation
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            orbitRotation = 360
        }
    }
    
    // MARK: - Sign In Methods
    private func signInWithGoogle() {
        isSigningIn = true
        HapticManager.shared.playButtonTap()
        SoundManager.shared.playButtonTap()
        Task {
            defer {
                // Always reset loading state when task completes
                Task { @MainActor in
                    isSigningIn = false
                }
            }
            do {
                try await viewModel.signInWithGoogle()
                // Success - explicitly dismiss
                await MainActor.run { handleSuccess() }
            } catch {
                await MainActor.run {
                    // Only show error for non-cancellation errors
                    if !isCancellationError(error) {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        }
    }
    
    private func signInWithApple() {
        isSigningIn = true
        HapticManager.shared.playButtonTap()
        SoundManager.shared.playButtonTap()
        Task {
            defer {
                // Always reset loading state when task completes
                Task { @MainActor in
                    isSigningIn = false
                }
            }
            do {
                try await viewModel.signInWithApple()
                // Success - explicitly dismiss
                await MainActor.run { handleSuccess() }
            } catch {
                await MainActor.run {
                    // Only show error for non-cancellation errors  
                    if !isCancellationError(error) {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        }
    }
    
    /// Check if error is a user cancellation (should not show error message)
    private func isCancellationError(_ error: Error) -> Bool {
        let nsError = error as NSError
        // ASAuthorizationError.canceled = 1000
        // ASAuthorizationError.unknown = 1001 (also often means cancelled)
        return nsError.domain == "com.apple.AuthenticationServices.AuthorizationError" && 
               (nsError.code == 1000 || nsError.code == 1001)
    }
    
    // MARK: - Success Handler
    private func handleSuccess() {
        HapticManager.shared.playSuccess()
        // If presented as sheet, dismiss it
        dismiss()
        // If embedded (like in MainTabView), call onBack
        onBack?()
    }
}

#Preview {
    GuestSignInPromptView(
        message: "Sign in to check compatibility",
        onBack: { }
    )
}
