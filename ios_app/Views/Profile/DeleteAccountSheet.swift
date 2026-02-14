import SwiftUI

/// Confirmation sheet for account deletion with safety checks
struct DeleteAccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isDeleting: Bool
    @Binding var errorMessage: String?
    
    let hasActiveSubscription: Bool
    let onConfirmDelete: () -> Void
    
    @State private var confirmationText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    private var canDelete: Bool {
        confirmationText == "DELETE" && !hasActiveSubscription && !isDeleting
    }
    
    var body: some View {
        ZStack {
            CosmicBackgroundView()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Warning Icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.error.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(AppTheme.Colors.error)
                    }
                    .padding(.top, 20)
                    
                    // Title
                    Text("Delete Your Account?")
                        .font(AppTheme.Fonts.display(size: 24))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    // Warning bullets
                    VStack(alignment: .leading, spacing: 14) {
                        warningBullet(
                            icon: "xmark.circle.fill",
                            text: "Your account will be permanently deactivated"
                        )
                        warningBullet(
                            icon: "envelope.badge.fill",
                            text: "You will NOT be able to sign in with this email again"
                        )
                        warningBullet(
                            icon: "trash.fill",
                            text: "All your data (chats, matches, birth profiles) will be inaccessible"
                        )
                    }
                    .padding(.horizontal, 8)
                    
                    // Active subscription warning
                    if hasActiveSubscription {
                        HStack(spacing: 10) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                            
                            Text("Please cancel your subscription in the App Store before deleting your account.")
                                .font(AppTheme.Fonts.body(size: 14))
                                .foregroundColor(.orange)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    // Confirmation input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type DELETE to confirm")
                            .font(AppTheme.Fonts.title(size: 14))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        TextField("", text: $confirmationText)
                            .font(AppTheme.Fonts.body(size: 16))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.Colors.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                confirmationText == "DELETE" 
                                                    ? AppTheme.Colors.error.opacity(0.5) 
                                                    : Color.white.opacity(0.1),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                            .focused($isTextFieldFocused)
                    }
                    
                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(AppTheme.Fonts.body(size: 13))
                            .foregroundColor(AppTheme.Colors.error)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        // Delete button
                        Button(action: {
                            isTextFieldFocused = false
                            onConfirmDelete()
                        }) {
                            HStack(spacing: 8) {
                                if isDeleting {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 14))
                                }
                                Text("Delete Account")
                                    .font(AppTheme.Fonts.title(size: 16))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(canDelete ? AppTheme.Colors.error : AppTheme.Colors.error.opacity(0.3))
                            )
                        }
                        .disabled(!canDelete)
                        
                        // Cancel button
                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .font(AppTheme.Fonts.title(size: 16))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isDeleting)
    }
    
    // MARK: - Warning Bullet
    private func warningBullet(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.error.opacity(0.8))
                .frame(width: 20)
            
            Text(text)
                .font(AppTheme.Fonts.body(size: 15))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
