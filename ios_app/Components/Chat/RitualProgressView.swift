import SwiftUI

/// Pipeline progress shown as an editorial pull-quote block.
/// Left gold bar + ring header + thin fill line + italic step rows.
/// Battery efficient: one GPU-native pulse, no Timer, stops on streaming end.
struct RitualProgressView: View {
    let completedSteps: [PipelineStep]
    let activeStep: PipelineStep?
    let isStreaming: Bool

    @State private var pulse = false

    private static let trackedSteps = PipelineStep.allCases.filter { $0 != .reading }

    private var progressFraction: Double {
        let done = completedSteps.filter { $0 != .reading }.count
        return Double(done) / Double(Self.trackedSteps.count)
    }

    private var displayRows: [(step: PipelineStep, isDone: Bool)] {
        let done = completedSteps.suffix(2).map { ($0, true) }
        let active = activeStep.map { [($0, false)] } ?? []
        return Array((done + active).suffix(3))
    }

    var body: some View {
        if isStreaming || !completedSteps.isEmpty {
            HStack(alignment: .top, spacing: 14) {

                // Left gold accent bar
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.gold.opacity(0.7), AppTheme.Colors.gold.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2)
                    .cornerRadius(1)

                VStack(alignment: .leading, spacing: 10) {

                    // Header: ring + status label
                    HStack(spacing: 8) {
                        KundaliRingView(
                            completedSteps: completedSteps,
                            activeStep: activeStep,
                            isStreaming: isStreaming
                        )

                        Text(activeStep != nil ? "Reading your stars\u{2026}" : "Chart complete")
                            .font(.system(size: 12, weight: .regular).italic())
                            .foregroundColor(Color.white.opacity(0.45))
                    }

                    // Thin progress fill line
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.07))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.Colors.gold.opacity(0.5), AppTheme.Colors.gold],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(6, geo.size.width * progressFraction))
                                .animation(.easeInOut(duration: 0.7), value: progressFraction)
                        }
                    }
                    .frame(height: 2)

                    // Step rows
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(displayRows, id: \.step.rawValue) { row in
                            HStack(spacing: 9) {
                                if row.isDone {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(Color.white.opacity(0.3))
                                        .frame(width: 8)
                                } else {
                                    Circle()
                                        .fill(AppTheme.Colors.gold)
                                        .frame(width: 6, height: 6)
                                        .scaleEffect(pulse ? 1.35 : 0.65)
                                        .opacity(pulse ? 1.0 : 0.4)
                                        .animation(
                                            isStreaming
                                                ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                                                : .easeOut(duration: 0.2),
                                            value: pulse
                                        )
                                        .frame(width: 8)
                                }

                                Text(row.step.label)
                                    .font(.system(size: row.isDone ? 13 : 14,
                                                  weight: row.isDone ? .regular : .medium)
                                        .italic())
                                    .foregroundColor(row.isDone
                                        ? Color.white.opacity(0.32)
                                        : AppTheme.Colors.gold)
                            }
                            .accessibilityIdentifier(row.isDone ? "ritual_step_done" : "ritual_step_active")
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            ))
                        }
                    }
                    .animation(.easeOut(duration: 0.3), value: displayRows.map(\.step.rawValue))
                }
            }
            .padding(.bottom, 12)
            .accessibilityIdentifier("ritual_progress_view")
            .onAppear {
                guard isStreaming else { return }
                pulse = true
            }
            .onChange(of: isStreaming) { _, streaming in
                if !streaming { pulse = false }
            }
        }
    }
}
