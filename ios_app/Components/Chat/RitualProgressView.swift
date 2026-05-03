import SwiftUI

/// Shows pipeline progress as a premium card with a thin fill-bar and step rows.
/// Battery efficient: one GPU-native pulse animation, no Timer, stops when streaming ends.
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
            VStack(alignment: .leading, spacing: 10) {
                // Thin gradient progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.07))
                        Capsule()
                            .fill(LinearGradient(
                                colors: [AppTheme.Colors.gold.opacity(0.5), AppTheme.Colors.gold],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: max(8, geo.size.width * progressFraction))
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
                                    .foregroundColor(Color.white.opacity(0.35))
                                    .frame(width: 8)
                            } else {
                                Circle()
                                    .fill(AppTheme.Colors.gold)
                                    .frame(width: 6, height: 6)
                                    .scaleEffect(pulse ? 1.3 : 0.7)
                                    .opacity(pulse ? 1.0 : 0.45)
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
                                              weight: row.isDone ? .regular : .medium))
                                .foregroundColor(row.isDone
                                    ? Color.white.opacity(0.38)
                                    : AppTheme.Colors.gold)
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                    }
                }
                .animation(.easeOut(duration: 0.3), value: displayRows.map(\.step.rawValue))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.Colors.gold.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.bottom, 10)
            .onAppear {
                guard isStreaming else { return }
                pulse = true
            }
            .onChange(of: isStreaming) { _, streaming in
                if !streaming { pulse = false }
            }
            .accessibilityIdentifier("ritual_progress_view")
        }
    }
}
