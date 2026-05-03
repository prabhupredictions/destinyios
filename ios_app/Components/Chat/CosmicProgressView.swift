import SwiftUI

/// Premium agentic pipeline progress — gold left border, fade-in steps, checkmarks.
struct CosmicProgressView: View {
    let steps: [CosmicProgressStep]

    var body: some View {
        if !steps.isEmpty {
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.gold.opacity(0.8), AppTheme.Colors.gold.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2)
                    .cornerRadius(1)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(steps) { step in
                        CosmicProgressStepRow(step: step)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .accessibilityIdentifier("cosmic_progress_view")
        }
    }
}

private struct CosmicProgressStepRow: View {
    let step: CosmicProgressStep

    @State private var dotsOpacity: Double = 1.0
    @State private var dotsTimer: Timer?
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkle")
                .font(.system(size: 9))
                .foregroundColor(stepColor)

            Text(step.text)
                .font(AppTheme.Fonts.body(size: 14))
                .foregroundColor(stepColor)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 4)

            if step.isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.gold.opacity(0.7))
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityIdentifier("progress_checkmark")
            } else if step.isActive {
                ThreeDotsView(opacity: dotsOpacity)
                    .accessibilityIdentifier("progress_active_dots")
            }
        }
        .opacity(step.isCompleted ? 0.55 : 1.0)
        .accessibilityIdentifier("progress_step_row")
        .accessibilityLabel(step.isActive ? "active: \(step.text)" : (step.isCompleted ? "completed: \(step.text)" : step.text))
        .overlay(
            Color.clear
                .accessibilityIdentifier(step.isActive ? "progress_step_active" : (step.isCompleted ? "progress_step_completed" : "progress_step_pending"))
        )
        .onAppear {
            guard !appeared else { return }
            appeared = true
            if step.isActive {
                startDotsAnimation()
            }
        }
        .onChange(of: step.isActive) { _, active in
            if active {
                startDotsAnimation()
            } else {
                stopDotsAnimation()
            }
        }
        .onDisappear {
            stopDotsAnimation()
        }
    }

    private var stepColor: Color {
        step.isActive ? AppTheme.Colors.gold : AppTheme.Colors.textSecondary
    }

    private func startDotsAnimation() {
        stopDotsAnimation()
        dotsTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                dotsOpacity = dotsOpacity < 0.5 ? 1.0 : 0.3
            }
        }
    }

    private func stopDotsAnimation() {
        dotsTimer?.invalidate()
        dotsTimer = nil
    }
}

private struct ThreeDotsView: View {
    let opacity: Double

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0 ..< 3, id: \.self) { _ in
                Circle()
                    .fill(AppTheme.Colors.gold)
                    .frame(width: 4, height: 4)
            }
        }
        .opacity(opacity)
    }
}
