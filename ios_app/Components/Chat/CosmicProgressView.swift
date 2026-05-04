import SwiftUI

/// Gemini-style progress indicator: sparkle icon + single cycling message with crossfade.
struct CosmicProgressView: View {
    let steps: [CosmicProgressStep]

    private var currentText: String {
        steps.last(where: { $0.isActive })?.text ?? steps.last?.text ?? ""
    }

    var body: some View {
        if !steps.isEmpty {
            HStack(alignment: .center, spacing: 10) {
                SparkleIcon()
                    .frame(width: 24, height: 24)

                Text(currentText)
                    .font(AppTheme.Fonts.body(size: 15))
                    .foregroundColor(Color.white.opacity(0.85))
                    .lineLimit(1)
                    .id(currentText)
                    .transition(.opacity.animation(.easeInOut(duration: 0.4)))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 14)
            .animation(.easeInOut(duration: 0.4), value: currentText)
            .accessibilityIdentifier("cosmic_progress_view")
            .accessibilityLabel("Loading: \(currentText)")
        }
    }
}

private struct SparkleIcon: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(
                LinearGradient(
                    colors: [AppTheme.Colors.gold, AppTheme.Colors.gold.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    scale = 1.15
                }
            }
    }
}
