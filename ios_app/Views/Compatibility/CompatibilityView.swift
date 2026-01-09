import SwiftUI

/// Compatibility/Match analysis screen
struct CompatibilityView: View {
    @State private var viewModel = CompatibilityViewModel()
    @State private var selectedTab = 0 // 0 = Boy, 1 = Girl
    @State private var showBoyLocationSearch = false
    @State private var showGirlLocationSearch = false
    @State private var showChartsSheet = false
    
    // Quota and subscription UI state
    // Quota and subscription UI state
    @State private var showQuotaExhausted = false
    @State private var quotaErrorMessage: String?
    @State private var showSubscription = false
    @AppStorage("isGuest") private var isGuest = false
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @AppStorage("hasBirthData") private var hasBirthData = false
    
    // External callbacks/props
    var initialMatchItem: CompatibilityHistoryItem? = nil
    var onShowResultChange: ((Bool) -> Void)? = nil
    
    @State private var hasHandledInitialMatch = false
    
    var body: some View {
        ZStack {
            // Dark Midnight Background
            AppTheme.Colors.mainBackground
                .ignoresSafeArea()
            
            if viewModel.showResult, let result = viewModel.result {
                CompatibilityResultView(
                    result: result,
                    boyName: viewModel.boyName,
                    girlName: viewModel.girlName,
                    boyDob: viewModel.formattedBoyDob,
                    girlDob: viewModel.formattedGirlDob,
                    boyCity: viewModel.boyCity,
                    girlCity: viewModel.girlCity,
                    onNewAnalysis: {
                        viewModel.reset()
                    },
                    onBack: {
                        viewModel.showResult = false
                    },
                    onHistory: nil,
                    onCharts: {
                        showChartsSheet = true
                    },
                    onLoadHistory: { item in
                        viewModel.loadFromHistory(item)
                    }
                )
            } else {
                compatibilityForm
            }
            
            // Premium streaming progress overlay
            if viewModel.showStreamingView {
                CompatibilityStreamingView(
                    isVisible: $viewModel.showStreamingView,
                    currentStep: $viewModel.currentStep,
                    streamingText: $viewModel.streamingText
                )
            }
        }
        .sheet(isPresented: $showBoyLocationSearch) {
            LocationSearchView(
                selectedCity: $viewModel.boyCity,
                latitude: $viewModel.boyLatitude,
                longitude: $viewModel.boyLongitude,
                placeId: .constant(nil)
            )
        }
        .sheet(isPresented: $showGirlLocationSearch) {
            LocationSearchView(
                selectedCity: $viewModel.girlCity,
                latitude: $viewModel.girlLatitude,
                longitude: $viewModel.girlLongitude,
                placeId: .constant(nil)
            )
        }
        .sheet(isPresented: $showChartsSheet) {
            if let result = viewModel.result {
                let boyAsc = result.analysisData?.boy?.chartData?.d1["Ascendant"]?.sign
                let girlAsc = result.analysisData?.girl?.chartData?.d1["Ascendant"]?.sign
                ChartComparisonSheet(
                    boyName: viewModel.boyName.isEmpty ? "You" : viewModel.boyName,
                    girlName: viewModel.girlName.isEmpty ? "Partner" : viewModel.girlName,
                    boyChartData: result.analysisData?.boy?.chartData,
                    girlChartData: result.analysisData?.girl?.chartData,
                    boyAscendant: boyAsc,
                    girlAscendant: girlAsc
                )
            }
        }
        .sheet(isPresented: $showQuotaExhausted) {
            QuotaExhaustedView(
                isGuest: isGuest,
                customMessage: quotaErrorMessage,
                onSignIn: { signOutAndReauth() },
                onUpgrade: {
                    if isGuest {
                        signOutAndReauth()
                    } else {
                        showSubscription = true
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
        }
        .onChange(of: viewModel.showResult) { _, newValue in
            onShowResultChange?(newValue)
        }
        // Handle initial match loading
        .onChange(of: initialMatchItem) { oldValue, newValue in
            if let item = newValue {
                viewModel.loadFromHistory(item)
            }
        }
        .onAppear {
            if let item = initialMatchItem, !hasHandledInitialMatch {
                hasHandledInitialMatch = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.loadFromHistory(item)
                }
            }
        }
    }
    
    // MARK: - Sign Out for Guest Re-auth
    private func signOutAndReauth() {
        // Clear all guest data so user starts fresh with Apple Sign-In
        isGuest = false
        isAuthenticated = false
        hasBirthData = false
        
        let keysToRemove = [
            "userEmail", "userName", "quotaUsed", "userBirthData",
            "hasBirthData", "userGender", "birthTimeUnknown", "isGuest"
        ]
        keysToRemove.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        
        let keychain = KeychainService.shared
        keychain.delete(forKey: KeychainService.Keys.userId)
        keychain.delete(forKey: KeychainService.Keys.authToken)
        
        print("[CompatibilityView] Guest data cleared for fresh sign-in")
    }
    
    // MARK: - Form View
    private var compatibilityForm: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header with gold interlocking rings icon
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image("match_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                        
                        Text("kundali_match".localized)
                            .font(AppTheme.Fonts.display(size: 24))
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                    
                    Text("ashtakoot_analysis".localized)
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(.top, 20)
                
                // Tab Selector
                tabSelector
                    .padding(.horizontal, 20)
                
                // Form based on selected tab
                if selectedTab == 0 {
                    boyFormCard
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                } else {
                    girlFormCard
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                
                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundColor(AppTheme.Colors.error)
                        .padding(.horizontal, 20)
                }
                
                // Analyze button
                analyzeButton
                
                // Spacer for tab bar
                Spacer(minLength: 20)
            }
            .padding(.top, 8)
        }
        .padding(.bottom, 90) // Reserve space for Transparent Tab Bar
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            // Boy's Details Tab
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedTab = 0
                }
                HapticManager.shared.play(.light)
            }) {
                Text("boys_details".localized)
                    .font(AppTheme.Fonts.title(size: 15))
                    .foregroundColor(selectedTab == 0 ? AppTheme.Colors.mainBackground : AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        selectedTab == 0 
                            ? AnyView(AppTheme.Colors.premiumGradient)
                            : AnyView(Color.clear)
                    )
                    .cornerRadius(12)
            }
            
            // Girl's Details Tab
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedTab = 1
                }
                HapticManager.shared.play(.light)
            }) {
                Text("girls_details".localized)
                    .font(AppTheme.Fonts.title(size: 15))
                    .foregroundColor(selectedTab == 1 ? AppTheme.Colors.mainBackground : AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        selectedTab == 1 
                            ? AnyView(AppTheme.Colors.premiumGradient)
                            : AnyView(Color.clear)
                    )
                    .cornerRadius(12)
            }
        }
        .padding(4)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.Styles.goldBorder.stroke, lineWidth: AppTheme.Styles.goldBorder.width)
        )
    }
    
    // MARK: - Boy Form Card (You)
    private var boyFormCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                // Row 1: Name and Gender
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("boys_name".localized)
                            .font(AppTheme.Fonts.body(size: 12))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Text(viewModel.boyName.isEmpty ? "not_set".localized : viewModel.boyName)
                            .font(AppTheme.Fonts.body(size: 15))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .padding(.horizontal, 12)
                            .frame(height: 52)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.Colors.inputBackground)
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("gender".localized.uppercased())
                            .font(AppTheme.Fonts.body(size: 12))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Text(userGenderDisplayText)
                            .font(AppTheme.Fonts.body(size: 14))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .padding(.horizontal, 12)
                            .frame(height: 52)
                            .frame(minWidth: 100)
                            .background(AppTheme.Colors.inputBackground)
                            .cornerRadius(12)
                    }
                }
                
                // Row 2: Date and Time
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("date_of_birth_caps".localized)
                            .font(AppTheme.Fonts.body(size: 12))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        HStack {
                            Text(formattedBoyDate)
                                .font(AppTheme.Fonts.body(size: 15))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Spacer()
                            Image(systemName: "calendar")
                                .font(AppTheme.Fonts.body(size: 14))
                                .foregroundColor(AppTheme.Colors.gold.opacity(0.5))
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 52)
                        .background(AppTheme.Colors.inputBackground)
                        .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("time_caps".localized)
                            .font(AppTheme.Fonts.body(size: 12))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        HStack {
                            Text(viewModel.boyTimeUnknown ? "birth_time_unknown".localized : formattedBoyTime)
                                .font(AppTheme.Fonts.body(size: 15))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Spacer()
                            Image(systemName: "clock")
                                .font(AppTheme.Fonts.body(size: 14))
                                .foregroundColor(AppTheme.Colors.gold.opacity(0.5))
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 52)
                        .background(AppTheme.Colors.inputBackground)
                        .cornerRadius(12)
                    }
                }
                
                // Row 3: Place of Birth
                VStack(alignment: .leading, spacing: 4) {
                    Text("place_of_birth_caps".localized)
                        .font(AppTheme.Fonts.body(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Button(action: { showBoyLocationSearch = true }) {
                        HStack {
                            Image(systemName: "location.fill")
                                .font(AppTheme.Fonts.body(size: 14))
                                .foregroundColor(AppTheme.Colors.gold)
                            
                            Text(viewModel.boyCity.isEmpty ? "select_city".localized : viewModel.boyCity)
                                .font(AppTheme.Fonts.body(size: 15))
                                .foregroundColor(viewModel.boyCity.isEmpty ? AppTheme.Colors.textSecondary : AppTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(AppTheme.Fonts.caption(size: 12))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 52)
                        .background(AppTheme.Colors.inputBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.Styles.inputBorder.stroke, lineWidth: AppTheme.Styles.inputBorder.width)
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Girl Form Card (Partner)
    private var girlFormCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                // Row 1: Name and Gender
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        PremiumTextField(
                            "girls_name".localized,
                            text: $viewModel.girlName,
                            placeholder: "enter_name".localized
                        )
                    }
                    
                    // Gender Menu
                    VStack(alignment: .leading, spacing: 4) {
                         Text("GENDER")
                            .font(AppTheme.Fonts.body(size: 14))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            
                        Menu {
                            Button("prefer_not_to_say".localized) { viewModel.partnerGender = "" }
                            Button("male".localized) { viewModel.partnerGender = "male" }
                            Button("female".localized) { viewModel.partnerGender = "female" }
                            Button("non_binary".localized) { viewModel.partnerGender = "non-binary" }
                        } label: {
                            HStack(spacing: 4) {
                                Text(genderDisplayText)
                                    .font(AppTheme.Fonts.body(size: 14))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(AppTheme.Fonts.caption(size: 10))
                                    .foregroundColor(AppTheme.Colors.gold)
                            }
                            .padding(.horizontal, 10)
                            .frame(height: 52)
                            .frame(minWidth: 110)
                            .background(AppTheme.Colors.inputBackground)
                            .cornerRadius(12)
                            .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.Styles.inputBorder.stroke, lineWidth: AppTheme.Styles.inputBorder.width)
                        )
                        }
                    }
                }
                
                // Row 2: Date and Time
                HStack(spacing: 12) {
                    // Date
                    VStack(alignment: .leading, spacing: 4) {
                        Text("date_of_birth_caps".localized)
                             .font(AppTheme.Fonts.body(size: 14))
                             .foregroundColor(AppTheme.Colors.textSecondary)
                        MatchDateButton(date: $viewModel.girlBirthDate)
                    }
                    
                    // Time
                    VStack(alignment: .leading, spacing: 4) {
                        Text("time_caps".localized)
                             .font(AppTheme.Fonts.body(size: 14))
                             .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        if viewModel.partnerTimeUnknown {
                            HStack {
                                Text("birth_time_unknown".localized)
                                    .font(AppTheme.Fonts.body(size: 15))
                                    .foregroundColor(AppTheme.Colors.textPrimary.opacity(0.6))
                                Spacer()
                                Image(systemName: "clock")
                                    .font(AppTheme.Fonts.body(size: 14))
                                    .foregroundColor(AppTheme.Colors.gold.opacity(0.3))
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 52)
                            .background(AppTheme.Colors.inputBackground)
                            .cornerRadius(12)
                        } else {
                            MatchTimeButton(time: $viewModel.girlBirthTime)
                        }
                    }
                }
                
                // Time unknown toggle
                HStack(spacing: 8) {
                    Button(action: { 
                         HapticManager.shared.play(.light)
                         viewModel.partnerTimeUnknown.toggle() 
                    }) {
                        Image(systemName: viewModel.partnerTimeUnknown ? "checkmark.square.fill" : "square")
                            .font(AppTheme.Fonts.title(size: 18))
                            .foregroundColor(viewModel.partnerTimeUnknown ? AppTheme.Colors.gold : AppTheme.Colors.textSecondary)
                    }
                    
                    Text("partner_birth_time_unknown".localized)
                        .font(AppTheme.Fonts.body(size: 13))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                // Warning note
                if viewModel.partnerTimeUnknown {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(AppTheme.Fonts.caption(size: 12))
                            .foregroundColor(AppTheme.Colors.warning)
                        
                        Text("birth_time_warning".localized)
                            .font(AppTheme.Fonts.body(size: 11))
                            .foregroundColor(AppTheme.Colors.warning)
                    }
                    .padding(10)
                    .background(AppTheme.Colors.warning.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Row 3: Place of Birth
                VStack(alignment: .leading, spacing: 4) {
                    Text("place_of_birth_caps".localized)
                        .font(AppTheme.Fonts.body(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Button(action: { showGirlLocationSearch = true }) {
                        HStack {
                            Image(systemName: "location.fill")
                                .font(AppTheme.Fonts.body(size: 14))
                                .foregroundColor(AppTheme.Colors.gold)
                            
                            Text(viewModel.girlCity.isEmpty ? "select_city".localized : viewModel.girlCity)
                                .font(AppTheme.Fonts.body(size: 15))
                                .foregroundColor(viewModel.girlCity.isEmpty ? AppTheme.Colors.textSecondary : AppTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(AppTheme.Fonts.caption(size: 12))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 52)
                        .background(AppTheme.Colors.inputBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.Styles.inputBorder.stroke, lineWidth: AppTheme.Styles.inputBorder.width)
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Analyze Button
    private var analyzeButton: some View {
        PremiumButton(
            "analyze_match".localized,
            icon: "sparkles",
            isLoading: viewModel.isAnalyzing
        ) {
            Task {
                // Check quota for COMPATIBILITY feature
                let email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
                do {
                    let accessResponse = try await QuotaManager.shared.canAccessFeature(.compatibility, email: email)
                    if accessResponse.canAccess {
                        await viewModel.analyzeMatch()
                        // Quota is now recorded server-side by /compatibility/analyze endpoint
                    } else {
                        await MainActor.run {
                            // Professional Quota UI - Daily=banner, Overall/Feature=sheet
                            if accessResponse.reason == "daily_limit_reached" {
                                // DAILY LIMIT: Show message (for banner), no sheet
                                if let resetAtStr = accessResponse.resetAt,
                                   let date = ISO8601DateFormatter().date(from: resetAtStr) {
                                    let timeFormatter = DateFormatter()
                                    timeFormatter.timeStyle = .short
                                    let timeStr = timeFormatter.string(from: date)
                                    viewModel.errorMessage = "Daily limit reached. Resets at \(timeStr)."
                                } else {
                                    viewModel.errorMessage = "Daily limit reached. Resets tomorrow."
                                }
                                // No sheet for daily limit
                            } else if accessResponse.reason == "overall_limit_reached" {
                                // OVERALL LIMIT: Show sheet only
                                if email.contains("guest") || email.contains("@gen.com") {
                                    quotaErrorMessage = "Free questions used. Sign In or Subscribe to continue."
                                } else {
                                    quotaErrorMessage = "You've reached your free limit. Subscribe for unlimited access."
                                }
                                showQuotaExhausted = true
                            } else {
                                // FEATURE NOT AVAILABLE: Show sheet only
                                quotaErrorMessage = accessResponse.upgradeCta?.message ?? "Upgrade to unlock this feature."
                                showQuotaExhausted = true
                            }
                        }
                    }
                } catch {
                    print("❌ Quota check failed: \(error)")
                    await MainActor.run {
                        quotaErrorMessage = "Unable to check compatibility access."
                        showQuotaExhausted = true
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // Helpers
    private var userGenderDisplayText: String {
        switch viewModel.boyGender {
        case "male": return "male".localized
        case "female": return "female".localized
        case "non-binary": return "non_binary".localized
        default: return "prefer_not_to_say".localized
        }
    }
    
    private var formattedBoyDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: viewModel.boyBirthDate)
    }
    
    private var formattedBoyTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: viewModel.boyBirthTime)
    }
    
    private var genderDisplayText: String {
        switch viewModel.partnerGender {
        case "male": return "male".localized
        case "female": return "female".localized
        case "non-binary": return "non_binary".localized
        default: return "prefer_not_to_say".localized
        }
    }
}

// MARK: - Helper Components (Dark Mode)
struct MatchDateButton: View {
    @Binding var date: Date
    @State private var showPicker = false
    
    var body: some View {
        Button(action: { showPicker = true }) {
            HStack {
                Text(formatDate(date))
                    .font(AppTheme.Fonts.body(size: 15))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
                Image(systemName: "calendar")
                    .font(AppTheme.Fonts.body(size: 14))
                    .foregroundColor(AppTheme.Colors.gold.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .frame(height: 52)
            .background(AppTheme.Colors.inputBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.Styles.inputBorder.stroke, lineWidth: AppTheme.Styles.inputBorder.width)
            )
        }
        .sheet(isPresented: $showPicker) {
            MatchDatePickerSheet(date: $date, title: "Select Date")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

struct MatchTimeButton: View {
    @Binding var time: Date
    @State private var showPicker = false
    
    var body: some View {
        Button(action: { showPicker = true }) {
            HStack {
                Text(formatTime(time))
                    .font(AppTheme.Fonts.body(size: 15))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
                Image(systemName: "clock")
                    .font(AppTheme.Fonts.body(size: 14))
                    .foregroundColor(AppTheme.Colors.gold.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .frame(height: 52)
            .background(AppTheme.Colors.inputBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.Styles.inputBorder.stroke, lineWidth: AppTheme.Styles.inputBorder.width)
            )
        }
        .sheet(isPresented: $showPicker) {
            MatchTimePickerSheet(time: $time, title: "Select Time")
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Picker Sheets (Dark Mode)
struct MatchDatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date
    let title: String
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.mainBackground.ignoresSafeArea()
                VStack {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .colorScheme(.dark)
                        .accentColor(AppTheme.Colors.gold)
                        .padding()
                    Spacer()
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.Colors.gold)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
             .toolbarBackground(AppTheme.Colors.mainBackground, for: .navigationBar)
        }
        .presentationDetents([.medium])
    }
}

struct MatchTimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var time: Date
    let title: String
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.mainBackground.ignoresSafeArea()
                VStack {
                    DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .colorScheme(.dark)
                        .labelsHidden()
                        .padding()
                    Spacer()
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.Colors.gold)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.mainBackground, for: .navigationBar)
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    CompatibilityView()
}
