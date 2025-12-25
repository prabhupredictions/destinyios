import SwiftUI

/// App header component with logo, menu, and profile buttons
struct AppHeader: View {
    var title: String? = nil
    var showMenuButton: Bool = true
    var showProfileButton: Bool = true
    var onMenuTap: (() -> Void)? = nil
    var onProfileTap: (() -> Void)? = nil
    
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
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color("NavyPrimary").opacity(0.7))
                        .frame(width: 44, height: 44)
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
        HStack(spacing: 8) {
            // Logo circle with D
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("GoldAccent"), Color("GoldAccent").opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .shadow(color: Color("GoldAccent").opacity(0.3), radius: 4, y: 2)
                
                Text("D")
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundColor(Color("NavyPrimary"))
            }
            
            // App name
            Text("destiny")
                .font(.system(size: 22, weight: .light))
                .foregroundColor(Color("NavyPrimary"))
        }
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

#Preview("Logo") {
    LogoView()
        .padding()
}
