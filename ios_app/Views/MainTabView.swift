import SwiftUI

/// Main tab view with custom floating tab bar
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showHistory = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            Group {
                switch selectedTab {
                case 0:
                    HomeView()
                case 1:
                    ChatView(onBack: { selectedTab = 0 })  // Pass back handler
                case 2:
                    CompatibilityView()
                default:
                    HomeView()
                }
            }
            
            // Custom Tab Bar - Hidden on Chat screen (Option 1: iMessage style)
            if selectedTab != 1 {
                CustomTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard)
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            // Home Tab
            TabBarItem(
                icon: "house.fill",
                title: "Home",
                isSelected: selectedTab == 0
            ) {
                withAnimation(.spring(response: 0.3)) {
                    selectedTab = 0
                }
            }
            
            // Ask Tab (Center - FAB Style)
            AskTabButton(isSelected: selectedTab == 1) {
                withAnimation(.spring(response: 0.3)) {
                    selectedTab = 1
                }
            }
            
            // Match Tab
            TabBarItem(
                icon: "heart.fill",
                title: "Match",
                isSelected: selectedTab == 2
            ) {
                withAnimation(.spring(response: 0.3)) {
                    selectedTab = 2
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 20, y: -5)
        )
    }
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .symbolEffect(.bounce, value: isSelected)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(isSelected ? Color("NavyPrimary") : Color("TextDark").opacity(0.4))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ask Tab Button (FAB Style)
struct AskTabButton: View {
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Outer glow when selected
                    if isSelected {
                        Circle()
                            .fill(Color("GoldAccent").opacity(0.2))
                            .frame(width: 64, height: 64)
                    }
                    
                    // Main button
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color("GoldAccent"),
                                    Color("GoldAccent").opacity(0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(
                            color: Color("GoldAccent").opacity(0.4),
                            radius: isSelected ? 12 : 8,
                            y: 4
                        )
                    
                    // Icon
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color("NavyPrimary"))
                        .symbolEffect(.bounce, value: isSelected)
                }
                .offset(y: -20)
                
                Text("Ask")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? Color("NavyPrimary") : Color("NavyPrimary").opacity(0.7))
                    .offset(y: -16)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}
