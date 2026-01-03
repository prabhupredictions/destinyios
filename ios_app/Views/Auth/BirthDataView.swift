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
    
    // Profile setup loading - setting this triggers fullScreenCover via item binding
    @State private var savedBirthData: BirthData?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.Colors.mainBackground.ignoresSafeArea()
                
                // Cosmic background effect
                GeometryReader { geo in
                    Circle()
                        .fill(AppTheme.Colors.premiumGradient.opacity(0.1))
                        .frame(width: 500, height: 500)
                        .blur(radius: 100)
                        .offset(x: geo.size.width - 150, y: -200)
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                            .padding(.top, 20)
                        
                        // Form fields
                        formSection
                        
                        // Error message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(AppTheme.Fonts.caption())
                                .foregroundColor(AppTheme.Colors.error)
                        }
                        
                        // Submit button
                        submitButton
                            .padding(.top, 16)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
                .opacity(contentOpacity)
            }
            .navigationBarBackButtonHidden(true)
        }
        .onAppear {
            viewModel.loadSaved()
            withAnimation(.easeOut(duration: 0.4)) {
                contentOpacity = 1.0
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                title: "date_of_birth".localized,
                selection: $viewModel.dateOfBirth,
                components: .date
            )
        }
        .sheet(isPresented: $showTimePicker) {
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
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.inputBackground)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 36))
                    .foregroundColor(AppTheme.Colors.gold)
            }
            .shadow(color: AppTheme.Colors.gold.opacity(0.2), radius: 15, x: 0, y: 0)
            
            Text("create_birth_chart".localized)
                .font(AppTheme.Fonts.display(size: 26))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("enter_details_desc".localized)
                .font(AppTheme.Fonts.body(size: 15))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        PremiumCard {
            VStack(spacing: 20) {
                // Name (mandatory)
                PremiumTextField(
                    "your_name".localized,
                    text: $viewModel.userName,
                    placeholder: "enter_your_name".localized,
                    icon: "person.circle"
                )
                
                // Date of Birth
                PremiumSelectionRow(
                    icon: "calendar",
                    title: "date_of_birth".localized,
                    value: viewModel.formattedDate
                ) {
                    showDatePicker = true
                }
                
                // Time of Birth
                VStack(spacing: 12) {
                    PremiumSelectionRow(
                        icon: "clock",
                        title: "time_of_birth".localized,
                        value: viewModel.formattedTime,
                        isDisabled: viewModel.timeUnknown
                    ) {
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
                                    .font(.system(size: 18))
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
                    value: viewModel.cityOfBirth.isEmpty ? "select_birth_city".localized : viewModel.cityOfBirth
                ) {
                    showLocationSearch = true
                }
                
                // Gender Identity
                PremiumMenuRow(
                    icon: "person",
                    title: "gender_identity".localized,
                    selection: $viewModel.gender,
                    options: [
                        ("", "prefer_not_to_say".localized),
                        ("male", "male".localized),
                        ("female", "female".localized),
                        ("non-binary", "non_binary".localized)
                    ]
                )
            }
        }
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        PremiumButton(
            "continue".localized,
            icon: "arrow.right"
        ) {
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
                
                // DEBUG: Setting savedBirthData triggers fullScreenCover automatically
                print("[DEBUG] BirthData saved, triggering ProfileSetupLoadingView via item binding")
            }
        }
        .disabled(!viewModel.isValid)
        .opacity(viewModel.isValid ? 1 : 0.6)
    }
    
    // MARK: - Backend Registration
    private func registerWithBackend() async {
        guard let userEmail = UserDefaults.standard.string(forKey: "userEmail"),
              !userEmail.isEmpty else {
            return
        }
        
        let isGuest = UserDefaults.standard.bool(forKey: "isGuest")
        
        do {
            // Register user with subscription service (creates if doesn't exist)
            try await QuotaManager.shared.registerWithServer(
                email: userEmail,
                userType: isGuest ? .guest : .registered,
                isGeneratedEmail: isGuest
            )
            print("Registered user with backend: \(userEmail), isGuest: \(isGuest)")
        } catch {
            print("Failed to register with backend: \(error)")
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
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.gold)
                    Text(title)
                        .font(AppTheme.Fonts.caption(size: 13))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                HStack {
                    Text(value)
                        .font(AppTheme.Fonts.body(size: 16))
                        .foregroundColor(isDisabled ? AppTheme.Colors.textTertiary : AppTheme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
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
    let options: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.gold)
                Text(title)
                    .font(AppTheme.Fonts.caption(size: 13))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Menu {
                ForEach(options, id: \.0) { value, label in
                    Button(label) {
                        selection = value
                    }
                }
            } label: {
                HStack {
                    Text(options.first(where: { $0.0 == selection })?.1 ?? "Select")
                        .font(AppTheme.Fonts.body(size: 16))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
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
        NavigationStack {
            ZStack {
                AppTheme.Colors.mainBackground.ignoresSafeArea()
                
                VStack {
                    DatePicker(
                        title,
                        selection: $selection,
                        displayedComponents: components
                    )
                    #if os(iOS)
                    .datePickerStyle(.wheel)
                    #else
                    .datePickerStyle(.graphical)
                    #endif
                    .colorScheme(.dark)
                    .labelsHidden()
                    // Use English locale for time picker to show AM/PM
                    .environment(\.locale, components == .hourAndMinute ? Locale(identifier: "en_US") : .current)
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("done".localized) {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.gold)
                }
            }
            .toolbarBackground(AppTheme.Colors.mainBackground, for: .navigationBar)
        }
        #if os(iOS)
        .presentationDetents([.medium])
        #endif
    }
}

#Preview {
    BirthDataView()
}
