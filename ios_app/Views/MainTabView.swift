import SwiftUI

/// Main tab view with custom floating tab bar
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showHistory = false
    @State private var showAskSheet = false  // New: Show Ask Destiny Sheet
    @State private var pendingQuestion: String? = nil
    @State private var pendingThreadId: String? = nil
    @State private var pendingMatchItem: CompatibilityHistoryItem? = nil
    @State private var showMatchResult = false  // Track if match result is showing
    @State private var homeViewModel = HomeViewModel()  // Shared for life areas data
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            Group {
                switch selectedTab {
                case 0:
                    HomeView(
                        onQuestionSelected: { question in
                            pendingQuestion = question
                            selectedTab = 1  // Navigate to chat
                        },
                        onChatHistorySelected: { threadId in
                            pendingThreadId = threadId
                            selectedTab = 1 // Navigate to chat
                        },
                        onMatchHistorySelected: { matchItem in
                            pendingMatchItem = matchItem
                            selectedTab = 2 // Navigate to match
                        }
                    )
                case 1:
                    ChatView(
                        onBack: { 
                            selectedTab = 0 
                            pendingQuestion = nil  // Clear pending question
                            pendingThreadId = nil
                        },
                        initialQuestion: pendingQuestion,
                        initialThreadId: pendingThreadId
                    )
                case 2:
                    CompatibilityView(
                        initialMatchItem: pendingMatchItem,
                        onShowResultChange: { isShowing in
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showMatchResult = isShowing
                            }
                        }
                    )
                default:
                    HomeView(onQuestionSelected: { _ in })
                }
            }
            
            // Custom Tab Bar - Hidden on Chat screen and Match Result screen
            if selectedTab != 1 && !showMatchResult {
                CustomTabBar(selectedTab: $selectedTab, showAskSheet: $showAskSheet)
                    // No horizontal padding for full width
                    .padding(.bottom, 0) // Docked to bottom
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard)
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
        .animation(.easeInOut(duration: 0.25), value: showMatchResult)
        .sheet(isPresented: $showAskSheet) {
            AskDestinyQuestionsSheet(
                suggestedQuestions: homeViewModel.suggestedQuestions,
                onQuestionSelected: { question in
                    pendingQuestion = question
                    selectedTab = 1  // Navigate to chat with question
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task {
            // Load home data to have life areas available for Ask sheet
            await homeViewModel.loadHomeData()
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showAskSheet: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Home Tab (Left)
            TabBarItem(
                icon: "house.fill",
                title: "home".localized,
                isSelected: selectedTab == 0
            ) {
                withAnimation(.spring(response: 0.3)) {
                    selectedTab = 0
                }
            }
            .frame(width: 60) // Fixed width touch target
            
            Spacer()
            
            // Ask Tab (Center - FAB Style)
            AskTabButton(isSelected: selectedTab == 1) {
                withAnimation(.spring(response: 0.3)) {
                    // Show Ask sheet instead of navigating directly
                    showAskSheet = true
                }
            }
            .frame(width: 80) // Fixed width for center
            
            Spacer()
            
            // Match Tab (Right)
            TabBarItem(
                icon: "heart.fill",
                title: "match".localized,
                isSelected: selectedTab == 2,
                accentColor: Color(red: 0.91, green: 0.71, blue: 0.72)
            ) {
                withAnimation(.spring(response: 0.3)) {
                    selectedTab = 2
                }
            }
            .frame(width: 60) // Fixed width touch target
        }
        .padding(.horizontal, 40) // Position icons comfortably near edges (standard ~30-40pt)
        .padding(.top, 6)       // Ultra lean top padding
        .padding(.bottom, 0)    // Use Safe Area
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // Sleek Glassy Background
                Rectangle()
                    .fill(AppTheme.Colors.tabBarBackground.opacity(0.85))
                    .background(.ultraThinMaterial) // Glass blur
                    .ignoresSafeArea()
                
                // Top Border Line
                VStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    AppTheme.Colors.gold.opacity(0.5),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                    Spacer()
                }
            }
        )
    }
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    var accentColor: Color? = nil  // Optional custom color when selected
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .symbolEffect(.bounce, value: isSelected)
                
                Text(title)
                    .font(AppTheme.Fonts.caption(size: 11))
            }
            .foregroundColor(isSelected ? (accentColor ?? AppTheme.Colors.gold) : AppTheme.Colors.tabInactive)
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
                            .fill(AppTheme.Colors.gold.opacity(0.3))
                            .frame(width: 64, height: 64)
                    }
                    
                    // Main button - champagne gold gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.Colors.goldChampagne,
                                    AppTheme.Colors.gold
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(
                            color: AppTheme.Colors.gold.opacity(0.5),
                            radius: isSelected ? 12 : 8,
                            y: 4
                        )
                    
                    // Icon
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(AppTheme.Fonts.title(size: 22))
                        .foregroundColor(AppTheme.Colors.darkNavyContrast)
                        .symbolEffect(.bounce, value: isSelected)
                }
                .offset(y: -20)
                
                Text("ask".localized)
                    .font(AppTheme.Fonts.caption(size: 11))
                    .foregroundColor(isSelected ? AppTheme.Colors.gold : AppTheme.Colors.tabInactive)
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
