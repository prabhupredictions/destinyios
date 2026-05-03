import SwiftUI

/// Shows the last 3 pipeline steps as fade-in ritual text rows.
/// Collapses when streaming ends.
struct RitualProgressView: View {
    let completedSteps: [PipelineStep]
    let activeStep: PipelineStep?
    let isStreaming: Bool

    @State private var ellipsisVisible = true

    private var displaySteps: [PipelineStep] {
        let active = activeStep.map { [$0] } ?? []
        let doneRecent = completedSteps.suffix(2)
        return Array((Array(doneRecent) + active).suffix(3))
    }

    var body: some View {
        if isStreaming || !completedSteps.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(displaySteps, id: \.rawValue) { step in
                    HStack(spacing: 7) {
                        Text("✦")
                            .font(.system(size: 9))
                            .foregroundColor(step == activeStep
                                ? AppTheme.Colors.gold
                                : Color.white.opacity(0.18))

                        Text(step.label)
                            .font(.system(size: 11))
                            .foregroundColor(step == activeStep
                                ? AppTheme.Colors.gold
                                : Color.white.opacity(0.18))
                            + Text(step == activeStep ? (ellipsisVisible ? "…" : "  ") : "")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .accessibilityIdentifier(step == activeStep ? "ritual_step_active" : "ritual_step_done")
                }
            }
            .padding(.bottom, 10)
            .accessibilityIdentifier("ritual_progress_view")
            .onAppear { startEllipsis() }
            .onChange(of: isStreaming) { _, streaming in
                if !streaming { ellipsisVisible = false }
            }
        }
    }

    private func startEllipsis() {
        Timer.scheduledTimer(withTimeInterval: 0.65, repeats: true) { t in
            if !isStreaming { t.invalidate(); return }
            ellipsisVisible.toggle()
        }
    }
}
