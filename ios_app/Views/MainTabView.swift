import SwiftUI
import Combine

/// Main tab view with custom floating tab bar
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showHistory = false
    @State private var showAskSheet = false  // New: Show Ask Destiny Sheet
    @State private var pendingQuestion: String? = nil
    @State private var pendingThreadId: String? = nil
    @State private var pendingMatchItem: CompatibilityHistoryItem? = nil
    @State private var pendingMatchGroup: ComparisonGroup? = nil
    @State private var showMatchResult = false  // Track if match result is showing
    @State private var homeViewModel = HomeViewModel()  // Shared for life areas data
    @State private var showGuestSignInSheet = false  // Guest sign-in prompt for Match tab
    @State private var isKeyboardVisible = false  // Track keyboard for tab bar hiding
    
    /// Reactive guest user check - uses @AppStorage for automatic UI updates
    @AppStorage("isGuest") private var isGuestUser = false

    
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
                            // Guest cannot view match history - show sign in
                            if isGuestUser {
                                showGuestSignInSheet = true
                            } else {
                                pendingMatchItem = matchItem
                                pendingMatchGroup = nil  // Clear any pending group
                                selectedTab = 2 // Navigate to match
                            }
                        },
                        onMatchGroupHistorySelected: { group in
                            if isGuestUser {
                                showGuestSignInSheet = true
                            } else {
                                pendingMatchGroup = group
                                pendingMatchItem = nil  // Clear any pending single item
                                selectedTab = 2 // Navigate to match
                            }
                        }
                    )
                    .ignoresSafeArea(.keyboard)
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
                    // Guest users cannot access Match tab - show sign-in prompt
                    if isGuestUser {
                        GuestSignInPromptView(
                            message: "sign_in_to_check_compatibility".localized,
                            onBack: { selectedTab = 0 }
                        )
                        .ignoresSafeArea(.keyboard)
                    } else {
                        CompatibilityView(
                            initialMatchItem: pendingMatchItem,
                            initialMatchGroup: pendingMatchGroup,
                            onShowResultChange: { isShowing in
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showMatchResult = isShowing
                                }
                            }
                        )
                        .id(ProfileContextManager.shared.activeProfileId) // Force recreation on profile switch
                        .ignoresSafeArea(.keyboard)
                    }
                default:
                    HomeView(onQuestionSelected: { _ in })
                        .ignoresSafeArea(.keyboard)
                }
            }
            
            // Custom Tab Bar - Hidden on Chat screen, Match Result screen, and when keyboard is visible
            if selectedTab != 1 && !showMatchResult && !isKeyboardVisible {
                CustomTabBar(selectedTab: $selectedTab, showAskSheet: $showAskSheet)
                    // No horizontal padding for full width
                    .padding(.bottom, 0) // Docked to bottom
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // Note: .ignoresSafeArea(.keyboard) removed from here
        // Applied per-tab instead so ChatView gets proper keyboard avoidance
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
        .animation(.easeInOut(duration: 0.25), value: showMatchResult)
        .animation(.easeInOut(duration: 0.2), value: isKeyboardVisible)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
        // Clear pending match state when switching profiles
        .onChange(of: ProfileContextManager.shared.activeProfileId) { _, _ in
            pendingMatchItem = nil
            pendingMatchGroup = nil
            showMatchResult = false
        }
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
                    // Navigate directly to Chat screen (skip intermediate sheet)
                    selectedTab = 1
                }
            }
            .frame(width: 80) // Fixed width for center
            
            Spacer()
            
            // Match Tab (Right)
            TabBarItem(
                icon: "heart.fill",
                title: "match".localized,
                isSelected: selectedTab == 2
            ) {
                withAnimation(.spring(response: 0.3)) {
                    selectedTab = 2
                }
            }
            .frame(width: 60) // Fixed width touch target
        }
        .padding(.horizontal, 30) // HIG: ~30pt minimum from edges
        .padding(.top, 4)        // Minimal top padding
        .padding(.bottom, 0)    // Use Safe Area
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // Sleek Transparent Background
                Rectangle()
                    .fill(Color.clear) // Transparent
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
            .tabItemStyle(isSelected: isSelected)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                            .frame(width: 56, height: 56) // Reduced
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
                        .frame(width: 48, height: 48) // Compact HIG
                        .shadow(
                            color: AppTheme.Colors.gold.opacity(0.5),
                            radius: isSelected ? 10 : 6,
                            y: 3
                        )
                    
                    // Icon
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(AppTheme.Fonts.title(size: 22))
                        .foregroundColor(AppTheme.Colors.darkNavyContrast)
                        .symbolEffect(.bounce, value: isSelected)
                }
                .offset(y: -12) // Reduced offset for minimal space
                
                Text("ask".localized)
                    .font(AppTheme.Fonts.caption(size: 11))
                    .foregroundColor(isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.gold)
                    .offset(y: -10) // Adjusted for smaller FAB
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("ask".localized)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}

// MARK: - Extensions
extension View {
    /// Applies a radiant gold gradient mask if unselected, otherwise solid color
    @ViewBuilder
    func tabItemStyle(isSelected: Bool) -> some View {
        if isSelected {
            self.foregroundColor(AppTheme.Colors.textPrimary)
        } else {
            self.overlay(
                LinearGradient(
                    colors: [
                        AppTheme.Colors.goldChampagne,
                        AppTheme.Colors.gold
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .mask(self)
        }
    }
}
