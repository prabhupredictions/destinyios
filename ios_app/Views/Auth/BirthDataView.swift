import SwiftUI

/// Premium birth data collection screen
struct BirthDataView: View {
    // MARK: - State
    @State private var viewModel = BirthDataViewModel()
    @AppStorage("hasBirthData") private var hasBirthData = false
    
    // Animation states
    @State private var contentOpacity: Double = 0
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    @State private var showLocationSearch = false
    @State private var showGenderSheet = false
    
    @FocusState private var isNameFocused: Bool
    
    // Profile setup loading - setting this triggers fullScreenCover via item binding
    @State private var savedBirthData: BirthData?
    
    // Sound Manager
    @ObservedObject private var soundManager = SoundManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Layer 1: Premium Cosmic Background (consistent with Splash/Language/Onboarding/Auth)
                CosmicBackgroundView()
                    .ignoresSafeArea()
                
                // Layer 2: Content with overlaid Sound Toggle
                ZStack(alignment: .topTrailing) {
                    // Main Content (Scrollable, with top padding for Sound Toggle)
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppTheme.BirthData.contentSpacing) {
                            // Compact Header
                            headerSection
                                .padding(.top, AppTheme.BirthData.sectionTopPadding)
                            
                            // Form fields (Glass Slabs)
                            formSection
                            
                            // Error message
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(AppTheme.Fonts.caption())
                                    .foregroundColor(AppTheme.Colors.error)
                            }
                            
                            // Submit button with bio-rhythm when valid
                            submitButton
                                .padding(.top, AppTheme.BirthData.inputRowSpacing)
                            
                            Spacer(minLength: 20)
                        }
                        .padding(.horizontal, AppTheme.BirthData.horizontalPadding)
                    }
                    .opacity(contentOpacity)
                    
                    // Sound Toggle - Fixed, Transparent, Floating
                    Button(action: {
                        HapticManager.shared.play(.light)
                        SoundManager.shared.toggleSound()
                    }) {
                        Image(systemName: soundManager.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: AppTheme.BirthData.soundToggleSize, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .contentTransition(.symbolEffect(.replace))
                            .padding(AppTheme.BirthData.soundTogglePadding)
                            .background(AppTheme.BirthData.soundToggleBackground)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, AppTheme.BirthData.soundToggleTrailingPadding)
                    .padding(.top, AppTheme.BirthData.soundToggleTopPadding)
                }
            }
            .onTapGesture {
                isNameFocused = false
            }
            .navigationBarBackButtonHidden(true)
        }
        .onAppear {
            viewModel.loadSaved()
            withAnimation(.easeOut(duration: 0.4)) {
                contentOpacity = 1.0
            }
        }
        .sheet(isPresented: $showDatePicker, onDismiss: {
            // Mark date as selected when user closes the picker
            viewModel.isDateSelected = true
            HapticManager.shared.play(.light)
        }) {
            DatePickerSheet(
                title: "date_of_birth".localized,
                selection: $viewModel.dateOfBirth,
                components: .date
            )
        }
        .sheet(isPresented: $showTimePicker, onDismiss: {
            // Mark time as selected when user closes the picker
            viewModel.isTimeSelected = true
            HapticManager.shared.play(.light)
        }) {
            DatePickerSheet(
                title: "time_of_birth".localized,
                selection: $viewModel.timeOfBirth,
                components: .hourAndMinute
            )
        }
        .sheet(isPresented: $showLocationSearch) {
            LocationSearchView(
                selectedCity: $viewModel.cityOfBirth,
                latitude: $viewModel.latitude,
                longitude: $viewModel.longitude,
                placeId: $viewModel.placeId
            )
        }
        .sheet(isPresented: $showGenderSheet) {
            PremiumSelectionSheet(
                title: "gender_identity".localized,
                selectedValue: $viewModel.gender,
                options: [
                    ("male", "male".localized),
                    ("female", "female".localized),
                    ("non-binary", "non_binary".localized),
                    ("prefer_not_to_say", "prefer_not_to_say".localized)
                ],
                onDismiss: { showGenderSheet = false }
            )
        }
        .fullScreenCover(item: $savedBirthData) { birthData in
            ProfileSetupLoadingView(
                onComplete: {
                    // Set hasBirthData FIRST so AppRootView transitions to MainTabView
                    // BEFORE the cover dismisses (avoids flash of BirthDataView)
                    hasBirthData = true
                    
                    // Small delay to allow transition to start, then dismiss cover
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        savedBirthData = nil
                    }
                },
                birthData: birthData,
                userEmail: UserDefaults.standard.string(forKey: "userEmail") ?? ""
            )
        }
    }
    
    // MARK: - Header (Compact, consistent with Auth screen)
    private var headerSection: some View {
        VStack(spacing: AppTheme.BirthData.headerSpacing) {
            // Compact Icon with Pulsing Glow
            ZStack {
                // Outer glow
                PulsingGlowView(
                    color: AppTheme.Colors.gold.opacity(0.3),
                    size: AppTheme.BirthData.headerGlowSize,
                    blurRadius: AppTheme.BirthData.headerGlowBlur
                )
                
                // Circle container
                Circle()
                    .fill(AppTheme.Colors.inputBackground)
                    .frame(width: AppTheme.BirthData.headerIconSize, height: AppTheme.BirthData.headerIconSize)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.Colors.gold.opacity(0.4), lineWidth: 1)
                    )
                
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(AppTheme.Fonts.display(size: AppTheme.BirthData.headerIconSize * 0.47)) // Proportional
                    .foregroundColor(AppTheme.Colors.gold)
            }
            
            Text("create_birth_chart".localized)
                .font(AppTheme.Fonts.display(size: AppTheme.BirthData.headerTitleSize))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("enter_details_desc".localized)
                .font(AppTheme.Fonts.body(size: AppTheme.BirthData.headerSubtitleSize))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
    }
    
    // MARK: - Form Section (No Card wrapper for compactness)
    private var formSection: some View {
        VStack(spacing: AppTheme.BirthData.formSpacing) {
            // Name (mandatory) - Using reusable PremiumInputField
            PremiumInputField(
                label: "your_name".localized,
                icon: "person.circle",
                placeholder: "enter_your_name".localized,
                text: $viewModel.userName,
                isFocused: $isNameFocused
            )
            
            // Date of Birth
                PremiumSelectionRow(
                    icon: "calendar",
                    title: "date_of_birth".localized,
                    value: viewModel.formattedDate,
                    isPlaceholder: !viewModel.isDateSelected
                ) {
                    isNameFocused = false
                    showDatePicker = true
                }
                
                // Time of Birth
                VStack(spacing: 12) {
                    PremiumSelectionRow(
                        icon: "clock",
                        title: "time_of_birth".localized,
                        value: viewModel.formattedTime,
                        isDisabled: viewModel.timeUnknown,
                        isPlaceholder: !viewModel.isTimeSelected && !viewModel.timeUnknown
                    ) {
                        isNameFocused = false
                        hideKeyboard()
                        if !viewModel.timeUnknown {
                            showTimePicker = true
                        }
                    }
                    
                    // Time unknown toggle
                    HStack {
                        Button(action: {
                            HapticManager.shared.play(.light)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.timeUnknown.toggle()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.timeUnknown ? "checkmark.square.fill" : "square")
                                    .font(AppTheme.Fonts.title(size: 18))
                                    .foregroundColor(viewModel.timeUnknown ? AppTheme.Colors.gold : AppTheme.Colors.textTertiary)
                                
                                Text("i_dont_know_birth_time".localized)
                                    .font(AppTheme.Fonts.body(size: 13))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.leading, 4)
                }
                
                // Place of Birth (with location search)
                PremiumSelectionRow(
                    icon: "location",
                    title: "place_of_birth".localized,
                    value: viewModel.cityOfBirth.isEmpty ? "select_birth_city".localized : viewModel.cityOfBirth,
                    isPlaceholder: viewModel.cityOfBirth.isEmpty
                ) {
                    isNameFocused = false
                    showLocationSearch = true
                }
                
                // Gender Identity (Mandatory)
                // Gender Identity (Mandatory)
                PremiumSelectionRow(
                    icon: "person",
                    title: "gender_identity".localized,
                    value: viewModel.gender.isEmpty ? "select_gender".localized : (
                        // Map value to localized label
                        ["male": "male".localized, 
                         "female": "female".localized, 
                         "non-binary": "non_binary".localized, 
                         "prefer_not_to_say": "prefer_not_to_say".localized][viewModel.gender] ?? viewModel.gender
                    ),
                    isPlaceholder: viewModel.gender.isEmpty
                ) {
                   isNameFocused = false
                   showGenderSheet = true
                }
        }
    }
    
    // MARK: - Submit Button (ShimmerButton - consistent with Onboarding)
    private var submitButton: some View {
        ShimmerButton(title: "continue".localized, icon: "arrow.right") {
            isNameFocused = false
            // Play premium haptic and sound
            HapticManager.shared.premiumContinue()
            SoundManager.shared.playButtonTap()
            
            if viewModel.save() {
                // Register with backend subscription service
                Task {
                    await registerWithBackend()
                }
                
                // Create birth data for prefetch
                savedBirthData = BirthData(
                    dob: viewModel.formattedDOB,
                    time: viewModel.formattedTOB,
                    latitude: viewModel.latitude,
                    longitude: viewModel.longitude,
                    cityOfBirth: viewModel.cityOfBirth
                )
                
                print("[DEBUG] BirthData saved, triggering ProfileSetupLoadingView via item binding")
            }
        }
        .disabled(!viewModel.isValid)
        .opacity(viewModel.isValid ? 1 : 0.5)
        .bioRhythm(bpm: 60, intensity: 1.02, active: viewModel.isValid) // Subtle pulse when valid
    }
    
    // MARK: - Backend Registration
    private func registerWithBackend() async {
        guard let userEmail = UserDefaults.standard.string(forKey: "userEmail"),
              !userEmail.isEmpty else {
            return
        }
        
        let isGuest = UserDefaults.standard.bool(forKey: "isGuest")
        
        do {
            // Register user with subscription service
            // Backend assigns plan based on isGeneratedEmail flag:
            // - isGeneratedEmail=true -> free_guest plan
            // - isGeneratedEmail=false -> free_registered plan
            try await QuotaManager.shared.registerUser(
                email: userEmail,
                isGeneratedEmail: isGuest
            )
            print("✅ Registered user with backend: \(userEmail), isGuest: \(isGuest)")
        } catch {
            print("❌ Failed to register with backend: \(error)")
            // Continue anyway - local data is saved
        }
    }
}

// MARK: - Helper Components

struct PremiumSelectionRow: View {
    let icon: String
    let title: String
    let value: String
    var isDisabled: Bool = false
    var isPlaceholder: Bool = false  // New: use muted color for placeholder text
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundColor(AppTheme.Colors.gold)
                    Text(title)
                        .font(AppTheme.Fonts.caption(size: 13))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                HStack {
                    Text(value)
                        .font(AppTheme.Fonts.body(size: 16))
                        .foregroundColor(isDisabled || isPlaceholder ? AppTheme.Colors.textTertiary : AppTheme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(AppTheme.Fonts.caption(size: 12))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                .padding()
                .background(AppTheme.Colors.inputBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.Styles.inputBorder.stroke, lineWidth: AppTheme.Styles.inputBorder.width)
                )
            }
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1)
    }
}

struct PremiumMenuRow: View {
    let icon: String
    let title: String
    @Binding var selection: String
    var placeholder: String = "Select"
    let options: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(AppTheme.Fonts.body(size: 14))
                    .foregroundColor(AppTheme.Colors.gold)
                Text(title)
                    .font(AppTheme.Fonts.caption(size: 13))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Menu {
                ForEach(options, id: \.0) { value, label in
                    Button(label) {
                        selection = value
                        HapticManager.shared.play(.light)
                    }
                }
            } label: {
                HStack {
                    Text(options.first(where: { $0.0 == selection })?.1 ?? placeholder)
                        .font(AppTheme.Fonts.body(size: 16))
                        .foregroundColor(selection.isEmpty ? AppTheme.Colors.textTertiary : AppTheme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(AppTheme.Fonts.caption(size: 12))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                .padding()
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

// MARK: - Date Picker Sheet
struct DatePickerSheet: View {
    let title: String
    @Binding var selection: Date
    let components: DatePickerComponents
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            CosmicBackgroundView().ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header (Handle + Title + Done)
                ZStack(alignment: .top) {
                    // 1. Handle & Title centered
                    VStack(spacing: 16) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 40, height: 4)
                            .padding(.top, 10)
                        
                        Text(title)
                            .font(AppTheme.Fonts.title(size: 20)) // Soul Typography
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 2. Done Button (Top Right)
                    HStack {
                        Spacer()
                        Button("done".localized) {
                            HapticManager.shared.play(.light)
                            dismiss()
                        }
                        .font(AppTheme.Fonts.body(size: 17).weight(.semibold))
                        .foregroundColor(AppTheme.Colors.gold)
                        .padding(.trailing, 20)
                        .padding(.top, 24) // Align with title basically
                    }
                }
                
                // Custom Gold Picker
                PremiumDatePicker(
                    selection: $selection,
                    mode: components
                )
                .padding(.horizontal)
                
                Spacer()
            }
        }
        #if os(iOS)
        .presentationDetents([.height(350)]) // Fixed height for custom sheet
        #endif
    }
}

#Preview {
    BirthDataView()
}

// MARK: - Keyboard Helper
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
