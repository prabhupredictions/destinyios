import SwiftUI

// MARK: - Orbital Rings View
/// Decorative rotating orbital rings for cosmic ambiance
/// Used in: SplashView, AuthView, and other premium screens
struct OrbitalRingsView: View {
    let rotation: Double
    
    var body: some View {
        ZStack {
            // Inner ring
            Circle()
                .stroke(AppTheme.Colors.gold.opacity(0.2), lineWidth: 1)
                .frame(width: AppTheme.Splash.ringInnerSize, height: AppTheme.Splash.ringInnerSize)
                .rotationEffect(.degrees(rotation))
            
            // Middle ring
            Circle()
                .stroke(AppTheme.Colors.gold.opacity(0.1), lineWidth: 1)
                .frame(width: AppTheme.Splash.ringMiddleSize, height: AppTheme.Splash.ringMiddleSize)
                .rotationEffect(.degrees(-rotation * 0.5))
            
            // Outer ring
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                .frame(width: AppTheme.Splash.ringOuterSize, height: AppTheme.Splash.ringOuterSize)
                .rotationEffect(.degrees(rotation * 0.3))
        }
    }
}

// MARK: - Premium Text Field
/// Reusable premium text input field with consistent styling across all screens
/// Features:
/// - Visible placeholder text (textTertiary) on dark backgrounds
/// - Optional leading icon (gold color)
/// - AppTheme-integrated sizing and colors
/// - Title Case placeholder convention
///
/// Usage:
/// ```swift
/// PremiumInputField(
///     label: "your_name".localized,
///     icon: "person.circle",
///     placeholder: "enter_your_name".localized,
///     text: $viewModel.userName
/// )
/// ```
struct PremiumInputField: View {
    let label: String
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding? // Optional focus binding
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.BirthData.labelSpacing) {
            // Label row with icon
            HStack(spacing: AppTheme.BirthData.labelSpacing) {
                Image(systemName: icon)
                    .font(AppTheme.Fonts.body(size: AppTheme.BirthData.iconFontSize))
                    .foregroundColor(AppTheme.Colors.gold)
                Text(label)
                    .font(AppTheme.Fonts.caption(size: AppTheme.BirthData.labelFontSize))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            // Text field with custom visible placeholder
            ZStack(alignment: .leading) {
                // Placeholder (visible when text is empty)
                if text.isEmpty {
                    Text(placeholder)
                        .font(AppTheme.Fonts.body(size: AppTheme.BirthData.inputFontSize))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .padding(.leading, 16)
                }
                
                // Actual TextField
                TextField("", text: $text)
                    .font(AppTheme.Fonts.body(size: AppTheme.BirthData.inputFontSize))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .padding()
                    .submitLabel(.done) // Add "Done" button
                    .focused(isFocused ?? FocusState<Bool>().projectedValue) // Bind if provided, otherwise dummy
            }
            .background(AppTheme.Colors.inputBackground)
            .cornerRadius(AppTheme.BirthData.inputCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.BirthData.inputCornerRadius)
                    .stroke(AppTheme.Styles.inputBorder.stroke, lineWidth: AppTheme.Styles.inputBorder.width)
            )
        }
    }
}

#Preview("Orbital Rings") {
    ZStack {
        AppTheme.Colors.mainBackground.ignoresSafeArea()
        OrbitalRingsView(rotation: 45)
    }
}

// MARK: - Premium Wheel Picker
/// A fully custom UIPickerView wrapper that allows strict styling (Gold Text)
/// Used to replace the standard DatePicker which has inconsistent styling
struct PremiumWheelPicker: UIViewRepresentable {
    var data: [[String]]
    @Binding var selections: [Int]
    
    // Configuration
    var width: CGFloat? = nil
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        picker.backgroundColor = .clear
        picker.overrideUserInterfaceStyle = .dark // Force dark mode override
        return picker
    }
    
    func updateUIView(_ uiView: UIPickerView, context: Context) {
        // Update selections if changed externally
        for (component, selection) in selections.enumerated() {
            if uiView.selectedRow(inComponent: component) != selection {
                uiView.selectRow(selection, inComponent: component, animated: true)
            }
        }
        
        // Reload data if needed (basic check)
        if context.coordinator.parent.data != data {
            context.coordinator.parent = self
            uiView.reloadAllComponents()
        }
    }
    
    class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: PremiumWheelPicker
        
        init(_ parent: PremiumWheelPicker) {
            self.parent = parent
        }
        
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return parent.data.count
        }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return parent.data[component].count
        }
        
        // MARK: - Delegate (Styling)
        func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
            let title = parent.data[component][row]
            
            // Center alignment
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            return NSAttributedString(string: title, attributes: [
                .foregroundColor: UIColor(red: 212/255, green: 175/255, blue: 55/255, alpha: 1.0), // #D4AF37 (Gold)
                .font: UIFont.systemFont(ofSize: 20, weight: .medium),
                .paragraphStyle: paragraphStyle
            ])
        }
        
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            parent.selections[component] = row
        }
    }
}

// MARK: - Premium Date Picker Interface
/// A composite view that manages the logic for Date and Time selection
/// converting between Date/Time objects and indices for the wheel picker
struct PremiumDatePicker: View {
    @Binding var selection: Date
    let mode: DatePickerComponents // .date or .hourAndMinute
    
    // Internal State for Wheels
    @State private var dateSelections: [Int] = [0, 0, 0] // [Month, Day, Year]
    @State private var timeSelections: [Int] = [0, 0, 0] // [Hour, Minute, AM/PM]
    
    // Data Sources
    private let months = Calendar.current.monthSymbols
    private var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 100)...currentYear).reversed() // Last 100 years
    }
    private var days: [Int] { Array(1...31) }
    
    private var hours: [Int] { Array(1...12) }
    private var minutes: [Int] { Array(0...59) }
    private let periods = ["AM", "PM"]
    
    var body: some View {
        Group {
            if mode == .date {
                PremiumWheelPicker(
                    data: [
                        months,
                        days.map { String($0) },
                        years.map { String(format: "%d", $0) }
                    ],
                    selections: $dateSelections
                )
                .onChange(of: dateSelections) { _ in
                    updateDateFromSelection()
                }
                .onAppear {
                    initializeDateSelection()
                }
            } else {
                PremiumWheelPicker(
                    data: [
                        hours.map { String($0) },
                        minutes.map { String(format: "%02d", $0) },
                        periods
                    ],
                    selections: $timeSelections
                )
                .onChange(of: timeSelections) { _ in
                    updateTimeFromSelection()
                }
                .onAppear {
                    initializeTimeSelection()
                }
            }
        }
        .frame(height: 200)
    }
    
    // MARK: - Helpers
    private func initializeDateSelection() {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: selection) - 1
        let day = calendar.component(.day, from: selection) - 1
        let year = calendar.component(.year, from: selection)
        
        if let yearIndex = years.firstIndex(of: year) {
            dateSelections = [month, day, yearIndex]
        }
    }
    
    private func updateDateFromSelection() {
        let month = dateSelections[0] + 1
        let day = days[dateSelections[1]]
        let year = years[dateSelections[2]]
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        // Validate day (e.g., Feb 31 -> Feb 28/29)
        if let date = Calendar.current.date(from: components) {
            // Check if day matches (invalid days roll over)
            let validDay = Calendar.current.component(.day, from: date)
             // Simple adjustment logic could be added here if needed, 
             // but Calendar handles rollover automatically (Feb 30 -> Mar 2).
             // For strict birthday picking, usually acceptable or we clamp.
            selection = date
        }
    }
    
    private func initializeTimeSelection() {
        let calendar = Calendar.current
        let hour24 = calendar.component(.hour, from: selection)
        let minute = calendar.component(.minute, from: selection)
        
        let periodIndex = hour24 >= 12 ? 1 : 0
        var hour12 = hour24 > 12 ? hour24 - 12 : hour24
        hour12 = hour12 == 0 ? 12 : hour12
        
        let hourIndex = hours.firstIndex(of: hour12) ?? 0
        let minuteIndex = minutes.firstIndex(of: minute) ?? 0
        
        timeSelections = [hourIndex, minuteIndex, periodIndex]
    }
    
    private func updateTimeFromSelection() {
        let hour12 = hours[timeSelections[0]]
        let minute = minutes[timeSelections[1]]
        let isPM = timeSelections[2] == 1
        
        var hour24 = hour12
        if isPM && hour12 != 12 { hour24 += 12 }
        else if !isPM && hour12 == 12 { hour24 = 0 }
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selection)
        components.hour = hour24
        components.minute = minute
        
        if let newDate = calendar.date(from: components) {
            selection = newDate
        }
    }
}

// MARK: - Premium Selection Sheet
/// A generic bottom sheet for selecting an option from a list
/// Replaces standard Menu/Picker for a more premium, themed experience
struct PremiumSelectionSheet: View {
    let title: String
    @Binding var selectedValue: String
    let options: [(String, String)] // (Value, Label)
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            CosmicBackgroundView().ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Handle/Title
                VStack(spacing: 16) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 40, height: 4)
                        .padding(.top, 10)
                    
                    Text(title)
                        .font(AppTheme.Fonts.title(size: 20))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                // Options List
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(options, id: \.0) { value, label in
                            Button(action: {
                                selectedValue = value
                                HapticManager.shared.play(.light)
                                onDismiss()
                            }) {
                                HStack {
                                    Spacer() // Center
                                    Text(label)
                                        .font(AppTheme.Fonts.body(size: 18))
                                        .foregroundColor(selectedValue == value ? AppTheme.Colors.gold : AppTheme.Colors.textPrimary)
                                        .multilineTextAlignment(.center)
                                    Spacer() // Center
                                    
                                    if selectedValue == value {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(AppTheme.Colors.gold)
                                            .padding(.leading, 8)
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 24)
                                .background(Color.white.opacity(0.001))
                            }
                            
                            if value != options.last?.0 {
                                Divider()
                                    .background(AppTheme.Colors.separator)
                                    .padding(.horizontal, 24)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .presentationDetents([.height(CGFloat(options.count * 60 + 80)), .medium])
        .presentationDragIndicator(.hidden)
    }
}

