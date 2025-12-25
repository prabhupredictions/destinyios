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
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundView
                
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
                                .font(.system(size: 13))
                                .foregroundColor(.red)
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
                title: "Date of Birth",
                selection: $viewModel.dateOfBirth,
                components: .date
            )
        }
        .sheet(isPresented: $showTimePicker) {
            DatePickerSheet(
                title: "Time of Birth",
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
    }
    
    // MARK: - Background
    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.95, blue: 0.98),
                    Color(red: 0.94, green: 0.94, blue: 0.97)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Decorative elements
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color("GoldAccent").opacity(0.08))
                        .frame(width: 300, height: 300)
                        .offset(x: 100, y: 100)
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color("NavyPrimary").opacity(0.08))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 36))
                    .foregroundColor(Color("NavyPrimary"))
            }
            
            Text("Tell us about yourself")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(Color("NavyPrimary"))
            
            Text("Enter your birth details so we can\ncreate your personalized profile")
                .font(.system(size: 15))
                .foregroundColor(Color("TextDark").opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 16) {
            // Date of Birth
            FormFieldButton(
                icon: "calendar",
                title: "Date of Birth",
                value: viewModel.formattedDate
            ) {
                showDatePicker = true
            }
            
            // Time of Birth
            VStack(spacing: 8) {
                FormFieldButton(
                    icon: "clock",
                    title: "Time of Birth",
                    value: viewModel.formattedTime
                ) {
                    if !viewModel.timeUnknown {
                        showTimePicker = true
                    }
                }
                .disabled(viewModel.timeUnknown)
                .opacity(viewModel.timeUnknown ? 0.6 : 1)
                
                // Time unknown toggle
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.timeUnknown.toggle()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: viewModel.timeUnknown ? "checkmark.square.fill" : "square")
                                .font(.system(size: 18))
                                .foregroundColor(viewModel.timeUnknown ? Color("NavyPrimary") : Color("TextDark").opacity(0.4))
                            
                            Text("I don't know my birth time")
                                .font(.system(size: 13))
                                .foregroundColor(Color("TextDark").opacity(0.6))
                        }
                    }
                    Spacer()
                }
                .padding(.leading, 4)
            }
            
            // City of Birth (with location search)
            FormFieldButton(
                icon: "location",
                title: "City of Birth",
                value: viewModel.cityOfBirth.isEmpty ? "Select your birth city" : viewModel.cityOfBirth
            ) {
                showLocationSearch = true
            }
            
            // Gender (optional)
            FormFieldPicker(
                icon: "person",
                title: "Gender (optional)",
                selection: $viewModel.gender,
                options: [
                    ("", "Prefer not to say"),
                    ("male", "Male"),
                    ("female", "Female"),
                    ("other", "Other")
                ]
            )
        }
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: {
            if viewModel.save() {
                // Register with backend subscription service
                Task {
                    await registerWithBackend()
                }
                withAnimation(.easeInOut(duration: 0.3)) {
                    hasBirthData = true
                }
            }
        }) {
            HStack(spacing: 10) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: viewModel.isValid
                        ? [Color("NavyPrimary"), Color("NavyPrimary").opacity(0.9)]
                        : [Color.gray.opacity(0.5), Color.gray.opacity(0.4)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(
                color: viewModel.isValid ? Color("NavyPrimary").opacity(0.3) : Color.clear,
                radius: 10,
                y: 5
            )
        }
        .disabled(!viewModel.isValid)
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

// MARK: - Form Field Components

struct FormFieldButton: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(Color("NavyPrimary"))
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color("TextDark").opacity(0.6))
                }
                
                HStack {
                    Text(value)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("NavyPrimary"))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("TextDark").opacity(0.4))
                }
                .padding()
                .background(Color.white)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color("NavyPrimary").opacity(0.15), lineWidth: 1)
                )
            }
        }
    }
}

struct FormFieldInput: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color("NavyPrimary"))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color("TextDark").opacity(0.6))
            }
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color("NavyPrimary"))
                .padding()
                .background(Color.white)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color("NavyPrimary").opacity(0.15), lineWidth: 1)
                )
        }
    }
}

struct FormFieldPicker: View {
    let icon: String
    let title: String
    @Binding var selection: String
    let options: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color("NavyPrimary"))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color("TextDark").opacity(0.6))
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
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("NavyPrimary"))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("TextDark").opacity(0.4))
                }
                .padding()
                .background(Color.white)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color("NavyPrimary").opacity(0.15), lineWidth: 1)
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
                .labelsHidden()
                .padding()
                
                Spacer()
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color("NavyPrimary"))
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium])
        #endif
    }
}

#Preview {
    BirthDataView()
}
