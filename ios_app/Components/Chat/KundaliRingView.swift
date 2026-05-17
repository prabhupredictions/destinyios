import SwiftUI

/// 28×28 pt 12-arc Kundali ring showing pipeline progress.
/// All animations stop when streaming ends (zero battery after done).
struct KundaliRingView: View {
    let completedSteps: [PipelineStep]
    let activeStep: PipelineStep?
    let isStreaming: Bool

    @State private var glowPhase: Bool = false

    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let r: CGFloat = 11
            let gapDeg: CGFloat = 3

            for i in 0 ..< 12 {
                let startDeg = Double(i * 30) - 90.0 + Double(gapDeg / 2)
                let endDeg = startDeg + 30.0 - Double(gapDeg)

                var path = Path()
                path.addArc(center: CGPoint(x: cx, y: cy),
                            radius: r,
                            startAngle: Angle(degrees: startDeg),
                            endAngle: Angle(degrees: endDeg),
                            clockwise: false)

                let step = PipelineStep(rawValue: i / 2)
                let state = segmentState(for: step)

                let color: Color
                let lineWidth: CGFloat
                switch state {
                case .done:
                    color = AppTheme.Colors.gold.opacity(0.85)
                    lineWidth = 2.5
                case .active:
                    let opacity = isStreaming ? (glowPhase ? 1.0 : 0.5) : 0.85
                    color = AppTheme.Colors.gold.opacity(opacity)
                    lineWidth = 2.5
                case .pending:
                    color = Color.white.opacity(0.07)
                    lineWidth = 2.0
                }

                context.stroke(path, with: .color(color),
                               style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
        }
        .frame(width: 28, height: 28)
        .onAppear {
            guard isStreaming else { return }
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                glowPhase = true
            }
        }
        .onChange(of: isStreaming) { _, streaming in
            if !streaming {
                withAnimation(.linear(duration: 0)) { glowPhase = false }
            }
        }
        .accessibilityIdentifier("kundali_ring_view")
        .accessibilityLabel("Chart analysis progress")
    }

    private enum SegmentState { case done, active, pending }

    private func segmentState(for step: PipelineStep?) -> SegmentState {
        guard let step else { return .pending }
        if completedSteps.contains(step) { return .done }
        if activeStep == step { return .active }
        return .pending
    }
}
