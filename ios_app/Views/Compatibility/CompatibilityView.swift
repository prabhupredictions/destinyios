import SwiftUI

/// Compatibility/Match analysis screen
struct CompatibilityView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = CompatibilityViewModel()
    @ObservedObject private var quotaManager = QuotaManager.shared
    @State private var selectedTab = 0 // 0 = Boy, 1 = Girl
    @State private var showBoyLocationSearch = false
    @State private var showGirlLocationSearch = false
    @State private var showChartsSheet = false
    @State private var showPartnerPicker = false
    @State private var savePartnerForFuture = false
    
    // Focus State for Name Field
    @FocusState private var isNameFocused: Bool
    
    // Picker States
    @State private var showBoyDatePicker = false
    @State private var showBoyTimePicker = false
    @State private var showGirlDatePicker = false
    @State private var showGirlTimePicker = false
    @State private var showGenderSheet = false
    @State private var showHistorySheet = false  // History access from input screen
    
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
    var initialMatchGroup: ComparisonGroup? = nil
    var onShowResultChange: ((Bool) -> Void)? = nil
    
    @State private var hasHandledInitialMatch = false
    @State private var hasHandledInitialGroup = false
    
    var body: some View {
        ZStack {
            // Cosmic Background (Soul of the App)
            CosmicBackgroundView()
            
            // Multi-Partner: Comparison Overview
            if viewModel.showComparisonOverview && !viewModel.comparisonResults.isEmpty {
                ComparisonOverviewView(
                    results: viewModel.comparisonResults,
                    userName: viewModel.boyName.isEmpty ? "You" : viewModel.boyName,
                    onSelectPartner: { index in
                        // Navigate to individual result
                        if viewModel.comparisonResults.indices.contains(index) {
                            viewModel.result = viewModel.comparisonResults[index].result
                            viewModel.girlName = viewModel.comparisonResults[index].partner.name
                            viewModel.showComparisonOverview = false  // Hide overview first
                            viewModel.showResult = true
                        }
                    },
                    onBack: {
                        viewModel.showComparisonOverview = false
                    },
                    onNewMatch: {
                        viewModel.reset()
                        viewModel.showComparisonOverview = false
                    }
                )
            }
            // Single Partner or Individual Result View
            else if viewModel.showResult, let result = viewModel.result {
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
                        // If we came from comparison overview, go back there
                        if viewModel.comparisonResults.count > 1 {
                            viewModel.showResult = false
                            viewModel.showComparisonOverview = true
                        } else {
                            viewModel.showResult = false
                        }
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
                if viewModel.partners.count > 1 {
                    // Multi-partner progress view
                    MultiPartnerStreamingView(
                        isVisible: $viewModel.showStreamingView,
                        partners: viewModel.partners,
                        completedResults: viewModel.comparisonResults,
                        currentPartnerIndex: viewModel.activePartnerIndex,
                        currentStep: viewModel.currentStep,
                        totalPartners: viewModel.partners.filter { $0.isComplete }.count
                    )
                } else {
                    // Single partner progress view
                    CompatibilityStreamingView(
                        isVisible: $viewModel.showStreamingView,
                        currentStep: $viewModel.currentStep,
                        streamingText: $viewModel.streamingText
                    )
                }
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
        .sheet(isPresented: $showBoyDatePicker) {
            DatePickerSheet(
                title: "date_of_birth".localized,
                selection: $viewModel.boyBirthDate,
                components: .date
            )
        }
        .sheet(isPresented: $showBoyTimePicker) {
            DatePickerSheet(
                title: "time_of_birth".localized,
                selection: $viewModel.boyBirthTime,
                components: .hourAndMinute
            )
        }
        .sheet(isPresented: $showGirlDatePicker) {
            DatePickerSheet(
                title: "date_of_birth".localized,
                selection: $viewModel.girlBirthDate,
                components: .date
            )
        }
        .sheet(isPresented: $showGirlTimePicker) {
            DatePickerSheet(
                title: "time_of_birth".localized,
                selection: $viewModel.girlBirthTime,
                components: .hourAndMinute
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
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
        }
        // "Loaded from history" toast when cached match is used
        .overlay(alignment: .top) {
            if viewModel.historyLoadedToast {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("Loaded from history")
                }
                .font(AppTheme.Fonts.body(size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.purple.opacity(0.85))
                )
                .padding(.top, 60)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation { viewModel.historyLoadedToast = false }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.historyLoadedToast)
        .sheet(isPresented: $showHistorySheet) {
            CompatibilityHistorySheet(
                onSelect: { selectedItem in
                    showHistorySheet = false
                    viewModel.loadFromHistory(selectedItem)
                },
                onGroupSelect: { selectedGroup in
                    showHistorySheet = false
                    viewModel.loadFromHistoryGroup(selectedGroup)
                }
            )
        }
        .sheet(isPresented: $showGenderSheet) {
            PremiumSelectionSheet(
                title: "gender_identity".localized,
                selectedValue: $viewModel.partnerGender,
                options: [
                    ("male", "male".localized),
                    ("female", "female".localized),
                    ("non-binary", "non_binary".localized),
                    ("prefer_not_to_say", "prefer_not_to_say".localized)
                ],
                onDismiss: { showGenderSheet = false }
            )
        }
        .sheet(isPresented: $showPartnerPicker) {
            // Compute IDs to exclude: active profile + partners already selected in other tabs
            let activeProfileId = ProfileContextManager.shared.activeProfileId
            let selectedProfileIds = Set(viewModel.partners.compactMap { $0.savedProfileId })
            let excludeIds = selectedProfileIds.union([activeProfileId])
            
            PartnerPickerSheet(
                isPresented: $showPartnerPicker,
                gender: nil,  // Show all partners, let user pick
                excludeIds: excludeIds
            ) { partner in
                // Fill form with selected partner data
                viewModel.girlName = partner.name
                viewModel.partnerGender = partner.gender
                viewModel.girlCity = partner.cityOfBirth ?? ""
                viewModel.girlLatitude = partner.latitude ?? 0
                viewModel.girlLongitude = partner.longitude ?? 0
                viewModel.partnerTimeUnknown = partner.birthTimeUnknown
                
                // Store the saved profile ID for filtering
                viewModel.currentPartner.savedProfileId = partner.id
                
                // Parse and set date
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if let date = dateFormatter.date(from: partner.dateOfBirth) {
                    viewModel.girlBirthDate = date
                }
                
                // Parse and set time if available
                if let timeString = partner.timeOfBirth {
                    let timeFormatter = DateFormatter()
                    timeFormatter.locale = Locale(identifier: "en_US_POSIX")
                    timeFormatter.dateFormat = "HH:mm"
                    if let time = timeFormatter.date(from: timeString) {
                        viewModel.girlBirthTime = time
                    }
                }
                
                HapticManager.shared.playSuccess()
            }
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
            if let group = initialMatchGroup, !hasHandledInitialGroup {
                hasHandledInitialGroup = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.loadFromHistoryGroup(group)
                }
            }
            
            // Pre-check "Save birth chart" for paid users (hide + unchecked for free users)
            if !quotaManager.isFreePlan {
                savePartnerForFuture = true
            }
        }
        .onChange(of: initialMatchGroup) { oldValue, newValue in
            if let group = newValue {
                viewModel.loadFromHistoryGroup(group)
            }
        }
        .onChange(of: ProfileContextManager.shared.activeProfileId) { oldProfileId, newProfileId in
            // When profile switches, clear old match result and reload user data
            if oldProfileId != newProfileId {
                viewModel.reset()
                // Reload user birth data for the new profile
                viewModel.reloadUserData()
            }
        }
    }
    
    // MARK: - Sign Out for Guest Re-auth
    private func signOutAndReauth() {
        // PHASE 12: DO NOT clear guest data here!
        // Preserve guest birth data for carry-forward during sign-in.
        isAuthenticated = false
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        
        print("[CompatibilityView] Navigating to Auth (guest data preserved for carry-forward)")
    }
    
    // MARK: - Form View (Compact Single-Screen Design)
    private var compatibilityForm: some View {
        VStack(spacing: 0) {
            // Header with History and Reset buttons (consistent with other screens)
            MatchInputHeader(
                onHistoryTap: { showHistorySheet = true },
                onNewMatchTap: { viewModel.reset() }
            )
            
            // Header with gold interlocking rings icon (BirthDataView Style)
            VStack(spacing: 12) { // Reduced spacing (was 16)
                // Compact Icon with Pulsing Glow
                ZStack {
                    // Outer glow
                    PulsingGlowView(
                        color: AppTheme.Colors.gold.opacity(0.3),
                        size: 80, // Reduced (was 90)
                        blurRadius: 25
                    )
                    
                    // Circle container
                    Circle()
                        .fill(AppTheme.Colors.inputBackground)
                        .frame(width: 64, height: 64) // Reduced (was 72)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.Colors.gold.opacity(0.4), lineWidth: 1)
                        )
                    
                    // Match Icon
                    Image("match_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30) // Reduced (was 34)
                        .shadow(color: AppTheme.Colors.gold.opacity(0.5), radius: 5)
                }
                
                VStack(spacing: 6) { // Reduced text spacing (was 8)
                    Text("ashtakoot_analysis".localized)
                        .font(AppTheme.Fonts.display(size: 22)) // Bold serif to match BirthDataView
                        .foregroundColor(AppTheme.Colors.textPrimary) 
                        .tracking(0.5) // Reduced tracking slightly
                    
                    Text("enter_details_desc_compatibility".localized)
                        .font(AppTheme.Fonts.body(size: 13)) // Slightly smaller (was 14)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.top, 10) // Reduced top padding (was 24)
            .padding(.bottom, 16) // Reduced bottom padding (was 20)
            
            // Unified Form Section (No Card Wrapper - Blends with Background)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // ═══════════════════════════════════════════════
                    // SECTION 1: Your Details (Compact Read-Only)
                    // ═══════════════════════════════════════════════
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.Colors.gold)
                            Text("your_details".localized)
                                .font(AppTheme.Fonts.caption(size: 11))
                                .foregroundColor(AppTheme.Colors.gold)

                            Spacer()
                            // Change button removed as requested
                        }
                        
                        // User Summary (Compact)
                        Text(viewModel.formattedUserSummary)
                            .font(AppTheme.Fonts.body(size: 14))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 11)
                            .padding(.horizontal, 10)
                            .background(AppTheme.Colors.inputBackground.opacity(0.6)) // Match partner fields
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppTheme.Colors.gold.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 4) // Align with fields
                    
                    // Divider (Gold Separation)
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, AppTheme.Colors.gold.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                    
                    // ═══════════════════════════════════════════════
                    // SECTION 2: Partner Details
                    // ═══════════════════════════════════════════════
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.Colors.gold)
                            Text("partner_details".localized)
                                .font(AppTheme.Fonts.caption(size: 11))
                                .foregroundColor(AppTheme.Colors.gold)
                        }
                        
                        // Compact Manual Entry Section (with search in name field)
                        compactPartnerFields
                            .id(viewModel.activePartnerIndex) // Force refresh when partner tab changes
                    }
                    .padding(.horizontal, 4)

                    // Error message with retry
                    if let error = viewModel.errorMessage, 
                       !error.hasPrefix("FREE_LIMIT") && !error.hasPrefix("FEATURE_") {
                        VStack(spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AppTheme.Colors.error)
                                    .font(.system(size: 14))
                                
                                Text(error)
                                    .font(AppTheme.Fonts.body(size: 13))
                                    .foregroundColor(AppTheme.Colors.error)
                                    .lineLimit(3)
                                
                                Spacer()
                            }
                            
                            if viewModel.hasFailedPartners {
                                Button(action: {
                                    HapticManager.shared.play(.medium)
                                    Task {
                                        await viewModel.retryFailedPartners()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 13, weight: .semibold))
                                        Text("retry_failed".localized)
                                            .font(AppTheme.Fonts.body(size: 13).weight(.semibold))
                                    }
                                    .foregroundColor(AppTheme.Colors.gold)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(AppTheme.Colors.gold, lineWidth: 1.5)
                                    )
                                }
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.Colors.error.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(AppTheme.Colors.error.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.top, 4)
                        .padding(.horizontal, 8)
                    }
                    
                    // Bottom padding for scrolling
                    Spacer(minLength: 100) 
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            
            // Analyze Button (Fixed at bottom, above tab bar)
            VStack {
                analyzeButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 90) // Clear tab bar completely (tab bar + safe area + margin)
        }
    }
    
    // MARK: - Compact Partner Fields (Grid Layout)
    private var compactPartnerFields: some View {
        VStack(spacing: 16) {
            // Partner Tab Strip (if multi-partner enabled)
            if AppTheme.Features.multiPartnerComparison {
                HStack(spacing: 8) {
                    // Partner pills
                    ForEach(Array(viewModel.partners.enumerated()), id: \.offset) { index, partner in
                        Button(action: { 
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.activePartnerIndex = index 
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text("Partner \(index + 1)")
                                    .font(AppTheme.Fonts.caption(size: 11))
                                if partner.isComplete {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 8, weight: .bold))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(index == viewModel.activePartnerIndex 
                                ? AppTheme.Colors.gold 
                                : Color.clear)
                            .foregroundColor(index == viewModel.activePartnerIndex 
                                ? AppTheme.Colors.textOnGold 
                                : AppTheme.Colors.gold)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.Colors.gold.opacity(index == viewModel.activePartnerIndex ? 0 : 0.5), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Add button (Plus-only, max 3 partners)
                    let maxPartners = 3
                    let isPlus = quotaManager.isPlus
                    let canAddMore = isPlus && viewModel.partners.count < maxPartners
                    
                    Button(action: { 
                        if !isPlus {
                            // Non-Plus: show subscription paywall
                            showSubscription = true
                            return
                        }
                        guard canAddMore else { return }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.addPartner() 
                        }
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: isPlus ? "plus" : "plus")
                                .font(.system(size: 11, weight: .medium))
                                .padding(6)
                                .foregroundColor(isPlus ? (canAddMore ? AppTheme.Colors.gold : AppTheme.Colors.textTertiary) : AppTheme.Colors.textTertiary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3]))
                                        .foregroundColor(isPlus ? (canAddMore ? AppTheme.Colors.gold.opacity(0.4) : AppTheme.Colors.textTertiary.opacity(0.3)) : AppTheme.Colors.gold.opacity(0.3))
                                )
                            
                            // Crown badge for non-Plus users
                            if !isPlus {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 7))
                                    .foregroundColor(AppTheme.Colors.gold)
                                    .offset(x: 3, y: -3)
                            }
                        }
                    }
                    .disabled(isPlus && !canAddMore)  // Only disable at max for Plus users; non-Plus always tappable (opens paywall)
                    .accessibilityLabel(isPlus ? "Add partner" : "Upgrade to Plus to add multiple partners")
                    
                    Spacer()
                    
                    // Delete current partner (if more than 1)
                    if viewModel.partners.count > 1 {
                        Button(action: { 
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.removePartner(at: viewModel.activePartnerIndex) 
                            }
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.Colors.error.opacity(0.7))
                                .padding(6)
                        }
                        .accessibilityLabel("Remove partner")
                    }
                }
                .padding(.bottom, 4)
            }
            
            // Name Field with Search Icon (for saved partners)
            HStack(spacing: 10) {
                // Name Field with trailing search button
                HStack(spacing: 6) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.gold.opacity(0.7))
                    ZStack(alignment: .leading) {
                        if viewModel.girlName.isEmpty {
                            Text("Partner Name")
                                .font(AppTheme.Fonts.body(size: 13))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                        TextField("", text: $viewModel.girlName)
                            .font(AppTheme.Fonts.body(size: 13))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .focused($isNameFocused)
                    }
                    
                    // Search icon to open saved partners
                    Button(action: { 
                        isNameFocused = false
                        showPartnerPicker = true 
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                    .accessibilityLabel("Search saved partners")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 11)
                .background(AppTheme.Colors.inputBackground.opacity(0.6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.Colors.goldDim.opacity(0.3), lineWidth: 1)
                )
                
                // Gender Selection (Compact Button triggering Sheet)
                Button(action: { 
                    HapticManager.shared.play(.light)
                    isNameFocused = false
                    showGenderSheet = true 
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "person")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Colors.gold.opacity(0.7))
                        Text(viewModel.partnerGender.isEmpty ? "Gender" : viewModel.partnerGender.localized)
                            .font(AppTheme.Fonts.body(size: 13))
                            .foregroundColor(viewModel.partnerGender.isEmpty ? AppTheme.Colors.textTertiary : AppTheme.Colors.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 11)
                    .background(AppTheme.Colors.inputBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.Colors.goldDim.opacity(0.5), lineWidth: 1)
                    )
                }
                .frame(width: 140)
                .accessibilityLabel(viewModel.partnerGender.isEmpty ? "Select gender" : "Gender: \(viewModel.partnerGender)")
            }
            
            // Date & Time Row
            HStack(spacing: 10) {
                // Date Button
                Button(action: { 
                    isNameFocused = false
                    showGirlDatePicker = true 
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Colors.gold.opacity(0.7))
                        Text(viewModel.currentPartner.birthDateSet ? viewModel.formattedGirlDob : "Select Date")
                            .font(AppTheme.Fonts.body(size: 13))
                            .foregroundColor(viewModel.currentPartner.birthDateSet ? AppTheme.Colors.textPrimary : AppTheme.Colors.textTertiary)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 11)
                    .background(AppTheme.Colors.inputBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.Colors.goldDim.opacity(0.5), lineWidth: 1)
                    )
                }
                .accessibilityLabel(viewModel.currentPartner.birthDateSet ? "Date of birth: \(viewModel.formattedGirlDob)" : "Select date of birth")
                
                // Time Button
                Button(action: { 
                    if !viewModel.partnerTimeUnknown {
                        isNameFocused = false
                        showGirlTimePicker = true 
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(viewModel.partnerTimeUnknown ? AppTheme.Colors.textTertiary : AppTheme.Colors.gold.opacity(0.7))
                        Text(viewModel.partnerTimeUnknown ? "Unknown" : (viewModel.currentPartner.birthTimeSet ? viewModel.formattedGirlTime : "Select Time"))
                            .font(AppTheme.Fonts.body(size: 13))
                            .foregroundColor((viewModel.partnerTimeUnknown || !viewModel.currentPartner.birthTimeSet) ? AppTheme.Colors.textTertiary : AppTheme.Colors.textPrimary)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 11)
                    .background(AppTheme.Colors.inputBackground.opacity(viewModel.partnerTimeUnknown ? 0.5 : 1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.Colors.goldDim.opacity(0.5), lineWidth: 1)
                    )
                }
                .frame(width: 140)
                .disabled(viewModel.partnerTimeUnknown)
                .accessibilityLabel(viewModel.partnerTimeUnknown ? "Time of birth: unknown" : (viewModel.currentPartner.birthTimeSet ? "Time of birth: \(viewModel.formattedGirlTime)" : "Select time of birth"))
            }
            
            // Place Button (full width) - Moved UP for better vertical flow
            Button(action: { 
                isNameFocused = false
                showGirlLocationSearch = true 
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "location")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.gold.opacity(0.7))
                    Text(viewModel.girlCity.isEmpty ? "select_birth_city".localized : viewModel.girlCity)
                        .font(AppTheme.Fonts.body(size: 13))
                        .foregroundColor(viewModel.girlCity.isEmpty ? AppTheme.Colors.textTertiary : AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 11)
                .background(AppTheme.Colors.inputBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.Colors.goldDim.opacity(0.5), lineWidth: 1)
                )
            }
            .accessibilityLabel(viewModel.girlCity.isEmpty ? "Select birth city" : "Birth city: \(viewModel.girlCity)")
            
            // Time Unknown & Save Row (Moved to Bottom)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 20) {
                    // Time Unknown Toggle
                    Button(action: {
                        HapticManager.shared.play(.light)
                        isNameFocused = false
                        withAnimation { viewModel.partnerTimeUnknown.toggle() }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.partnerTimeUnknown ? "checkmark.square.fill" : "square")
                                .font(.system(size: 14))
                                .foregroundColor(viewModel.partnerTimeUnknown ? AppTheme.Colors.gold : AppTheme.Colors.textTertiary)
                            Text("partner_birth_time_unknown".localized)
                                .font(AppTheme.Fonts.caption(size: 11))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                    .accessibilityLabel("Birth time unknown")
                    .accessibilityAddTraits(viewModel.partnerTimeUnknown ? .isSelected : [])
                    
                    // Save Partner Toggle (hidden for free plan users)
                    if !quotaManager.isFreePlan {
                        Button(action: {
                            HapticManager.shared.play(.light)
                            withAnimation { savePartnerForFuture.toggle() }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: savePartnerForFuture ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 14))
                                    .foregroundColor(savePartnerForFuture ? AppTheme.Colors.gold : AppTheme.Colors.textTertiary)
                                Text("save_birth_chart".localized)
                                    .font(AppTheme.Fonts.caption(size: 11))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        }
                        .accessibilityLabel("Save partner for future")
                        .accessibilityAddTraits(savePartnerForFuture ? .isSelected : [])
                    }
                    
                    Spacer()
                }
                
                if viewModel.partnerTimeUnknown {
                    Text("birth_time_warning".localized)
                        .font(AppTheme.Fonts.caption(size: 11))
                        .foregroundColor(AppTheme.Colors.warning)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Compact Text Field Helper
    private func compactTextField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.gold.opacity(0.7))
            TextField(placeholder, text: text)
                .font(AppTheme.Fonts.body(size: 13))
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 11)
        .background(AppTheme.Colors.inputBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.Colors.goldDim.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Analyze Button
    private var analyzeButton: some View {
        let buttonTitle: String = {
            if viewModel.isAnalyzing {
                return "analyzing".localized
            } else if viewModel.partners.count > 1 {
                return "compare_all".localized + " (\(viewModel.partners.count))"
            } else {
                return "analyze_match".localized
            }
        }()
        
        return ZStack {
            ShimmerButton(
                title: buttonTitle,
                icon: viewModel.isAnalyzing ? nil : "sparkles"
            ) {
                if !viewModel.isAnalyzing {
                    HapticManager.shared.playHeartbeat()
                    analyzeAction()
                }
            }
            .opacity(viewModel.isAnalyzing ? 0.7 : 1)
            .animation(.easeInOut, value: viewModel.isAnalyzing)
            
            if viewModel.isAnalyzing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.textOnGold))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    private func analyzeAction() {
        Task {
            let email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
            let partnerCount = viewModel.partners.count
            
            // Check quota upfront for ALL partners (count-based check)
            // Single partner = count=1, multi-partner = count=N
            // This ensures user sees upgrade prompt before starting if not enough quota
            
            do {
                let accessResponse = try await QuotaManager.shared.canAccessFeature(
                    .compatibility,
                    email: email,
                    count: partnerCount  // Check if N usages are available
                )
                if accessResponse.canAccess {
                    // Save partners if requested (fire and forget)
                    if savePartnerForFuture {
                        viewModel.saveAllPartners(context: modelContext)
                    }
                    
                    // Multi-partner vs Single-partner flow
                    if partnerCount > 1 {
                        await viewModel.analyzeAllPartners()
                    } else {
                        await viewModel.analyzeMatch()
                    }
                    // Quota is recorded server-side per API call (each partner = 1 usage)
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
                                // Guest users should only see Sign In option (no subscribe)
                                quotaErrorMessage = "sign_in_to_continue_matching".localized
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



#Preview {
    CompatibilityView()
}
