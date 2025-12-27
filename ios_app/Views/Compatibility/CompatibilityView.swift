import SwiftUI

/// Compatibility/Match analysis screen
struct CompatibilityView: View {
    @State private var viewModel = CompatibilityViewModel()
    @State private var selectedTab = 0 // 0 = Boy, 1 = Girl
    @State private var showBoyLocationSearch = false
    @State private var showGirlLocationSearch = false
    
    var body: some View {
        ZStack {
            // Animated orbital background with rotating planets
            MinimalOrbitalBackground()
            
            if viewModel.showResult, let result = viewModel.result {
                CompatibilityResultView(
                    result: result,
                    boyName: viewModel.boyName,
                    girlName: viewModel.girlName
                ) {
                    viewModel.reset()
                }
            } else {
                compatibilityForm
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
    }
    
    // MARK: - Form View
    private var compatibilityForm: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Text("💕")
                            .font(.system(size: 24))
                        Text("kundali_match".localized)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color("NavyPrimary"))
                    }
                    
                    Text("ashtakoot_analysis".localized)
                        .font(.system(size: 14))
                        .foregroundColor(Color("TextDark").opacity(0.6))
                }
                .padding(.top, 20)
                
                // Tab Selector
                tabSelector
                    .padding(.horizontal, 20)
                
                // Form based on selected tab
                if selectedTab == 0 {
                    boyFormCard
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                } else {
                    girlFormCard
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                
                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }
                
                // Analyze button
                analyzeButton
                
                // Spacer for tab bar
                Spacer(minLength: 120)
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            // Boy's Details Tab
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedTab = 0
                }
            }) {
                Text("boys_details".localized)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(selectedTab == 0 ? .white : Color("NavyPrimary"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        selectedTab == 0 
                            ? AnyView(
                                LinearGradient(
                                    colors: [Color("NavyPrimary"), Color("NavyPrimary").opacity(0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : AnyView(Color.clear)
                    )
                    .cornerRadius(12)
            }
            
            // Girl's Details Tab
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedTab = 1
                }
            }) {
                Text("girls_details".localized)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(selectedTab == 1 ? .white : Color("NavyPrimary"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        selectedTab == 1 
                            ? AnyView(
                                LinearGradient(
                                    colors: [Color("NavyPrimary"), Color("NavyPrimary").opacity(0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : AnyView(Color.clear)
                    )
                    .cornerRadius(12)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("NavyPrimary").opacity(0.3), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                )
        )
    }
    
    // MARK: - Boy Form Card (You - from profile)
    private var boyFormCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Profile indicator if data loaded
            if viewModel.userDataLoaded {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("From your profile")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("TextDark").opacity(0.6))
                    Spacer()
                }
                .padding(.bottom, 4)
            }
            
            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("boys_name".localized)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color("TextDark").opacity(0.5))
                
                if viewModel.userDataLoaded {
                    // Read-only display
                    HStack(spacing: 10) {
                        Image(systemName: "person")
                            .font(.system(size: 14))
                            .foregroundColor(Color("NavyPrimary").opacity(0.5))
                        Text(viewModel.boyName.isEmpty ? "Not set" : viewModel.boyName)
                            .font(.system(size: 15))
                            .foregroundColor(Color("TextDark"))
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.95, green: 0.95, blue: 0.96))
                    )
                } else {
                    MatchTextField(
                        placeholder: "Enter name",
                        text: $viewModel.boyName,
                        icon: "person"
                    )
                }
            }
            
            // Date and Time row
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("date_of_birth_caps".localized)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color("TextDark").opacity(0.5))
                    
                    if viewModel.userDataLoaded {
                        // Read-only date display
                        HStack {
                            Text(formattedBoyDate)
                                .font(.system(size: 15))
                                .foregroundColor(Color("TextDark"))
                            Spacer()
                            Image(systemName: "calendar")
                                .foregroundColor(Color("NavyPrimary").opacity(0.4))
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.95, green: 0.95, blue: 0.96))
                        )
                    } else {
                        MatchDateButton(date: $viewModel.boyBirthDate)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("time_caps".localized)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color("TextDark").opacity(0.5))
                    
                    if viewModel.userDataLoaded {
                        // Read-only time display
                        HStack {
                            Text(viewModel.boyTimeUnknown ? "Unknown" : formattedBoyTime)
                                .font(.system(size: 15))
                                .foregroundColor(Color("TextDark"))
                            Spacer()
                            Image(systemName: "clock")
                                .foregroundColor(Color("NavyPrimary").opacity(0.4))
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.95, green: 0.95, blue: 0.96))
                        )
                    } else {
                        MatchTimeButton(time: $viewModel.boyBirthTime)
                    }
                }
            }
            
            // Place of Birth
            VStack(alignment: .leading, spacing: 8) {
                Text("place_of_birth_caps".localized)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color("TextDark").opacity(0.5))
                
                if viewModel.userDataLoaded {
                    // Read-only city display
                    HStack(spacing: 10) {
                        Image(systemName: "mappin")
                            .font(.system(size: 14))
                            .foregroundColor(Color("NavyPrimary").opacity(0.5))
                        
                        Text(viewModel.boyCity.isEmpty ? "Not set" : viewModel.boyCity)
                            .font(.system(size: 15))
                            .foregroundColor(Color("TextDark"))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.95, green: 0.95, blue: 0.96))
                    )
                } else {
                    Button(action: {
                        showBoyLocationSearch = true
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "mappin")
                                .font(.system(size: 14))
                                .foregroundColor(Color("NavyPrimary").opacity(0.5))
                            
                            Text(viewModel.boyCity.isEmpty ? "select_city".localized : viewModel.boyCity)
                                .font(.system(size: 15))
                                .foregroundColor(viewModel.boyCity.isEmpty ? Color("TextDark").opacity(0.4) : Color("TextDark"))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color("NavyPrimary").opacity(0.4))
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.97, green: 0.97, blue: 0.98))
                        )
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 15, y: 5)
        )
        .padding(.horizontal, 20)
    }
    
    // Formatted date for display
    private var formattedBoyDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: viewModel.boyBirthDate)
    }
    
    // Formatted time for display
    private var formattedBoyTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: viewModel.boyBirthTime)
    }
    
    // MARK: - Girl Form Card
    private var girlFormCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("girls_name".localized)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color("TextDark").opacity(0.5))
                
                MatchTextField(
                    placeholder: "Enter name",
                    text: $viewModel.girlName,
                    icon: "person"
                )
            }
            
            // Date and Time row
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("date_of_birth_caps".localized)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color("TextDark").opacity(0.5))
                    
                    MatchDateButton(date: $viewModel.girlBirthDate)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("time_caps".localized)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color("TextDark").opacity(0.5))
                    
                    MatchTimeButton(time: $viewModel.girlBirthTime)
                }
            }
            
            // Place of Birth
            VStack(alignment: .leading, spacing: 8) {
                Text("place_of_birth_caps".localized)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color("TextDark").opacity(0.5))
                
                Button(action: {
                    showGirlLocationSearch = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin")
                            .font(.system(size: 14))
                            .foregroundColor(Color("NavyPrimary").opacity(0.5))
                        
                        Text(viewModel.girlCity.isEmpty ? "select_city".localized : viewModel.girlCity)
                            .font(.system(size: 15))
                            .foregroundColor(viewModel.girlCity.isEmpty ? Color("TextDark").opacity(0.4) : Color("TextDark"))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color("NavyPrimary").opacity(0.4))
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.97, green: 0.97, blue: 0.98))
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 15, y: 5)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Analyze Button
    private var analyzeButton: some View {
        Button(action: {
            Task { await viewModel.analyzeMatch() }
        }) {
            HStack(spacing: 10) {
                if viewModel.isAnalyzing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Text("analyze_match".localized)
                        .font(.system(size: 17, weight: .semibold))
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color("NavyPrimary"), Color("NavyPrimary").opacity(0.9)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color("NavyPrimary").opacity(0.4), radius: 10, y: 5)
        }
        .disabled(viewModel.isAnalyzing)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// MARK: - Match Date Button
struct MatchDateButton: View {
    @Binding var date: Date
    @State private var showPicker = false
    
    var body: some View {
        Button(action: { showPicker = true }) {
            HStack {
                Text(formatDate(date))
                    .font(.system(size: 15))
                    .foregroundColor(Color("NavyPrimary"))
                
                Spacer()
                
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundColor(Color("NavyPrimary").opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.96, green: 0.95, blue: 0.98))
            )
        }
        .sheet(isPresented: $showPicker) {
            MatchDatePickerSheet(date: $date, title: "Select Date")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Match Time Button
struct MatchTimeButton: View {
    @Binding var time: Date
    @State private var showPicker = false
    
    var body: some View {
        Button(action: { showPicker = true }) {
            HStack {
                Text(formatTime(time))
                    .font(.system(size: 15))
                    .foregroundColor(Color("NavyPrimary"))
                
                Spacer()
                
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundColor(Color("NavyPrimary").opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.96, green: 0.95, blue: 0.98))
            )
        }
        .sheet(isPresented: $showPicker) {
            MatchTimePickerSheet(time: $time, title: "Select Time")
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Match Person Form Card (for compatibility)
struct MatchPersonFormCard: View {
    let title: String
    let icon: String
    @Binding var name: String
    @Binding var birthDate: Date
    @Binding var birthTime: Date
    @Binding var city: String
    @Binding var latitude: Double
    @Binding var longitude: Double
    
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color("GoldAccent"))
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("NavyPrimary"))
            }
            
            // Name field
            MatchTextField(
                placeholder: "Full Name",
                text: $name,
                icon: "person"
            )
            
            // Date and Time row
            HStack(spacing: 12) {
                // Date button
                Button(action: { showDatePicker = true }) {
                    MatchFieldButton(
                        label: formatDate(birthDate),
                        icon: "calendar"
                    )
                }
                
                // Time button
                Button(action: { showTimePicker = true }) {
                    MatchFieldButton(
                        label: formatTime(birthTime),
                        icon: "clock"
                    )
                }
            }
            
            // City field with geocoding
            MatchTextField(
                placeholder: "Birth City",
                text: $city,
                icon: "mappin"
            )
            .onChange(of: city) { _, newValue in
                // Mock geocoding - in production use LocationService
                if !newValue.isEmpty {
                    latitude = 17.385
                    longitude = 78.4867
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
        )
        .sheet(isPresented: $showDatePicker) {
            MatchDatePickerSheet(date: $birthDate, title: "Select Date")
        }
        .sheet(isPresented: $showTimePicker) {
            MatchTimePickerSheet(time: $birthTime, title: "Select Time")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Match Text Field
struct MatchTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color("NavyPrimary").opacity(0.5))
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundColor(Color("NavyPrimary"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.96, green: 0.95, blue: 0.98))
        )
    }
}

// MARK: - Match Field Button
struct MatchFieldButton: View {
    let label: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color("NavyPrimary").opacity(0.5))
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color("NavyPrimary"))
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.96, green: 0.95, blue: 0.98))
        )
    }
}

// MARK: - Match Date Picker Sheet
struct MatchDatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date
    let title: String
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color("NavyPrimary"))
                }
                #else
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color("NavyPrimary"))
                }
                #endif
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Match Time Picker Sheet
struct MatchTimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var time: Date
    let title: String
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "",
                    selection: $time,
                    displayedComponents: .hourAndMinute
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
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color("NavyPrimary"))
                }
                #else
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color("NavyPrimary"))
                }
                #endif
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview
#Preview {
    CompatibilityView()
}
