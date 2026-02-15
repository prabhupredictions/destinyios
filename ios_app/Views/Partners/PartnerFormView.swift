import SwiftUI

/// Form mode for add/edit partner
enum PartnerFormMode {
    case add
    case edit(PartnerProfile)
    
    var title: String {
        switch self {
        case .add: return "Add Profile"
        case .edit: return "Edit Profile"
        }
    }
    
    var partner: PartnerProfile? {
        switch self {
        case .add: return nil
        case .edit(let partner): return partner
        }
    }
}

/// Add/Edit Partner Form View
/// Follows Soul of the App theme with cosmic aesthetics
struct PartnerFormView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool
    
    let mode: PartnerFormMode
    let onSave: (PartnerProfile) -> Void
    
    // Form fields
    @State private var name: String = ""
    @State private var gender: String = ""
    @State private var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var timeOfBirth: Date = Date()
    @State private var birthTimeUnknown: Bool = false
    @State private var cityOfBirth: String = ""
    @State private var latitude: Double = 0
    @State private var longitude: Double = 0
    
    // UI state
    @State private var showLocationSearch = false
    @State private var showGenderSheet = false
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    @State private var isSaving = false
    
    // Selection state (for placeholders)
    @State private var isDateSelected = false
    @State private var isTimeSelected = false
    
    // Age check
    private var isUnder13: Bool {
        guard isDateSelected else { return false }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return (ageComponents.year ?? 0) < 13
    }
    
    // Guardian consent state
    @State private var guardianConsentGiven = false
    
    // Validation
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !gender.isEmpty &&
        isDateSelected &&
        (isTimeSelected || birthTimeUnknown) &&
        (!isUnder13 || guardianConsentGiven)
    }
    
    init(mode: PartnerFormMode, onSave: @escaping (PartnerProfile) -> Void) {
        self.mode = mode
        self.onSave = onSave
    }
    
    // Formatted helpers
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dateOfBirth)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timeOfBirth)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                CosmicBackgroundView()
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Name field uses PremiumInputField
                        PremiumInputField(
                            label: "Name",
                            icon: "person.circle",
                            placeholder: "Enter profile name",
                            text: $name,
                            isFocused: $isNameFocused
                        )
                        
                        // Gender
                        PremiumSelectionRow(
                            icon: "person",
                            title: "Gender",
                            value: gender.isEmpty ? "Select Gender" : gender.capitalized,
                            isPlaceholder: gender.isEmpty
                        ) {
                            isNameFocused = false
                            showGenderSheet = true
                        }
                        
                        // Date of Birth
                        PremiumSelectionRow(
                            icon: "calendar",
                            title: "Date of Birth",
                            value: isDateSelected ? formattedDate : "Select Date",
                            isPlaceholder: !isDateSelected
                        ) {
                            isNameFocused = false
                            showDatePicker = true
                        }
                        
                        // Time of Birth Section
                        VStack(spacing: 12) {
                            PremiumSelectionRow(
                                icon: "clock",
                                title: "Time of Birth",
                                value: isTimeSelected ? formattedTime : "Select Time",
                                isDisabled: birthTimeUnknown,
                                isPlaceholder: !isTimeSelected && !birthTimeUnknown
                            ) {
                                isNameFocused = false
                                if !birthTimeUnknown {
                                    showTimePicker = true
                                }
                            }
                            
                            // Time unknown toggle
                            Button(action: {
                                HapticManager.shared.play(.light)
                                withAnimation { birthTimeUnknown.toggle() }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: birthTimeUnknown ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 18))
                                        .foregroundColor(birthTimeUnknown ? AppTheme.Colors.gold : AppTheme.Colors.textTertiary)
                                    
                                    Text("partner_birth_time_unknown".localized)
                                        .font(AppTheme.Fonts.body(size: 14))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                    
                                    Spacer()
                                }
                                .padding(.leading, 4)
                            }
                            
                            if birthTimeUnknown {
                                Text("birth_time_warning".localized)
                                    .font(AppTheme.Fonts.caption(size: 11))
                                    .foregroundColor(AppTheme.Colors.warning)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 4)
                            }
                        }
                        
                        // Guardian consent for under-13
                        if isUnder13 {
                            VStack(alignment: .leading, spacing: 8) {
                                Button(action: {
                                    HapticManager.shared.play(.light)
                                    withAnimation { guardianConsentGiven.toggle() }
                                }) {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: guardianConsentGiven ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 18))
                                            .foregroundColor(guardianConsentGiven ? AppTheme.Colors.gold : AppTheme.Colors.textTertiary)
                                            .padding(.top, 2)
                                        
                                        Text("By adding this birth chart, you confirm that you are the parent or legal guardian and have the authority to provide this information")
                                            .font(AppTheme.Fonts.caption(size: 13))
                                            .foregroundColor(AppTheme.Colors.textSecondary)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // City of Birth
                        PremiumSelectionRow(
                            icon: "location",
                            title: "Place of Birth",
                            value: cityOfBirth.isEmpty ? "Select City" : cityOfBirth,
                            isPlaceholder: cityOfBirth.isEmpty
                        ) {
                            isNameFocused = false
                            showLocationSearch = true
                        }
                        
                        Spacer(minLength: 20)
                        
                        // Save Button
                        ShimmerButton(title: "Save Profile", icon: "checkmark") {
                            savePartner()
                        }
                        .disabled(!isValid || isSaving)
                        .opacity(isValid ? 1 : 0.6)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.shared.play(.light)
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .sheet(isPresented: $showLocationSearch) {
                LocationSearchView(
                    selectedCity: $cityOfBirth,
                    latitude: $latitude,
                    longitude: $longitude,
                    placeId: .constant(nil)
                )
            }
            .sheet(isPresented: $showDatePicker, onDismiss: {
                isDateSelected = true
                HapticManager.shared.play(.light)
            }) {
                DatePickerSheet(
                    title: "Date of Birth",
                    selection: $dateOfBirth,
                    components: .date
                )
            }
            .sheet(isPresented: $showTimePicker, onDismiss: {
                isTimeSelected = true
                HapticManager.shared.play(.light)
            }) {
                DatePickerSheet(
                    title: "Time of Birth",
                    selection: $timeOfBirth,
                    components: .hourAndMinute
                )
            }
            .sheet(isPresented: $showGenderSheet) {
                PremiumSelectionSheet(
                    title: "Select Gender",
                    selectedValue: $gender,
                    options: [
                        ("male", "Male"),
                        ("female", "Female"),
                        ("non-binary", "Non-binary"),
                        ("prefer_not_to_say", "Prefer not to say")
                    ],
                    onDismiss: { showGenderSheet = false }
                )
            }
            .onAppear {
                loadExistingData()
            }
        }
    }
    
    // MARK: - Load Existing Data
    
    private func loadExistingData() {
        guard let partner = mode.partner else { return }
        
        name = partner.name
        gender = partner.gender
        birthTimeUnknown = partner.birthTimeUnknown
        cityOfBirth = partner.cityOfBirth ?? ""
        latitude = partner.latitude ?? 0
        longitude = partner.longitude ?? 0
        
        // Parse date of birth
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: partner.dateOfBirth) {
            dateOfBirth = date
            isDateSelected = true
        }
        
        // Parse time of birth
        if let timeString = partner.timeOfBirth {
            let timeFormatter = DateFormatter()
            timeFormatter.locale = Locale(identifier: "en_US_POSIX")
            timeFormatter.dateFormat = "HH:mm"
            if let time = timeFormatter.date(from: timeString) {
                timeOfBirth = time
                isTimeSelected = true
            }
        }
    }
    
    // MARK: - Save Partner
    
    private func savePartner() {
        HapticManager.shared.play(.medium)
        isSaving = true
        
        // Format date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: dateOfBirth)
        
        // Format time
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "HH:mm"
        let timeString = birthTimeUnknown ? nil : timeFormatter.string(from: timeOfBirth)
        
        let partner = PartnerProfile(
            id: mode.partner?.id ?? UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespaces),
            gender: gender,
            dateOfBirth: dateString,
            timeOfBirth: timeString,
            cityOfBirth: cityOfBirth.isEmpty ? nil : cityOfBirth,
            latitude: latitude == 0 ? nil : latitude,
            longitude: longitude == 0 ? nil : longitude,
            timezone: nil,
            birthTimeUnknown: birthTimeUnknown,
            consentGiven: true
        )
        
        onSave(partner)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    PartnerFormView(mode: .add) { _ in }
}
