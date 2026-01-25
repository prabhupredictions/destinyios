import SwiftUI

/// Premium authentication screen with multiple sign-in options
/// Aligned with Splash/Language/Onboarding visual consistency
struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var quotaManager = QuotaManager.shared
    @State private var viewModel = AuthViewModel()
    
    // User preferences from storage
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("chartStyle") private var chartStyle: String = "north"
    @AppStorage("isGuest") private var isGuest: Bool = false
    @AppStorage("isAuthenticated") private var isAuthenticatedStorage = false
    
    // Navigation states for settings sheets
    @State private var showBirthDetails = false
    @State private var showLanguageSettings = false
    @State private var showAstrologySettings = false
    
    // ... (rest of View)


    // Animation states
    @State private var logoScale: CGFloat = 0.6
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    @State private var orbitRotation: Double = 0
    
    // Sound Manager
    @ObservedObject private var soundManager = SoundManager.shared
    
    var body: some View {
        ZStack {
            // Layer 1: Cosmic Background
            CosmicBackgroundView()
                .ignoresSafeArea()
            
            // Layer 2: Orbital Rings (Ambient decoration)
            OrbitalRingsView(rotation: orbitRotation)
                .opacity(0.25)
            
            // Layer 3: Content
            VStack(spacing: 0) {
                // Sound Toggle (Top Right)
                soundToggle
                
                Spacer()
                
                // Logo section with animated glow
                logoSection
                    .scaleEffect(logoScale)
                
                // Welcome text
                welcomeSection
                    .opacity(contentOpacity)
                    .offset(y: contentOffset)
                    .padding(.top, 28)
                
                Spacer()
                
                // Auth buttons
                authButtonsSection
                    .opacity(contentOpacity)
                    .offset(y: contentOffset)
                
                // Guest option
                guestSection
                    .opacity(contentOpacity)
                
                Spacer()
                
                // Terms
                termsSection
                    .opacity(contentOpacity)
            }
            .padding(.bottom, 20)
            
            // Loading overlay
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: viewModel.isAuthenticated) { _, isAuth in
            if isAuth {
                HapticManager.shared.playSuccess()
                isAuthenticatedStorage = true
            }
        }
    }
    
    // MARK: - Sound Toggle (Consistency with Language Screen)
    @ViewBuilder
    private var soundToggle: some View {
        if AppTheme.Features.showSoundToggle {
            HStack {
                Spacer()
                
                Button(action: {
                    HapticManager.shared.play(.light)
                    SoundManager.shared.toggleSound()
                }) {
                    Image(systemName: soundManager.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .contentTransition(.symbolEffect(.replace))
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }
    
    // MARK: - Logo Section (Refined: Smaller & Elegant)
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
        .bioRhythm(bpm: 60, intensity: 1.05, active: !viewModel.isLoading)
        .tilt3D(intensity: 10)
    }
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        VStack(spacing: AppTheme.Auth.logoToTextSpacing) {
            Text("welcome_to_destiny".localized)
                .font(AppTheme.Fonts.display(size: AppTheme.Auth.titleSize))
                .goldGradient()
            
            Text("sign_in_save".localized)
                .font(AppTheme.Fonts.body(size: AppTheme.Auth.subtitleSize))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Auth.textPadding)
        }
    }
    
    // MARK: - Auth Buttons
    private var authButtonsSection: some View {
        VStack(spacing: 14) {
            // Apple Sign In (Gold Slab)
            AuthButton(
                icon: "apple.logo",
                iconImage: nil,
                title: "Continue with Apple",
                style: .goldSlab,
                iconScale: 1.15  // Apple logo has more whitespace
            ) {
                Task { await viewModel.signInWithApple() }
            }
            
            // Google Sign In (Glass Slab)
            AuthButton(
                icon: nil,
                iconImage: "google_logo",
                title: "Continue with Google",
                style: .glassSlab,
                iconScale: 1.0   // Image asset - no scaling needed
            ) {
                Task { await viewModel.signInWithGoogle() }
            }
            
            /*
            // Email Sign In (Glass Slab)
            AuthButton(
                icon: "envelope.fill",
                iconImage: nil,
                title: "Continue with Email",
                style: .glassSlab,
                iconScale: 0.95  // Envelope fills bounding box well
            ) {
                // TODO: Email sign in
            }
            */
            
            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(AppTheme.Fonts.caption(size: 13))
                    .foregroundColor(AppTheme.Colors.error)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 32)
        .disabled(viewModel.isLoading)
    }

    // MARK: - Guest Section
    private var guestSection: some View {
        VStack(spacing: 12) {
            // Divider with gold fade
            HStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, AppTheme.Colors.gold.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                
                Text("or".localized)
                    .font(AppTheme.Fonts.caption(size: 13))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, AppTheme.Colors.gold.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            }
            .padding(.horizontal, AppTheme.Auth.textPadding)
            .padding(.top, 18)
            
            // Guest button
            Button(action: {
                HapticManager.shared.playButtonTap()
                SoundManager.shared.playButtonTap()
                viewModel.continueAsGuest()
            }) {
                Text("continue_as_guest".localized)
                    .font(AppTheme.Fonts.body(size: AppTheme.Auth.subtitleSize))
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.gold)
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Terms Section
    private var termsSection: some View {
        VStack(spacing: 6) {
            Text("by_continuing".localized)
                .font(AppTheme.Fonts.caption(size: 11))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            HStack(spacing: 4) {
                Button("terms_of_service".localized) {
                     if let url = URL(string: "https://www.destinyaiastrology.com/terms-of-service/") {
                         openURL(url)
                     }
                }
                .font(AppTheme.Fonts.caption(size: 11))
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.goldDim)
                
                Text("and".localized)
                    .font(AppTheme.Fonts.caption(size: 11))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                
                Button("privacy_policy".localized) {
                     if let url = URL(string: "https://www.destinyaiastrology.com/privacy-policy/") {
                         openURL(url)
                     }
                }
                .font(AppTheme.Fonts.caption(size: 11))
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.goldDim)
            }
        }
        .padding(.bottom, 28)
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
}

// MARK: - Premium Auth Button Component
struct AuthButton: View {
    enum Style {
        case goldSlab   // Primary: Heavy Gold
        case glassSlab  // Secondary: Frosted Glass
    }
    
    let icon: String?
    let iconImage: String?
    let title: String
    let style: Style
    let iconScale: CGFloat // Per-icon optical adjustment
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.playButtonTap()
            SoundManager.shared.playButtonTap()
            action()
        }) {
            HStack(spacing: 12) {
                // Icon container with consistent sizing
                Group {
                    if let iconImage = iconImage {
                        Image(iconImage)
                            .resizable()
                            .scaledToFit()
                    } else if let icon = icon {
                        Image(systemName: icon)
                            .resizable()
                            .scaledToFit()
                            .fontWeight(.medium)
                            .scaleEffect(iconScale) // Per-icon optical compensation
                    }
                }
                .frame(width: AppTheme.Auth.iconSize, height: AppTheme.Auth.iconSize)
                
                Text(title)
                    .font(AppTheme.Fonts.title(size: 16))
            }
            .foregroundColor(style == .goldSlab ? AppTheme.Colors.textOnGold : AppTheme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.Auth.buttonHeight)
            .background(
                Group {
                    if style == .goldSlab {
                        ZStack {
                            AppTheme.Colors.premiumCardGradient
                            // ... (Rest of button styling)
                            // Top highlight
                            VStack {
                                Rectangle()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(height: 1)
                                Spacer()
                            }
                            
                            // Subtle inner shadow gradient for realism
                            LinearGradient(
                                colors: [.black.opacity(0.1), .clear],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            .mask(
                                VStack {
                                    Spacer()
                                    Rectangle().frame(height: 4)
                                }
                            )
                        }
                    } else {
                        // Glass Slab
                        RoundedRectangle(cornerRadius: AppTheme.Auth.buttonCornerRadius)
                            .fill(.ultraThinMaterial.opacity(0.1))
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Auth.buttonCornerRadius)
                                    .fill(AppTheme.Colors.cardBackground.opacity(0.6))
                            )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Auth.buttonCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Auth.buttonCornerRadius)
                    .stroke(
                        style == .goldSlab
                            ? Color.white.opacity(0.25)
                            : AppTheme.Colors.gold.opacity(0.3),
                        lineWidth: style == .goldSlab ? 0.5 : 1
                    )
            )
            .shadow(
                color: style == .goldSlab ? AppTheme.Colors.gold.opacity(0.3) : Color.black.opacity(0.2),
                radius: style == .goldSlab ? 10 : 8,
                y: 4
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    AuthView()
}

