import SafariServices
import SwiftUI

struct WaitlistPendingView: View {
    let userEmail: String

    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @AppStorage("lastAccessState") private var lastAccessState = "unknown"
    @State private var showTally = false

    private var tallyURL: URL {
        let encoded = userEmail.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? ""
        return URL(
            string: "https://tally.so/r/w4bOkb?utm_source=iOSApp&utm_medium=waitlist_screen&email=\(encoded)"
        )!
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.mainBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.Colors.gold)

                VStack(spacing: 12) {
                    Text(NSLocalizedString("waitlist_title", value: "You're almost in", comment: "Waitlist pending screen title"))
                        .font(AppTheme.Fonts.title(size: 28))
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    VStack(spacing: 8) {
                        Text(NSLocalizedString("waitlist_body_1", value: "Destiny is in early access right now, and we're rolling out in phases.", comment: "Waitlist pending screen body line 1"))
                            .font(AppTheme.Fonts.body(size: 16))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)

                        Text(NSLocalizedString("waitlist_body_2", value: "Take a moment to fill out this quick form and we'll get you in soon:", comment: "Waitlist pending screen body line 2"))
                            .font(AppTheme.Fonts.body(size: 16))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                }

                Button {
                    showTally = true
                } label: {
                    Text(NSLocalizedString("waitlist_cta", value: "Join the Waitlist", comment: "Waitlist Tally form CTA"))
                        .font(AppTheme.Fonts.body(size: 16).weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.gold)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.Colors.gold, lineWidth: 1)
                        )
                }

                Text(NSLocalizedString("waitlist_already_filled", value: "Already filled it out? Hang tight, your turn is coming.", comment: "Waitlist pending reassurance text"))
                    .font(AppTheme.Fonts.caption(size: 13))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 4) {
                    Text(NSLocalizedString("waitlist_support_prefix", value: "Questions or need help? Reach us anytime at", comment: "Waitlist support text prefix"))
                        .font(AppTheme.Fonts.caption(size: 13))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                    Link("support@destinyaiastrology.com",
                         destination: URL(string: "mailto:support@destinyaiastrology.com")!)
                        .font(AppTheme.Fonts.caption(size: 13))
                        .foregroundStyle(AppTheme.Colors.gold)
                }
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        lastAccessState = "unknown"
                        isAuthenticated = false
                    }
                } label: {
                    Text(NSLocalizedString("waitlist_back_to_login", value: "Back to Login", comment: "Waitlist screen back to login button"))
                        .font(AppTheme.Fonts.body(size: 15))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showTally) {
            SafariView(url: tallyURL)
        }
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
