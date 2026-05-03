import SwiftUI

/// Premium reading layout for AI prediction messages.
/// Canela italic question label → domain tag + kundali ring →
/// ritual progress → SF Pro Text body → depth layers → footer.
struct ReadingMessageView: View {
    let message: LocalChatMessage
    let userQuery: String
    let completedSteps: [PipelineStep]
    let activeStep: PipelineStep?
    let isStreaming: Bool

    @State private var showCopied = false

    private var domainLabel: String {
        message.area?.uppercased() ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Question label — Canela italic
            if !userQuery.isEmpty && userQuery != "General question" {
                Text(userQuery)
                    .font(AppTheme.Fonts.body(size: 14).italic())
                    .foregroundColor(AppTheme.Colors.gold.opacity(0.65))
                    .lineLimit(3)
                    .padding(.bottom, 12)
                    .accessibilityIdentifier("reading_question_label")
            }

            // Domain tag + kundali ring inline
            if !domainLabel.isEmpty || isStreaming || !completedSteps.isEmpty {
                HStack(spacing: 8) {
                    if !domainLabel.isEmpty {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(AppTheme.Colors.gold)
                                .frame(width: 5, height: 5)
                            Text(domainLabel)
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.2)
                                .foregroundColor(AppTheme.Colors.gold)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.gold.opacity(0.08))
                                .overlay(Capsule().stroke(AppTheme.Colors.gold.opacity(0.18), lineWidth: 1))
                        )
                        .accessibilityIdentifier("reading_domain_tag")
                    }

                    KundaliRingView(
                        completedSteps: completedSteps,
                        activeStep: activeStep,
                        isStreaming: isStreaming
                    )
                }
                .padding(.bottom, 12)
            }

            // Ritual progress (fades in step by step during streaming)
            RitualProgressView(
                completedSteps: completedSteps,
                activeStep: activeStep,
                isStreaming: isStreaming
            )

            // Reading body — rendered markdown, SF Pro Text 16px
            if !message.content.isEmpty {
                MarkdownTextView(
                    content: message.content,
                    textColor: Color.white.opacity(0.92),
                    fontSize: 16
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("reading_body_text")
                .padding(.bottom, 2)
            }

            // Depth layers and footer — only once streaming is done
            if !isStreaming && !message.content.isEmpty {
                DepthLayersView(
                    whyContent: message.advice,
                    timingContent: nil
                )
                .padding(.top, 4)

                HStack(spacing: 14) {
                    Button {
                        UIPasteboard.general.string = message.content
                        showCopied = true
                        HapticManager.shared.play(.light)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showCopied = false
                        }
                    } label: {
                        Text(showCopied ? "Copied" : "⎘ Copy")
                            .font(.system(size: 11))
                            .foregroundColor(showCopied
                                ? AppTheme.Colors.gold
                                : Color.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("copy_button")

                    Spacer()

                    Text(message.createdAt, style: .time)
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.2))

                    InlineMessageRating(
                        message: message,
                        query: userQuery.isEmpty ? "General question" : userQuery,
                        responseText: String(message.content.prefix(500)),
                        predictionId: message.traceId
                    )
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Destiny said: \(message.content)")
        .accessibilityIdentifier("reading_entry")
    }
}
