import SwiftUI
import UserNotifications

/// Notification Preferences sheet (Plus-only).
/// Follows the same List + section + gold styling as AstrologySettingsSheet.
struct NotificationPreferencesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel = NotificationPreferencesViewModel()
    
    // iOS notification permission state
    @State private var iOSNotificationsAuthorized = false
    
    let userEmail: String
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.mainBackground.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppTheme.Colors.gold)
                } else {
                    List {
                        // MARK: - Master Toggle
                        Section {
                            Toggle(isOn: $viewModel.isEnabled) {
                                Label {
                                    Text("Enable Notifications")
                                        .font(AppTheme.Fonts.body(size: 16))
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                } icon: {
                                    Image(systemName: "bell.badge.fill")
                                        .foregroundColor(AppTheme.Colors.gold)
                                }
                            }
                            .tint(AppTheme.Colors.gold)
                            .listRowBackground(AppTheme.Colors.cardBackground)
                        } header: {
                            sectionHeader(
                                title: "Notifications",
                                description: "Master switch for all custom notifications"
                            )
                        }
                        
                        if viewModel.isEnabled {
                            // MARK: - Channels
                            Section {
                                // Push Notifications with iOS permission check
                                pushNotificationsRow
                                
                                channelToggle("Email", icon: "envelope.fill", isOn: $viewModel.emailEnabled)
                                channelToggle("In-App Inbox", icon: "tray.fill", isOn: $viewModel.inAppEnabled)
                            } header: {
                                sectionHeader(
                                    title: "Channels",
                                    description: "Choose how you receive notifications"
                                )
                            }
                            
                            // MARK: - Frequency
                            Section {
                                ForEach(NotificationPreferencesViewModel.NotificationFrequency.allCases) { freq in
                                    Button {
                                        viewModel.frequency = freq
                                        viewModel.frequencyDay = nil
                                        HapticManager.shared.play(.light)
                                    } label: {
                                        HStack {
                                            Image(systemName: freq.icon)
                                                .foregroundColor(AppTheme.Colors.gold)
                                                .frame(width: 24)
                                            
                                            Text(freq.displayName)
                                                .font(AppTheme.Fonts.body(size: 16))
                                                .foregroundColor(AppTheme.Colors.textPrimary)
                                            
                                            Spacer()
                                            
                                            if viewModel.frequency == freq {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(AppTheme.Colors.gold)
                                                    .font(AppTheme.Fonts.title(size: 14))
                                            }
                                        }
                                    }
                                    .listRowBackground(AppTheme.Colors.cardBackground)
                                }
                                
                                // Day picker for weekly/monthly
                                if viewModel.frequency == .weekly {
                                    Picker("Day of Week", selection: Binding(
                                        get: { viewModel.frequencyDay ?? 1 },
                                        set: { viewModel.frequencyDay = $0 }
                                    )) {
                                        Text("Monday").tag(1)
                                        Text("Tuesday").tag(2)
                                        Text("Wednesday").tag(3)
                                        Text("Thursday").tag(4)
                                        Text("Friday").tag(5)
                                        Text("Saturday").tag(6)
                                        Text("Sunday").tag(7)
                                    }
                                    .font(AppTheme.Fonts.body(size: 16))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                    .tint(AppTheme.Colors.gold)
                                    .listRowBackground(AppTheme.Colors.cardBackground)
                                }
                                
                                if viewModel.frequency == .monthly {
                                    Picker("Day of Month", selection: Binding(
                                        get: { viewModel.frequencyDay ?? 1 },
                                        set: { viewModel.frequencyDay = $0 }
                                    )) {
                                        ForEach(1...28, id: \.self) { day in
                                            Text("\(day)").tag(day)
                                        }
                                    }
                                    .font(AppTheme.Fonts.body(size: 16))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                    .tint(AppTheme.Colors.gold)
                                    .listRowBackground(AppTheme.Colors.cardBackground)
                                }
                            } header: {
                                sectionHeader(
                                    title: "Frequency",
                                    description: "How often you'd like to receive notifications"
                                )
                            }
                            
                            // MARK: - Custom Instructions
                            Section {
                                VStack(alignment: .leading, spacing: 8) {
                                    TextEditor(text: $viewModel.customInstruction)
                                        .font(AppTheme.Fonts.body(size: 15))
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                        .scrollContentBackground(.hidden)
                                        .frame(minHeight: 100)
                                    
                                    Text("\(viewModel.customInstruction.count)/500")
                                        .font(AppTheme.Fonts.caption(size: 12))
                                        .foregroundColor(AppTheme.Colors.textTertiary)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                                .listRowBackground(AppTheme.Colors.cardBackground)
                            } header: {
                                sectionHeader(
                                    title: "Custom Instructions",
                                    description: "Tell the AI what topics or style you prefer for your notifications"
                                )
                            } footer: {
                                Text("Example: \"Focus on career and finance. Keep it short and uplifting.\"")
                                    .font(AppTheme.Fonts.caption(size: 12))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isEnabled)
                }
                
                // Success toast
                if viewModel.showSaveSuccess {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.Colors.success)
                            Text("Preferences saved")
                                .font(AppTheme.Fonts.body(size: 14))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.cardBackground)
                                .shadow(color: .black.opacity(0.3), radius: 10)
                        )
                        .padding(.bottom, 20)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Notification Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.savePreferences(email: userEmail) }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(AppTheme.Colors.gold)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.Colors.gold)
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                await viewModel.loadPreferences(email: userEmail)
                checkIOSNotificationPermission()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                checkIOSNotificationPermission()
            }
        }
    }
    
    // MARK: - iOS Permission Helpers
    
    /// Check current iOS notification permission status
    private func checkIOSNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                iOSNotificationsAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Request iOS notification permission or open settings if denied
    private func handlePushToggleAttempt(enabled: Bool) {
        guard enabled else {
            // User is turning OFF push - allow it
            viewModel.pushEnabled = false
            return
        }
        
        // User is turning ON push - check iOS permission first
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    // Request permission
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                        DispatchQueue.main.async {
                            iOSNotificationsAuthorized = granted
                            if granted {
                                viewModel.pushEnabled = true
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                        }
                    }
                case .denied:
                    // Permission denied - open iOS Settings for Destiny app
                    openAppSettings()
                case .authorized, .provisional, .ephemeral:
                    iOSNotificationsAuthorized = true
                    viewModel.pushEnabled = true
                @unknown default:
                    break
                }
            }
        }
    }
    
    /// Open Destiny app settings in iOS Settings
    private func openAppSettings() {
        // Modern iOS: Use App-Prefs:apps&path= to open specific app settings page
        if let bundleId = Bundle.main.bundleIdentifier,
           let url = URL(string: "App-Prefs:apps&path=\(bundleId)") {
            UIApplication.shared.open(url)
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
    
    // MARK: - Push Notifications Row with Permission Check
    
    private var pushNotificationsRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .foregroundColor(AppTheme.Colors.gold)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Push Notifications")
                        .font(AppTheme.Fonts.body(size: 16))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if !iOSNotificationsAuthorized {
                        Text("Permission required in iOS Settings")
                            .font(AppTheme.Fonts.caption(size: 12))
                            .foregroundColor(AppTheme.Colors.error)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { viewModel.pushEnabled && iOSNotificationsAuthorized },
                    set: { newValue in
                        handlePushToggleAttempt(enabled: newValue)
                    }
                ))
                .labelsHidden()
                .tint(AppTheme.Colors.gold)
                .disabled(!iOSNotificationsAuthorized && !viewModel.pushEnabled)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(AppTheme.Colors.cardBackground)
            
            // Warning row if permission denied
            if !iOSNotificationsAuthorized {
                Button(action: openAppSettings) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.Colors.error)
                            .font(.system(size: 14))
                        
                        Text("Enable in iOS Settings → Notifications → Destiny")
                            .font(AppTheme.Fonts.caption(size: 12))
                            .foregroundColor(AppTheme.Colors.error)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(AppTheme.Colors.error)
                            .font(.system(size: 12))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(AppTheme.Colors.error.opacity(0.1))
                }
                .buttonStyle(.plain)
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Components
    
    private func sectionHeader(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.Fonts.title(size: 14))
                .foregroundColor(AppTheme.Colors.gold)
            Text(description)
                .font(AppTheme.Fonts.caption(size: 12))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
    }
    
    private func channelToggle(_ title: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Label {
                Text(title)
                    .font(AppTheme.Fonts.body(size: 16))
                    .foregroundColor(AppTheme.Colors.textPrimary)
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.Colors.gold)
            }
        }
        .tint(AppTheme.Colors.gold)
        .listRowBackground(AppTheme.Colors.cardBackground)
    }
}

#Preview {
    NotificationPreferencesSheet(userEmail: "test@example.com")
}
