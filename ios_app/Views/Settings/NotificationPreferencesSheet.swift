import SwiftUI

/// Notification Preferences sheet (Plus-only).
/// Follows the same List + section + gold styling as AstrologySettingsSheet.
struct NotificationPreferencesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NotificationPreferencesViewModel()
    
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
                                channelToggle("Push Notifications", icon: "iphone.radiowaves.left.and.right", isOn: $viewModel.pushEnabled)
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
            }
        }
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
