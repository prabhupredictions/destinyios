import SwiftUI

/// Premium birth data collection screen
struct BirthDataView: View {
    // MARK: - State
    @State private var viewModel = BirthDataViewModel()
    @AppStorage("hasBirthData") private var hasBirthData = false
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    
    // Animation states
    @State private var contentOpacity: Double = 0
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    @State private var showLocationSearch = false
    @State private var showGenderSheet = false
    @State private var showSignInPrompt = false  // For birthDataTaken case
    
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
                    
                    // Top bar: Back button (left) + Sound toggle (right)
                    HStack {
                        // Back button for guests to return to sign-up
                        if UserDefaults.standard.bool(forKey: "isGuest") {
                            Button(action: {
                                HapticManager.shared.play(.light)
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isAuthenticated = false
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Sign up")
                                        .font(AppTheme.Fonts.body(size: 14))
                                }
                                .foregroundColor(AppTheme.Colors.gold)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Capsule())
                            }
                            .padding(.leading, AppTheme.BirthData.soundToggleTrailingPadding)
                            .padding(.top, AppTheme.BirthData.soundToggleTopPadding)
                        }
                        
                        Spacer()
                        
                        // Sound Toggle - Fixed, Transparent, Floating
                        if AppTheme.Features.showSoundToggle {
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
        .sheet(isPresented: $showSignInPrompt) {
            // Guest tried to use birth data that belongs to a registered user
            GuestSignInPromptView(
                message: viewModel.errorMessage ?? "birth_data_registered".localized,
                provider: viewModel.birthDataTakenProvider,
                onBack: { showSignInPrompt = false }
            )
        }
        .onChange(of: viewModel.birthDataTakenEmail) { _, email in
            if email != nil {
                // Cancel the ProfileSetupLoadingView if showing
                savedBirthData = nil
                // Show sign-in prompt
                showSignInPrompt = true
            }
        }
        .onChange(of: showSignInPrompt) { oldValue, newValue in
            // When sign-in sheet closes, reload user info to get the new email
            if oldValue && !newValue {
                print("[BirthDataView] Sign-in sheet closed, reloading user info...")
                viewModel.reloadUserInfo()
            }
        }
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
            
            // Date & Time Row (Compact)
            HStack(spacing: 12) {
                // Date Button
                Button(action: {
                    isNameFocused = false
                    showDatePicker = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.gold.opacity(0.8))
                        Text(viewModel.isDateSelected ? viewModel.formattedDate : "select_date".localized)
                            .font(AppTheme.Fonts.body(size: 14))
                            .foregroundColor(viewModel.isDateSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.textTertiary)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(AppTheme.Colors.inputBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Time Button
                Button(action: {
                    isNameFocused = false
                    hideKeyboard()
                    if !viewModel.timeUnknown {
                        showTimePicker = true
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundColor(viewModel.timeUnknown ? AppTheme.Colors.textTertiary : AppTheme.Colors.gold.opacity(0.8))
                        Text(viewModel.timeUnknown ? "birth_time_unknown".localized : (viewModel.isTimeSelected ? viewModel.formattedTime : "select_time".localized))
                            .font(AppTheme.Fonts.body(size: 14))
                            .foregroundColor((viewModel.timeUnknown || !viewModel.isTimeSelected) ? AppTheme.Colors.textTertiary : AppTheme.Colors.textPrimary)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(AppTheme.Colors.inputBackground.opacity(viewModel.timeUnknown ? 0.5 : 1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(viewModel.timeUnknown)
            }
            
            // Age validation message
            if viewModel.isUnder13 {
                Text("age_requirement".localized)
                    .font(AppTheme.Fonts.caption(size: 13))
                    .foregroundColor(AppTheme.Colors.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 4)
            }
            
            // Time Unknown Toggle
            VStack(alignment: .leading, spacing: 6) {
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
                            .font(AppTheme.Fonts.body(size: 14))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                if viewModel.timeUnknown {
                    Text("birth_time_warning".localized)
                        .font(AppTheme.Fonts.caption(size: 12))
                        .foregroundColor(AppTheme.Colors.warning)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 26) // Align with text
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
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
                // Register with backend subscription service FIRST
                // Wait for result before proceeding to avoid race condition
                Task {
                    let shouldProceed = await registerWithBackend()
                    
                    if shouldProceed {
                        // Only proceed if registration succeeded (no conflict)
                        await MainActor.run {
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
                }
            }
        }
        .disabled(!viewModel.isValid)
        .opacity(viewModel.isValid ? 1 : 0.5)
    }
    
    // MARK: - Backend Registration
    /// Returns true if registration AND profile sync succeeded, false if conflict error occurred
    private func registerWithBackend() async -> Bool {
        guard let userEmail = UserDefaults.standard.string(forKey: "userEmail"),
              !userEmail.isEmpty else {
            return true // Let it proceed if no email (shouldn't happen)
        }
        
        let isGuest = UserDefaults.standard.bool(forKey: "isGuest")
        
        // Step 1: Register user with subscription service
        do {
            // Backend assigns plan based on isGeneratedEmail flag:
            // - isGeneratedEmail=true -> free_guest plan (also checks birth data conflict)
            // - isGeneratedEmail=false -> free_registered plan
            try await QuotaManager.shared.registerUser(
                email: userEmail,
                isGeneratedEmail: isGuest
            )
            print("✅ Registered user with backend: \(userEmail), isGuest: \(isGuest)")
        } catch let error as ArchivedGuestError {
            // Guest already upgraded to registered - show sign-in prompt
            print("🔔 Archived guest detected! Upgraded to: \(error.upgradedToEmail ?? "unknown") (provider: \(error.provider ?? "unknown"))")
            await MainActor.run {
                viewModel.birthDataTakenProvider = error.provider
                viewModel.errorMessage = error.localizedDescription
                showSignInPrompt = true
            }
            return false // Don't proceed - conflict detected
        } catch let error as RegisteredUserConflictError {
            // Guest's birth data matches a registered user - show sign-in prompt
            print("🔔 Guest conflict! Birth data belongs to: \(error.maskedEmail ?? "unknown") (provider: \(error.provider ?? "unknown"))")
            await MainActor.run {
                viewModel.birthDataTakenEmail = error.maskedEmail
                viewModel.birthDataTakenProvider = error.provider
                viewModel.errorMessage = error.localizedDescription
                showSignInPrompt = true
            }
            return false // Don't proceed - conflict detected
        } catch let error as AccountDeletedError {
            // Account was soft-deleted — block all access
            print("🚫 Account deleted: \(error.message)")
            await MainActor.run {
                viewModel.errorMessage = "This account has been permanently deleted and can no longer be used. The email associated with this account cannot be reused. If you believe this is an error, please contact support."
            }
            return false // Don't proceed - account deleted
        } catch {
            print("❌ Failed to register with backend: \(error)")
            // Continue to profile sync anyway
        }
        
        // Step 2: Sync profile with birth data - this checks for birth_data_taken (registered users)
        // For registered users, the /register endpoint won't catch birth data conflicts
        // because they register with Apple/Google email first, then save birth data
        do {
            let syncResult = await syncProfile(userEmail: userEmail, isGuest: isGuest)
            
            if case .conflict(let maskedEmail, let provider) = syncResult {
                // Birth data belongs to another registered user
                print("🔔 Birth data conflict detected during profile sync! (provider: \(provider ?? "unknown"))")
                await MainActor.run {
                    viewModel.birthDataTakenEmail = maskedEmail
                    viewModel.birthDataTakenProvider = provider
                    // Show friendly message based on provider
                    switch provider {
                    case "apple":
                        viewModel.errorMessage = "Your birth data is already linked to your Apple account. Please sign in with Apple."
                    case "google":
                        if let email = maskedEmail {
                            viewModel.errorMessage = "Your birth data is already linked to \(email). Please sign in with Google."
                        } else {
                            viewModel.errorMessage = "Your birth data is already linked to your Google account. Please sign in with Google."
                        }
                    default:
                        viewModel.errorMessage = "Your birth data is already linked to \(maskedEmail ?? "a registered account"). Please sign in with that account."
                    }
                    showSignInPrompt = true
                }
                return false // Don't proceed - conflict detected
            }
        } catch {
            print("❌ Failed to sync profile: \(error)")
            // Continue anyway - local data is saved
        }
        
        return true // Success - proceed to next screen
    }
    
    /// Profile sync result
    private enum ProfileSyncResult {
        case success
        case conflict(maskedEmail: String?, provider: String?)
        case error
    }
    
    /// Sync profile to server and check for birth data conflicts
    private func syncProfile(userEmail: String, isGuest: Bool) async -> ProfileSyncResult {
        let storedUserName = UserDefaults.standard.string(forKey: "userName") ?? ""
        let appleUserId = UserDefaults.standard.string(forKey: "appleUserID")
        let googleUserId = UserDefaults.standard.string(forKey: "googleUserID")
        
        var profileRequest: [String: Any] = [
            "email": userEmail,
            "user_name": storedUserName,
            "user_type": isGuest ? "guest" : "registered",
            "is_generated_email": isGuest,
            "birth_profile": [
                "date_of_birth": viewModel.formattedDOB,
                "time_of_birth": viewModel.formattedTOB,
                "city_of_birth": viewModel.cityOfBirth,
                "latitude": viewModel.latitude,
                "longitude": viewModel.longitude,
                "gender": viewModel.gender.isEmpty ? nil : viewModel.gender,
                "birth_time_unknown": viewModel.timeUnknown
            ] as [String: Any?]
        ]
        
        // Add Apple/Google IDs for proper user lookup (email might be placeholder)
        if let appleId = appleUserId, !appleId.isEmpty {
            profileRequest["apple_id"] = appleId
        }
        if let googleId = googleUserId, !googleId.isEmpty {
            profileRequest["google_id"] = googleId
        }
        
        guard let url = URL(string: "\(APIConfig.baseURL)/subscription/profile") else {
            return .error
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: profileRequest)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[ProfileSync] Server response: \(httpResponse.statusCode)")
                
                // Handle 409 Conflict - birth data already belongs to another registered user
                if httpResponse.statusCode == 409 {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let detail = json["detail"] as? [String: Any] {
                        let existingEmail = detail["existing_email"] as? String
                        let provider = detail["provider"] as? String
                        return .conflict(maskedEmail: existingEmail, provider: provider)
                    }
                    return .conflict(maskedEmail: nil, provider: nil)
                }
                
                if httpResponse.statusCode == 200 {
                    print("✅ Profile synced successfully")
                    return .success
                }
            }
            return .error
        } catch {
            print("❌ Profile sync error: \(error)")
            return .error
        }
    }
}

// MARK: - Helper Components

// Components moved to SharedThemeComponents.swift

// MARK: - Date Picker Sheet
// DatePickerSheet moved to SharedThemeComponents.swift

#Preview {
    BirthDataView()
}

// MARK: - Keyboard Helper
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
