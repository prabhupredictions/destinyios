import SwiftUI

/// App header component with logo, menu, and profile buttons
struct AppHeader: View {
    var title: String? = nil
    var showMenuButton: Bool = true
    var showProfileButton: Bool = true
    var onMenuTap: (() -> Void)? = nil
    var onProfileTap: (() -> Void)? = nil
    
    // User info for profile button
    @AppStorage("userName") private var userName = ""
    @AppStorage("isGuest") private var isGuest = false
    
    // First letter of user name
    private var userInitial: String? {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }
        return String(trimmedName.prefix(1)).uppercased()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Menu button
            if showMenuButton {
                Button(action: { onMenuTap?() }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppTheme.Colors.gold)
                        .frame(width: 44, height: 44)
                }
            } else {
                Spacer()
                    .frame(width: 44)
            }
            
            Spacer()
            
            // Logo or title
            if let title = title {
                Text(title)
                    .font(AppTheme.Fonts.title(size: 18))
                    .foregroundColor(AppTheme.Colors.textPrimary)
            } else {
                LogoView()
            }
            
            Spacer()
            
            // Profile button
            if showProfileButton {
                Button(action: { onProfileTap?() }) {
                    if let initial = userInitial {
                        // Show user's first letter in a circle
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.premiumGradient)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.Colors.gold, lineWidth: 1)
                                )
                            
                            Text(initial)
                                .font(AppTheme.Fonts.body(size: 14).weight(.bold))
                                .foregroundColor(AppTheme.Colors.mainBackground)
                        }
                        .frame(width: 44, height: 44)
                    } else {
                        // Guest user - show person icon
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(AppTheme.Colors.gold.opacity(0.7))
                            .frame(width: 44, height: 44)
                    }
                }
            } else {
                Spacer()
                    .frame(width: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppTheme.Colors.mainBackground)
    }
}

// MARK: - Logo View
struct LogoView: View {
    var body: some View {
        // Destiny wordmark logo - ensuring it looks good on dark bg
        // If image is black text, we might need a different asset or filter.
        // Assuming current asset works or we might need to tint it if it's template.
        Image("destiny_home")
            .resizable()
            .scaledToFit()
            .frame(height: 32) // Standard height across all screens
            // If the logo is black text, we invert it for dark mode or specific tint
            // .colorInvert() // Only if the asset is black-on-transparent
    }
}

// MARK: - Chat Header (with history and new chat buttons)
struct ChatHeader: View {
    var onBackTap: (() -> Void)? = nil  // NEW: Back navigation
    var onHistoryTap: (() -> Void)? = nil
    var onNewChatTap: (() -> Void)? = nil
    var onChartTap: (() -> Void)? = nil
    var onProfileTap: (() -> Void)? = nil
    
    // Profile Context
    private let profileContext = ProfileContextManager.shared
    
    var body: some View {
        VStack(spacing: 4) {
            // Profile Context Indicator (non-tappable, shows who we're viewing)
            // Note: Switching is only allowed from Home screen
            if !profileContext.isUsingSelf {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.caption)
                    
                    Text("Viewing as \(profileContext.activeProfileName)")
                        .font(AppTheme.Fonts.caption())
                }
                .foregroundColor(AppTheme.Colors.gold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(AppTheme.Colors.gold.opacity(0.15))
                        .overlay(Capsule().stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1))
                )
            }
            
            // Main Header Row
            HStack(spacing: 12) {
                // Back button (since tab bar is hidden on chat)
                Button(action: { onBackTap?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.gold)
                        .frame(width: 44, height: 44)
                }
                
                // History button
                Button(action: { onHistoryTap?() }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.Colors.gold) // Standardizing to Gold
                        .frame(width: 40, height: 40)
                }
                
                Spacer()
                
                // Logo
                LogoView()
                
                Spacer()
                
                // Chart button
                Button(action: { onChartTap?() }) {
                    Image(systemName: "globe.asia.australia")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.Colors.gold) // Standardizing to Gold
                        .frame(width: 40, height: 40)
                }
                
                // New chat button
                Button(action: { onNewChatTap?() }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.Colors.gold)
                        .frame(width: 40, height: 40)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.clear)
    }
}

// MARK: - Match Input Header (for Compatibility input screen - with history, logo)
struct MatchInputHeader: View {
    var onHistoryTap: (() -> Void)? = nil
    var onNewMatchTap: (() -> Void)? = nil
    
    // Profile Context
    private let profileContext = ProfileContextManager.shared
    
    var body: some View {
        VStack(spacing: 4) {
            // Profile Context Indicator (non-tappable, shows who we're viewing)
            // Note: Switching is only allowed from Home screen
            if !profileContext.isUsingSelf {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.caption)
                    
                    Text("Viewing as \(profileContext.activeProfileName)")
                        .font(AppTheme.Fonts.caption())
                }
                .foregroundColor(AppTheme.Colors.gold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(AppTheme.Colors.gold.opacity(0.15))
                        .overlay(Capsule().stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1))
                )
            }
            
            // Main Header Row
            HStack(spacing: 12) {
                // History button
                Button(action: { onHistoryTap?() }) {
                    ZStack {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1))
                        
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                }
                
                Spacer()
                
                // Logo
                LogoView()
                
                Spacer()
                
                // New match button (clears form)
                Button(action: { onNewMatchTap?() }) {
                    ZStack {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1))
                        
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.clear)
    }
}

// MARK: - Match Result Header (with back, history, charts, new match buttons)
struct MatchResultHeader: View {
    var boyName: String
    var girlName: String
    var onBackTap: (() -> Void)? = nil
    var onHistoryTap: (() -> Void)? = nil
    var onChartTap: (() -> Void)? = nil
    var onNewMatchTap: (() -> Void)? = nil
    var transparent: Bool = false
    
    // Helper to get first name
    private func firstName(_ fullName: String) -> String {
        return fullName.components(separatedBy: " ").first ?? fullName
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Back button
            Button(action: { onBackTap?() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.gold)
                    .frame(width: 44, height: 44)
            }
            
            // History button
            Button(action: { onHistoryTap?() }) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.Colors.gold) // Standardizing to Gold
                    .frame(width: 40, height: 40)
            }
            
            Spacer()
            
            // Center: Name - Icon - Name
            HStack(spacing: 4) {
                Text(firstName(boyName))
                    .font(AppTheme.Fonts.title(size: 18))
                    .foregroundColor(AppTheme.Colors.gold) // Standardizing text to Gold to match logo
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                Image("match_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 32)
                
                Text(firstName(girlName))
                    .font(AppTheme.Fonts.title(size: 18))
                    .foregroundColor(AppTheme.Colors.gold) // Standardizing text to Gold to match logo
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            
            Spacer()
            
            // Chart button
            Button(action: { onChartTap?() }) {
                Image(systemName: "globe.asia.australia")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.Colors.gold) // Standardizing to Gold
                    .frame(width: 40, height: 40)
            }
            
            // New match button
            Button(action: { onNewMatchTap?() }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.Colors.gold)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(transparent ? Color.clear : AppTheme.Colors.mainBackground)
    }
}

// Helper for blur
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - Previews
#Preview("App Header") {
    VStack {
        AppHeader()
        Spacer()
    }
    .background(AppTheme.Colors.mainBackground)
}

#Preview("Chat Header") {
    VStack {
        ChatHeader()
        Spacer()
    }
    .background(AppTheme.Colors.mainBackground)
}

#Preview("Match Result Header") {
    VStack {
        MatchResultHeader(boyName: "Prabhu", girlName: "Raju")
        Spacer()
    }
    .background(AppTheme.Colors.mainBackground)
}

#Preview("Logo") {
    LogoView()
        .padding()
        .background(AppTheme.Colors.mainBackground)
}

