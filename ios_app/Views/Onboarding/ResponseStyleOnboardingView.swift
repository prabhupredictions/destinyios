import SwiftUI

/// Full-screen card picker for Response Style — used in both onboarding and Settings.
/// `isSettingsMode` controls the subtitle copy (removes "in Settings" when already in Settings).
struct ResponseStyleOnboardingView: View {
    var isSettingsMode: Bool = false
    var onContinue: (() -> Void)?

    @State private var selectedStyle: ContentStyle
    @Environment(\.dismiss) private var dismiss

    init(isSettingsMode: Bool = false, onContinue: (() -> Void)? = nil) {
        self.isSettingsMode = isSettingsMode
        self.onContinue = onContinue
        _selectedStyle = State(initialValue: ContentStyleManager.shared.currentStyle)
    }

    var body: some View {
        ZStack {
            CosmicBackgroundView()
                .ignoresSafeArea()

            // Subtle gold radial glow at top
            VStack {
                RadialGradient(
                    gradient: Gradient(colors: [AppTheme.Colors.gold.opacity(0.07), Color.clear]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 300
                )
                .frame(height: 300)
                .offset(y: -60)
                Spacer()
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Step dots (only in onboarding flow)
                    if !isSettingsMode {
                        HStack(spacing: 6) {
                            ForEach(0..<4, id: \.self) { i in
                                Capsule()
                                    .fill(i == 2 ? AppTheme.Colors.gold : AppTheme.Colors.textTertiary.opacity(0.3))
                                    .frame(width: i == 2 ? 24 : 8, height: 8)
                            }
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                    } else {
                        // Settings: back chevron
                        HStack {
                            Button { dismiss() } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .padding(8)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }

                    // Header
                    VStack(spacing: 10) {
                        Text(NSLocalizedString("response_style_onboarding_title_prefix", value: "How should Destiny", comment: ""))
                            .font(AppTheme.Fonts.title(size: 26))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        + Text(" ")
                        + Text(NSLocalizedString("response_style_onboarding_title_emphasis", value: "respond to you?", comment: ""))
                            .font(.system(size: 26, weight: .semibold).italic())
                            .foregroundColor(AppTheme.Colors.gold)

                        Text(
                            isSettingsMode
                                ? NSLocalizedString("response_style_settings_subtitle", value: "Pick what feels right. You can change this anytime.", comment: "")
                                : NSLocalizedString("response_style_onboarding_subtitle", value: "Pick what feels right. You can change this anytime in Settings.", comment: "")
                        )
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)

                    // Cards
                    VStack(spacing: 14) {
                        ForEach(ContentStyle.allCases) { style in
                            styleCard(for: style)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)

                    // Continue / Save button
                    Button {
                        HapticManager.shared.premiumContinue()
                        ContentStyleManager.shared.setStyle(selectedStyle)
                        if let onContinue {
                            onContinue()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text(isSettingsMode
                             ? NSLocalizedString("save_action", value: "Save", comment: "")
                             : NSLocalizedString("continue", value: "Continue", comment: ""))
                            .font(AppTheme.Fonts.title(size: 16))
                            .foregroundColor(AppTheme.Colors.mainBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppTheme.Colors.premiumGradient)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Style Card

    private func styleCard(for style: ContentStyle) -> some View {
        let isSelected = selectedStyle == style

        return Button {
            HapticManager.shared.play(.light)
            withAnimation(.spring(response: 0.25)) {
                selectedStyle = style
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Title row
                HStack(spacing: 8) {
                    Image(systemName: style.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.gold)

                    Text(style.label)
                        .font(AppTheme.Fonts.title(size: 17))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Spacer()

                    // Radio indicator
                    ZStack {
                        Circle()
                            .stroke(isSelected ? AppTheme.Colors.gold : AppTheme.Colors.textTertiary.opacity(0.5), lineWidth: 1.5)
                            .frame(width: 24, height: 24)
                        if isSelected {
                            Circle()
                                .fill(AppTheme.Colors.gold)
                                .frame(width: 14, height: 14)
                        }
                    }
                    .animation(.spring(response: 0.25), value: isSelected)
                }
                .padding(.bottom, 6)

                // Tagline
                Text(style.tagline)
                    .font(AppTheme.Fonts.body(size: 13))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.trailing, 32)
                    .padding(.bottom, 16)

                // Example box
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("example_label", value: "EXAMPLE", comment: ""))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .tracking(1.2)

                    Text(NSLocalizedString("example_question_career", value: "\"Is this a good time to switch jobs?\"", comment: ""))
                        .font(AppTheme.Fonts.body(size: 11).italic())
                        .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.6))

                    Text(style.exampleResponse)
                        .font(AppTheme.Fonts.body(size: 12))
                        .foregroundColor(AppTheme.Colors.textPrimary.opacity(0.75))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.04), lineWidth: 1)
                        )
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppTheme.Colors.gold.opacity(0.06) : AppTheme.Colors.surfaceBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? AppTheme.Colors.gold.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

#Preview("Onboarding") {
    ResponseStyleOnboardingView(isSettingsMode: false, onContinue: {})
}

#Preview("Settings") {
    ResponseStyleOnboardingView(isSettingsMode: true)
}
