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
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Editable Section
                    editableSection
                    
                    // Read-only Section
                    readOnlySection
                    
                    // Support Contact Info
                    supportInfoSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(red: 0.96, green: 0.95, blue: 0.98))
            .navigationTitle("Birth Details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color("NavyPrimary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .foregroundColor(Color("NavyPrimary"))
                        .fontWeight(.semibold)
                        .disabled(!hasChanges)
                }
            }
        }
        .onAppear { loadData() }
        .alert("Changes Saved", isPresented: $showSaveConfirmation) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your name and gender have been updated.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color("NavyPrimary").opacity(0.1))
                    .frame(width: 70, height: 70)
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color("NavyPrimary"))
            }
            
            Text("Your Birth Information")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color("NavyPrimary"))
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Editable Section
    private var editableSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EDITABLE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color("TextDark").opacity(0.4))
            
            VStack(spacing: 12) {
                // Name Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("TextDark").opacity(0.6))
                    
                    TextField("Enter your name", text: $userName)
                        .font(.system(size: 16))
                        .foregroundColor(Color("TextDark"))
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("NavyPrimary").opacity(0.15), lineWidth: 1)
                        )
                        .onChange(of: userName) { _, _ in hasChanges = true }
                }
                
                // Gender Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Gender")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("TextDark").opacity(0.6))
                    
                    Menu {
                        Button("Not specified") { gender = ""; hasChanges = true }
                        Button("Male") { gender = "male"; hasChanges = true }
                        Button("Female") { gender = "female"; hasChanges = true }
                        Button("Non-binary") { gender = "non-binary"; hasChanges = true }
                    } label: {
                        HStack {
                            Text(genderDisplayText)
                                .font(.system(size: 16))
                                .foregroundColor(Color("TextDark"))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(Color("NavyPrimary").opacity(0.5))
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("NavyPrimary").opacity(0.15), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
            )
        }
    }
    
    // MARK: - Read-only Section
    private var readOnlySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("BIRTH DATA")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color("TextDark").opacity(0.4))
            
            VStack(spacing: 0) {
                readOnlyRow(label: "Date of Birth", value: dateOfBirth, icon: "calendar")
                Divider().padding(.leading, 44)
                readOnlyRow(label: "Time of Birth", value: timeOfBirth, icon: "clock")
                Divider().padding(.leading, 44)
                readOnlyRow(label: "Place of Birth", value: placeOfBirth, icon: "location.fill")
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.95, green: 0.95, blue: 0.96))
            )
        }
    }
    
    private func readOnlyRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color("NavyPrimary").opacity(0.5))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(Color("TextDark").opacity(0.5))
                Text(value.isEmpty ? "Not set" : value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color("TextDark"))
            }
            
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.system(size: 12))
                .foregroundColor(Color("TextDark").opacity(0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    // MARK: - Support Info Section
    private var supportInfoSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color("NavyPrimary"))
                
                Text("Need to update birth data?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("NavyPrimary"))
            }
            
            Text("For changes to your date, time, or place of birth, please contact our support team. This ensures accuracy in your astrological readings.")
                .font(.system(size: 13))
                .foregroundColor(Color("TextDark").opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Button(action: { openEmail() }) {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 14))
                    Text("support@destinyaiastrology.com")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color("NavyPrimary"))
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("NavyPrimary").opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("NavyPrimary").opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helpers
    private var genderDisplayText: String {
        switch gender {
        case "male": return "Male"
        case "female": return "Female"
        case "non-binary": return "Non-binary"
        default: return "Not specified"
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
                
                // Format date
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if let date = dateFormatter.date(from: birthData.dob) {
                    dateFormatter.dateStyle = .long
                    dateOfBirth = dateFormatter.string(from: date)
                } else {
                    dateOfBirth = birthData.dob
                }
                
                // Format time
                if UserDefaults.standard.bool(forKey: "birthTimeUnknown") {
                    timeOfBirth = "Unknown"
                } else {
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm"
                    if let time = timeFormatter.date(from: birthData.time) {
                        timeFormatter.timeStyle = .short
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
