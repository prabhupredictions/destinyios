import SwiftUI

/// Form mode for add/edit partner
enum PartnerFormMode {
    case add
    case edit(PartnerProfile)
    
    var title: String {
        switch self {
        case .add: return "Add Partner"
        case .edit: return "Edit Partner"
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
    
    let mode: PartnerFormMode
    let onSave: (PartnerProfile) -> Void
    
    // Form fields
    @State private var name: String = ""
    @State private var gender: String = "female"
    @State private var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var timeOfBirth: Date = Date()
    @State private var birthTimeUnknown: Bool = false
    @State private var cityOfBirth: String = ""
    @State private var latitude: Double = 0
    @State private var longitude: Double = 0
    
    // UI state
    @State private var showLocationSearch = false
    @State private var isSaving = false
    
    // Validation
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    init(mode: PartnerFormMode, onSave: @escaping (PartnerProfile) -> Void) {
        self.mode = mode
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppTheme.Colors.mainBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Name field
                        fieldCard(title: "Name", required: true) {
                            TextField("Enter partner name", text: $name)
                                .font(AppTheme.Fonts.body(size: 16))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .autocorrectionDisabled()
                        }
                        
                        // Gender selection
                        fieldCard(title: "Gender", required: true) {
                            HStack(spacing: 12) {
                                genderButton("male", symbol: "♂", label: "Male")
                                genderButton("female", symbol: "♀", label: "Female")
                            }
                        }
                        
                        // Date of Birth
                        fieldCard(title: "Date of Birth", required: true) {
                            DatePicker(
                                "",
                                selection: $dateOfBirth,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(AppTheme.Colors.gold)
                        }
                        
                        // Time of Birth
                        fieldCard(title: "Time of Birth", required: false) {
                            VStack(spacing: 12) {
                                if !birthTimeUnknown {
                                    DatePicker(
                                        "",
                                        selection: $timeOfBirth,
                                        displayedComponents: .hourAndMinute
                                    )
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .tint(AppTheme.Colors.gold)
                                }
                                
                                Toggle(isOn: $birthTimeUnknown) {
                                    Text("Time is unknown")
                                        .font(AppTheme.Fonts.body(size: 14))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                                .tint(AppTheme.Colors.gold)
                            }
                        }
                        
                        // City of Birth
                        fieldCard(title: "City of Birth", required: false) {
                            Button(action: {
                                HapticManager.shared.play(.light)
                                showLocationSearch = true
                            }) {
                                HStack {
                                    Text(cityOfBirth.isEmpty ? "Search city..." : cityOfBirth)
                                        .font(AppTheme.Fonts.body(size: 16))
                                        .foregroundColor(cityOfBirth.isEmpty ? AppTheme.Colors.textSecondary : AppTheme.Colors.textPrimary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "location.magnifyingglass")
                                        .foregroundStyle(AppTheme.Colors.premiumGradient)
                                }
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.shared.play(.light)
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePartner()
                    }
                    .font(.headline)
                    .foregroundColor(isValid ? AppTheme.Colors.gold : Color.gray)
                    .disabled(!isValid || isSaving)
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
            .onAppear {
                loadExistingData()
            }
        }
    }
    
    // MARK: - Field Card
    
    private func fieldCard<Content: View>(title: String, required: Bool, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(AppTheme.Fonts.body(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                if required {
                    Text("*")
                        .foregroundColor(AppTheme.Colors.gold)
                }
            }
            
            content()
                .padding(16)
                .background(AppTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.Styles.goldBorder.stroke, lineWidth: 0.5)
                )
                .cornerRadius(12)
        }
    }
    
    // MARK: - Gender Button
    
    private func genderButton(_ value: String, symbol: String, label: String) -> some View {
        Button(action: {
            HapticManager.shared.play(.light)
            withAnimation(.interpolatingSpring(stiffness: 100, damping: 10)) {
                gender = value
            }
        }) {
            HStack(spacing: 8) {
                Text(symbol)
                    .font(.system(size: 18))
                Text(label)
                    .font(AppTheme.Fonts.body(size: 15))
            }
            .foregroundColor(gender == value ? AppTheme.Colors.mainBackground : AppTheme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                gender == value
                    ? AnyView(AppTheme.Colors.premiumGradient)
                    : AnyView(AppTheme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        gender == value ? Color.clear : AppTheme.Styles.goldBorder.stroke,
                        lineWidth: 0.5
                    )
            )
            .cornerRadius(10)
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
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: partner.dateOfBirth) {
            dateOfBirth = date
        }
        
        // Parse time of birth
        if let timeString = partner.timeOfBirth {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            if let time = timeFormatter.date(from: timeString) {
                timeOfBirth = time
            }
        }
    }
    
    // MARK: - Save Partner
    
    private func savePartner() {
        HapticManager.shared.play(.medium)
        isSaving = true
        
        // Format date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: dateOfBirth)
        
        // Format time
        let timeFormatter = DateFormatter()
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
