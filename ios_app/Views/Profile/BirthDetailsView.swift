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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    headerSection
                    
                    // Editable Section
                    editableSection
                    
                    // Read-only Section
                    readOnlySection
                    
                    // Support Contact Info
                    supportInfoSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .background(Color(red: 0.96, green: 0.95, blue: 0.98))
            .navigationTitle("birth_details".localized)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) { dismiss() }
                        .foregroundColor(Color("NavyPrimary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save".localized) { saveChanges() }
                        .foregroundColor(Color("NavyPrimary"))
                        .fontWeight(.semibold)
                        .disabled(!hasChanges)
                }
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
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color("NavyPrimary").opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color("NavyPrimary"))
            }
            
            Text("your_birth_info".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("NavyPrimary"))
        }
    }
    
    // MARK: - Editable Section
    private var editableSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("editable".localized.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color("TextDark").opacity(0.4))
            
            VStack(spacing: 10) {
                // Name Field
                VStack(alignment: .leading, spacing: 4) {
                    Text("your_name".localized)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color("TextDark").opacity(0.6))
                    
                    TextField("enter_your_name".localized, text: $userName)
                        .font(.system(size: 15))
                        .foregroundColor(Color("TextDark"))
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color("NavyPrimary").opacity(0.15), lineWidth: 1)
                        )
                        .onChange(of: userName) { _, _ in hasChanges = true }
                }
                
                // Gender Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("gender".localized)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color("TextDark").opacity(0.6))
                    
                    Menu {
                        Button("prefer_not_to_say".localized) { gender = ""; hasChanges = true }
                        Button("male".localized) { gender = "male"; hasChanges = true }
                        Button("female".localized) { gender = "female"; hasChanges = true }
                        Button("non_binary".localized) { gender = "non-binary"; hasChanges = true }
                    } label: {
                        HStack {
                            Text(genderDisplayText)
                                .font(.system(size: 15))
                                .foregroundColor(Color("TextDark"))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11))
                                .foregroundColor(Color("NavyPrimary").opacity(0.5))
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color("NavyPrimary").opacity(0.15), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
            )
        }
    }
    
    // MARK: - Read-only Section
    private var readOnlySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("birth_data".localized.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color("TextDark").opacity(0.4))
            
            VStack(spacing: 0) {
                readOnlyRow(label: "date_of_birth".localized, value: dateOfBirth, icon: "calendar")
                Divider().padding(.leading, 40)
                readOnlyRow(label: "time_of_birth".localized, value: timeOfBirth, icon: "clock")
                Divider().padding(.leading, 40)
                readOnlyRow(label: "place_of_birth".localized, value: placeOfBirth, icon: "location.fill")
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.95, green: 0.95, blue: 0.96))
            )
        }
    }
    
    private func readOnlyRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color("NavyPrimary").opacity(0.5))
                .frame(width: 22)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(Color("TextDark").opacity(0.5))
                Text(value.isEmpty ? "not_set".localized : value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("TextDark"))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.system(size: 10))
                .foregroundColor(Color("TextDark").opacity(0.3))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    // MARK: - Support Info Section
    private var supportInfoSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color("NavyPrimary"))
                
                Text("need_update_birth_data".localized)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color("NavyPrimary"))
            }
            
            Text("contact_support_birth_data".localized)
                .font(.system(size: 12))
                .foregroundColor(Color("TextDark").opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
            
            Button(action: { openEmail() }) {
                HStack(spacing: 6) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 12))
                    Text("support@destinyaiastrology.com")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color("NavyPrimary"))
                .cornerRadius(8)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("NavyPrimary").opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("NavyPrimary").opacity(0.1), lineWidth: 1)
                )
        )
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
        // Load name
        userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        
        // Load gender
        gender = UserDefaults.standard.string(forKey: "userGender") ?? ""
        
        // Load birth data
        if let data = UserDefaults.standard.data(forKey: "userBirthData") {
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
                if UserDefaults.standard.bool(forKey: "birthTimeUnknown") {
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
        
        // Save gender
        UserDefaults.standard.set(gender, forKey: "userGender")
        
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
