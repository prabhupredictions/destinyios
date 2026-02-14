import SwiftUI

/// View for displaying and editing birth details
/// Name and Gender are editable, other fields require support contact
struct BirthDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Editable fields
    @State private var userName: String = ""
    @State private var gender: String = ""
    
    // Read-only fields (loaded from storage)
    @State private var dateOfBirth: String = ""
    @State private var timeOfBirth: String = ""
    @State private var placeOfBirth: String = ""
    
    // State
    @State private var showSaveConfirmation = false
    @State private var hasChanges = false
    @State private var showGenderSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Header
                    headerSection
                        .padding(.top, 4)
                        .padding(.bottom, 0)
                    
                    // Editable Section
                    editableSection
                    
                    // Read-only Section
                    readOnlySection
                    
                    Spacer(minLength: 0)
                    
                    // Support Contact Info
                    supportInfoSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
            .background(
                CosmicBackgroundView()
                    .ignoresSafeArea()
            )
            .navigationTitle("birth_details".localized)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) { dismiss() }
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save".localized) { saveChanges() }
                        .font(AppTheme.Fonts.body(size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(hasChanges ? AppTheme.Colors.gold : AppTheme.Colors.textTertiary)
                        .disabled(!hasChanges)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showGenderSheet) {
                PremiumSelectionSheet(
                    title: "select_gender".localized,
                    selectedValue:Binding(
                        get: { gender },
                        set: { if $0 != gender { gender = $0; hasChanges = true } }
                    ),
                    options: [
                        ("", "prefer_not_to_say".localized),
                        ("male", "male".localized),
                        ("female", "female".localized),
                        ("non-binary", "non_binary".localized)
                    ],
                    onDismiss: { showGenderSheet = false }
                )
                .presentationDetents([.height(320)])
            }
        }
        .onAppear { loadData() }
        .alert("changes_saved".localized, isPresented: $showSaveConfirmation) {
            Button("ok".localized) { dismiss() }
        } message: {
            Text("name_gender_updated".localized)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.gold.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.crop.circle.fill")
                    .font(AppTheme.Fonts.display(size: 24))
                    .foregroundColor(AppTheme.Colors.gold)
            }
            
            Text("your_birth_info".localized)
                .font(AppTheme.Fonts.title(size: 14))
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
    
    // MARK: - Editable Section
    private var editableSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("editable".localized.uppercased())
                .font(AppTheme.Fonts.caption(size: 10))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .padding(.leading, 4)
            
            PremiumCard {
                VStack(spacing: 10) {
                    // Name Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("your_name".localized)
                            .font(AppTheme.Fonts.body(size: 11))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        TextField("enter_your_name".localized, text: $userName)
                            .font(AppTheme.Fonts.body(size: 14))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .padding(.horizontal, 12)
                            .frame(height: 40)
                            .background(AppTheme.Colors.inputBackground)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.Colors.gold.opacity(0.15), lineWidth: 1)
                            )
                            .onChange(of: userName) { _, _ in hasChanges = true }
                    }
                    
                    Divider().overlay(AppTheme.Colors.separator)
                    
                    // Gender Picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("gender".localized)
                            .font(AppTheme.Fonts.body(size: 11))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Button(action: { showGenderSheet = true }) {
                            HStack {
                                Text(genderDisplayText)
                                    .font(AppTheme.Fonts.body(size: 14))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(AppTheme.Fonts.caption(size: 10))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 40)
                            .background(AppTheme.Colors.inputBackground)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.Colors.gold.opacity(0.15), lineWidth: 1)
                            )
                        }
                        .accessibilityLabel("Gender: \(genderDisplayText)")
                    }
                }
            }
        }
    }
    
    // MARK: - Read-only Section
    private var readOnlySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("birth_data".localized.uppercased())
                .font(AppTheme.Fonts.caption(size: 10))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .padding(.leading, 4)
            
            PremiumCard {
                VStack(spacing: 0) {
                    readOnlyRow(label: "date_of_birth".localized, value: dateOfBirth, icon: "calendar")
                    Divider().overlay(AppTheme.Colors.separator).padding(.leading, 40)
                    readOnlyRow(label: "time_of_birth".localized, value: timeOfBirth, icon: "clock")
                    Divider().overlay(AppTheme.Colors.separator).padding(.leading, 40)
                    readOnlyRow(label: "place_of_birth".localized, value: placeOfBirth, icon: "location.fill")
                }
            }
        }
    }
    
    private func readOnlyRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(AppTheme.Fonts.body(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(width: 22)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(AppTheme.Fonts.caption(size: 11))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                Text(value.isEmpty ? "not_set".localized : value)
                    .font(AppTheme.Fonts.body(size: 14))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(AppTheme.Fonts.caption(size: 10))
                .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    // MARK: - Support Info Section
    private var supportInfoSection: some View {
        PremiumCard {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text("need_update_birth_data".localized)
                        .font(AppTheme.Fonts.title(size: 14))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                Text("contact_support_birth_data".localized)
                    .font(AppTheme.Fonts.caption(size: 12))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
                
                Button(action: { openEmail() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                            .font(AppTheme.Fonts.body(size: 14))
                        Text("support@destinyaiastrology.com")
                            .font(AppTheme.Fonts.body(size: 14).weight(.medium))
                    }
                    .foregroundColor(AppTheme.Colors.mainBackground)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(AppTheme.Colors.gold)
                    .cornerRadius(12)
                    .shadow(color: AppTheme.Colors.gold.opacity(0.3), radius: 4, y: 2)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Helpers
    private var genderDisplayText: String {
        switch gender {
        case "male": return "male".localized
        case "female": return "female".localized
        case "non-binary": return "non_binary".localized
        default: return "prefer_not_to_say".localized
        }
    }
    
    private func loadData() {
        // Load name (remains global for current user session)
        userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        
        // Load gender (User-Scoped)
        let genderKey = StorageKeys.userKey(for: StorageKeys.userGender)
        gender = UserDefaults.standard.string(forKey: genderKey) ?? ""
        
        // Load birth data (User-Scoped)
        let dataKey = StorageKeys.userKey(for: StorageKeys.userBirthData)
        if let data = UserDefaults.standard.data(forKey: dataKey) {
            do {
                let birthData = try JSONDecoder().decode(BirthData.self, from: data)
                
                // Format date - use dd/MM/yyyy format with 4-digit year
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if let date = dateFormatter.date(from: birthData.dob) {
                    dateFormatter.dateFormat = "dd/MM/yyyy"
                    dateOfBirth = dateFormatter.string(from: date)
                } else {
                    dateOfBirth = birthData.dob
                }
                
                // Format time - always use English AM/PM format
                let timeUnknownKey = StorageKeys.userKey(for: StorageKeys.birthTimeUnknown)
                if UserDefaults.standard.bool(forKey: timeUnknownKey) {
                    timeOfBirth = "birth_time_unknown".localized
                } else {
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm"
                    if let time = timeFormatter.date(from: birthData.time) {
                        timeFormatter.locale = Locale(identifier: "en_US")
                        timeFormatter.dateFormat = "h:mm a"
                        timeOfBirth = timeFormatter.string(from: time)
                    } else {
                        timeOfBirth = birthData.time
                    }
                }
                
                // Place
                placeOfBirth = birthData.cityOfBirth ?? ""
            } catch {
                print("Failed to load birth data: \(error)")
            }
        }
        
        hasChanges = false
    }
    
    private func saveChanges() {
        // Save name
        UserDefaults.standard.set(userName, forKey: "userName")
        
        // Save gender (User-Scoped)
        let genderKey = StorageKeys.userKey(for: StorageKeys.userGender)
        UserDefaults.standard.set(gender, forKey: genderKey)
        
        showSaveConfirmation = true
    }
    
    private func openEmail() {
        let email = "support@destinyaiastrology.com"
        let subject = "Birth Data Update Request"
        let body = "Hello,\n\nI would like to request an update to my birth data.\n\nCurrent details:\n- Date of Birth: \(dateOfBirth)\n- Time of Birth: \(timeOfBirth)\n- Place of Birth: \(placeOfBirth)\n\nRequested changes:\n[Please specify the changes you need]\n\nThank you."
        
        if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }
}

#Preview {
    BirthDetailsView()
}
