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
                        .foregroundColor(Color("NavyPrimary"))
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
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color("NavyPrimary"))
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
                                .fill(Color("NavyPrimary"))
                                .frame(width: 32, height: 32)
                            
                            Text(initial)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 44, height: 44)
                    } else {
                        // Guest user - show person icon
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(Color("NavyPrimary").opacity(0.7))
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
    }
}

// MARK: - Logo View
struct LogoView: View {
    var body: some View {
        // Destiny wordmark logo
        Image("destiny_home")
            .resizable()
            .scaledToFit()
            .frame(height: 28)  // Height controls size, width auto-scales
    }
}

// MARK: - Chat Header (with history and new chat buttons)
struct ChatHeader: View {
    var onBackTap: (() -> Void)? = nil  // NEW: Back navigation
    var onHistoryTap: (() -> Void)? = nil
    var onNewChatTap: (() -> Void)? = nil
    var onChartTap: (() -> Void)? = nil
    var onProfileTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // Back button (since tab bar is hidden on chat)
            Button(action: { onBackTap?() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color("NavyPrimary"))
                    .frame(width: 44, height: 44)
            }
            
            // History button
            Button(action: { onHistoryTap?() }) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color("NavyPrimary"))
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
                    .foregroundColor(Color("NavyPrimary"))
                    .frame(width: 40, height: 40)
            }
            
            // New chat button
            Button(action: { onNewChatTap?() }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color("NavyPrimary"))
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Match Result Header (with back, history, charts, new match buttons)
struct MatchResultHeader: View {
    var onBackTap: (() -> Void)? = nil
    var onHistoryTap: (() -> Void)? = nil
    var onChartTap: (() -> Void)? = nil
    var onNewMatchTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // Back button
            Button(action: { onBackTap?() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color("NavyPrimary"))
                    .frame(width: 44, height: 44)
            }
            
            // History button
            Button(action: { onHistoryTap?() }) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color("NavyPrimary"))
                    .frame(width: 40, height: 40)
            }
            
            Spacer()
            
            // Title with heart icon
            HStack(spacing: 4) {
                Text("💕")
                    .font(.system(size: 16))
                Text("kundali_match".localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("NavyPrimary"))
            }
            
            Spacer()
            
            // Chart button
            Button(action: { onChartTap?() }) {
                Image(systemName: "globe.asia.australia")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color("NavyPrimary"))
                    .frame(width: 40, height: 40)
            }
            
            // New match button
            Button(action: { onNewMatchTap?() }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color("NavyPrimary"))
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Previews
#Preview("App Header") {
    VStack {
        AppHeader()
        Spacer()
    }
    .background(Color(red: 0.96, green: 0.95, blue: 0.98))
}

#Preview("Chat Header") {
    VStack {
        ChatHeader()
        Spacer()
    }
    .background(Color(red: 0.96, green: 0.95, blue: 0.98))
}

#Preview("Match Result Header") {
    VStack {
        MatchResultHeader()
        Spacer()
    }
    .background(Color(red: 0.96, green: 0.95, blue: 0.98))
}

#Preview("Logo") {
    LogoView()
        .padding()
}

