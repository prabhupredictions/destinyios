import SwiftUI

/// Two collapsible hairline-separated rows below reading body.
/// Shows "Why this is happening" (advice) and "Timing window".
struct DepthLayersView: View {
    let whyContent: String?
    let timingContent: String?

    @State private var whyExpanded = false
    @State private var timingExpanded = false

    var body: some View {
        if whyContent != nil || timingContent != nil {
            VStack(spacing: 0) {
                Divider()
                    .background(Color.white.opacity(0.06))

                if let why = whyContent {
                    depthRow(label: "Why this is happening",
                             content: why,
                             isExpanded: $whyExpanded,
                             accessibilityId: "depth_why_row")
                }

                if let timing = timingContent {
                    depthRow(label: "Timing window",
                             content: timing,
                             isExpanded: $timingExpanded,
                             accessibilityId: "depth_timing_row")
                }
            }
            .accessibilityIdentifier("depth_layers_view")
        }
    }

    @ViewBuilder
    private func depthRow(label: String, content: String,
                          isExpanded: Binding<Bool>, accessibilityId: String) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack {
                    Text(label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isExpanded.wrappedValue
                            ? AppTheme.Colors.gold.opacity(0.8)
                            : Color.white.opacity(0.45))
                    Spacer()
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.25))
                }
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(accessibilityId)

            if isExpanded.wrappedValue {
                Text(content)
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.65))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .accessibilityIdentifier("depth_expanded_content")
            }

            Divider()
                .background(Color.white.opacity(0.05))
        }
    }
}
