import SwiftUI

/// Bottom sheet for selecting response length (concise vs expanded) in chat input bar.
struct ResponseLengthSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var manager = ResponseLengthManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(NSLocalizedString("response_length_title", value: "Response Length", comment: ""))
                    .font(AppTheme.Fonts.title(size: 20))
                    .foregroundColor(AppTheme.Colors.gold)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
            .padding(24)

            // Options
            VStack(spacing: 16) {
                ForEach(ResponseLength.allCases) { length in
                    lengthOptionRow(for: length)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(AppTheme.Colors.surfaceBackground)
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }

    private func lengthOptionRow(for length: ResponseLength) -> some View {
        let isSelected = manager.currentLength == length

        return Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            manager.setLength(length)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                dismiss()
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.Colors.gold.opacity(0.15) : AppTheme.Colors.mainBackground)
                        .frame(width: 48, height: 48)
                    Image(systemName: length.icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? AppTheme.Colors.gold : AppTheme.Colors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(length.label)
                        .font(AppTheme.Fonts.body(size: 16).weight(isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? AppTheme.Colors.gold : AppTheme.Colors.textPrimary)
                    Text(length.description)
                        .font(AppTheme.Fonts.body(size: 13))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? AppTheme.Colors.gold : AppTheme.Colors.textTertiary, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(AppTheme.Colors.gold)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppTheme.Colors.gold.opacity(0.05) : AppTheme.Colors.mainBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppTheme.Colors.gold.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ResponseLengthSheet()
        .preferredColorScheme(.dark)
}
