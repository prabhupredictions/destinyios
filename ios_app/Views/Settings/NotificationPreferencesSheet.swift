import SwiftUI
import UserNotifications

/// Personalized Alerts sheet (Plus-only).
/// Supports multiple alert items (max 5), each with independent frequency.
struct NotificationPreferencesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel = NotificationPreferencesViewModel()
    
    // iOS notification permission state
    @State private var iOSNotificationsAuthorized = false
    
    // Add/Edit sheet state
    @State private var showAddEditSheet = false
    @State private var editingAlert: AlertItem? = nil
    
    // Delete confirmation
    @State private var alertToDelete: AlertItem? = nil
    @State private var showDeleteConfirmation = false
    
    // Suggestion chips
    private let suggestions = [
        "Good day to invest or take calculated risks",
        "Good day for tough relationship conversations and conflict resolution",
        "Good day to shop for a big purchase and negotiate a deal",
        "Good day to ask for a raise, negotiate, or pitch something important"
    ]
    
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
                        // MARK: - Channels
                        Section {
                            pushNotificationsRow
                            channelToggle("Email", icon: "envelope.fill", isOn: $viewModel.emailEnabled)
                            channelToggle("In-App inbox", icon: "tray.fill", isOn: $viewModel.inAppEnabled)
                        } header: {
                            sectionHeader(
                                title: "Channels",
                                description: "Choose how you want to receive alerts"
                            )
                        }
                        
                        // MARK: - Alert Items
                        Section {
                            if viewModel.alertItems.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        Image(systemName: "bell.slash")
                                            .font(.system(size: 28))
                                            .foregroundColor(AppTheme.Colors.textTertiary)
                                        Text("no_alerts_yet".localized)
                                            .font(AppTheme.Fonts.body(size: 16).weight(.medium))
                                            .foregroundColor(AppTheme.Colors.textTertiary)
                                        Text("Add your first personalized alert below")
                                            .font(AppTheme.Fonts.caption(size: 12))
                                            .foregroundColor(AppTheme.Colors.textTertiary)
                                    }
                                    .padding(.vertical, 20)
                                    Spacer()
                                }
                                .listRowBackground(AppTheme.Colors.cardBackground)
                            } else {
                                ForEach(viewModel.alertItems) { item in
                                    alertItemRow(item)
                                }
                            }
                            
                            // Add button
                            if viewModel.canAddMore {
                                Button {
                                    editingAlert = nil
                                    showAddEditSheet = true
                                    HapticManager.shared.play(.light)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("Add new alert preference")
                                            .font(AppTheme.Fonts.body(size: 15))
                                    }
                                    .foregroundColor(AppTheme.Colors.gold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                }
                                .listRowBackground(AppTheme.Colors.cardBackground.opacity(0.6))
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 12))
                                    Text("max_alerts_reached".localized)
                                        .font(AppTheme.Fonts.caption(size: 13))
                                }
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .listRowBackground(Color.clear)
                            }
                        } header: {
                            sectionHeader(
                                title: "Alert preferences",
                                description: "Tell Destiny what you want personalized alerts about"
                            )
                        }
                        
                        // MARK: - Suggestions
                        Section {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button {
                                    addSuggestionAsAlert(suggestion)
                                    HapticManager.shared.play(.light)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(AppTheme.Colors.gold)
                                            .font(.system(size: 14))
                                            .frame(width: 20)
                                        
                                        Text(suggestion)
                                            .font(AppTheme.Fonts.body(size: 14))
                                            .foregroundColor(AppTheme.Colors.textPrimary)
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "plus.circle")
                                            .foregroundColor(viewModel.canAddMore ? AppTheme.Colors.gold : AppTheme.Colors.textTertiary)
                                            .font(.system(size: 16))
                                    }
                                }
                                .disabled(!viewModel.canAddMore)
                                .listRowBackground(AppTheme.Colors.cardBackground)
                            }
                        } header: {
                            sectionHeader(
                                title: "Suggestions",
                                description: "Tap to add"
                            )
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
                
                // Success toast
                if viewModel.showSaveSuccess {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.Colors.success)
                            Text("Alerts saved")
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
            .navigationTitle("Personalized alerts")
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
            .alert("Delete Alert", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { alertToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let item = alertToDelete {
                        withAnimation { viewModel.deleteAlert(id: item.id) }
                        alertToDelete = nil
                    }
                }
            } message: {
                if let item = alertToDelete {
                    Text("Remove \"\(item.text.prefix(50))...\"?")
                } else {
                    Text("Remove this alert?")
                }
            }
            .sheet(isPresented: $showAddEditSheet) {
                AddEditAlertSheet(
                    editingItem: editingAlert,
                    suggestions: suggestions,
                    canAddMore: viewModel.canAddMore
                ) { savedItem in
                    if editingAlert != nil {
                        viewModel.updateAlert(savedItem)
                    } else {
                        viewModel.addAlert(savedItem)
                    }
                }
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
    
    // MARK: - Alert Item Row
    
    private func alertItemRow(_ item: AlertItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.frequency.icon)
                .foregroundColor(AppTheme.Colors.gold)
                .font(.system(size: 16))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.text)
                    .font(AppTheme.Fonts.body(size: 14))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                
                Text(item.frequency.displayName)
                    .font(AppTheme.Fonts.caption(size: 11))
                    .foregroundColor(AppTheme.Colors.gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(AppTheme.Colors.gold.opacity(0.15))
                    )
            }
            
            Spacer()
            
            // Edit button
            Button {
                editingAlert = item
                showAddEditSheet = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            
            // Delete button
            Button {
                alertToDelete = item
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .listRowBackground(AppTheme.Colors.cardBackground)
    }
    
    // MARK: - Suggestion Helper
    
    private func addSuggestionAsAlert(_ suggestion: String) {
        guard viewModel.canAddMore else { return }
        let newItem = AlertItem(text: suggestion, frequency: .daily)
        viewModel.addAlert(newItem)
    }
    
    // MARK: - iOS Permission Helpers
    
    private func checkIOSNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                iOSNotificationsAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func handlePushToggleAttempt(enabled: Bool) {
        guard enabled else {
            viewModel.pushEnabled = false
            return
        }
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
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
    
    private func openAppSettings() {
        if let bundleId = Bundle.main.bundleIdentifier,
           let url = URL(string: "App-Prefs:apps&path=\(bundleId)") {
            UIApplication.shared.open(url)
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
    
    // MARK: - Push Notifications Row
    
    private var pushNotificationsRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .foregroundColor(AppTheme.Colors.gold)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("push_notifications".localized)
                        .font(AppTheme.Fonts.body(size: 16).weight(.medium))
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
            
            if !iOSNotificationsAuthorized {
                Button(action: openAppSettings) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.Colors.error)
                            .font(.system(size: 14))
                        
                        Text("Enable in iOS Settings → Apps → Destiny → Notifications")
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

// MARK: - Add / Edit Alert Sheet

struct AddEditAlertSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let editingItem: AlertItem?
    let suggestions: [String]
    let canAddMore: Bool
    let onSave: (AlertItem) -> Void
    
    @State private var text: String = ""
    @State private var frequency: NotificationPreferencesViewModel.NotificationFrequency = .daily
    @State private var frequencyDay: Int? = nil
    @FocusState private var isTextFocused: Bool
    
    private var isEditing: Bool { editingItem != nil }
    private var canSave: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.mainBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Text Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What do you want alerts about?")
                                .font(AppTheme.Fonts.title(size: 14))
                                .foregroundColor(AppTheme.Colors.gold)
                            
                            TextField("Type what you want alerts about", text: $text, axis: .vertical)
                                .font(AppTheme.Fonts.body(size: 15))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppTheme.Colors.cardBackground)
                                )
                                .focused($isTextFocused)
                            
                            Text("\(text.count)/200")
                                .font(AppTheme.Fonts.caption(size: 11))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.horizontal, 16)
                        
                        // MARK: - Frequency Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Alert frequency")
                                .font(AppTheme.Fonts.title(size: 14))
                                .foregroundColor(AppTheme.Colors.gold)
                            
                            VStack(spacing: 0) {
                                ForEach(NotificationPreferencesViewModel.NotificationFrequency.allCases) { freq in
                                    Button {
                                        frequency = freq
                                        frequencyDay = nil
                                        HapticManager.shared.play(.light)
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: freq.icon)
                                                .foregroundColor(AppTheme.Colors.gold)
                                                .frame(width: 24)
                                            
                                            Text(freq.displayName)
                                                .font(AppTheme.Fonts.body(size: 16))
                                                .foregroundColor(AppTheme.Colors.textPrimary)
                                            
                                            Spacer()
                                            
                                            if frequency == freq {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(AppTheme.Colors.gold)
                                                    .font(.system(size: 14, weight: .semibold))
                                            }
                                        }
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 16)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if freq != .monthly {
                                        Divider()
                                            .background(AppTheme.Colors.textTertiary.opacity(0.3))
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.Colors.cardBackground)
                            )
                        }
                        .padding(.horizontal, 16)
                        
                        // MARK: - Suggestions
                        if !isEditing {
                            VStack(alignment: .leading, spacing: 8) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("suggestions_label".localized)
                                        .font(AppTheme.Fonts.caption(size: 13).weight(.medium))
                                        .foregroundColor(AppTheme.Colors.gold)
                                    Text("tap_to_add".localized)
                                        .font(AppTheme.Fonts.caption(size: 12))
                                        .foregroundColor(AppTheme.Colors.textTertiary)
                                }
                                
                                VStack(spacing: 0) {
                                    ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                                        Button {
                                            text = suggestion
                                            HapticManager.shared.play(.light)
                                        } label: {
                                            HStack(spacing: 12) {
                                                Image(systemName: "sparkles")
                                                    .foregroundColor(AppTheme.Colors.gold)
                                                    .font(.system(size: 14))
                                                    .frame(width: 20)
                                                
                                                Text(suggestion)
                                                    .font(AppTheme.Fonts.body(size: 14))
                                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                                    .multilineTextAlignment(.leading)
                                                
                                                Spacer()
                                                
                                                Image(systemName: "plus.circle")
                                                    .foregroundColor(AppTheme.Colors.gold)
                                                    .font(.system(size: 16))
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 16)
                                        }
                                        .buttonStyle(.plain)
                                        
                                        if index < suggestions.count - 1 {
                                            Divider()
                                                .background(AppTheme.Colors.textTertiary.opacity(0.3))
                                        }
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppTheme.Colors.cardBackground)
                                )
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(isEditing ? "Edit alert" : "New alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        let limitedText = String(trimmed.prefix(200))
                        let item = AlertItem(
                            id: editingItem?.id ?? UUID().uuidString,
                            text: limitedText,
                            frequency: frequency,
                            frequencyDay: frequencyDay
                        )
                        onSave(item)
                        dismiss()
                    } label: {
                        Text(isEditing ? "Save" : "Add")
                            .fontWeight(.semibold)
                            .foregroundColor(canSave ? AppTheme.Colors.gold : AppTheme.Colors.textTertiary)
                    }
                    .disabled(!canSave)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                if let item = editingItem {
                    text = item.text
                    frequency = item.frequency
                    frequencyDay = item.frequencyDay
                }
                isTextFocused = true
            }
            .onChange(of: text) { _, newValue in
                if newValue.count > 200 {
                    text = String(newValue.prefix(200))
                }
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    NotificationPreferencesSheet(userEmail: "test@example.com")
}
