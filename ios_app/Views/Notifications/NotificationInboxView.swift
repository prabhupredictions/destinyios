import SwiftUI

/// Professional In-App Notification Inbox
/// Premium design matching app theme with grouped notifications
struct NotificationInboxView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var service = NotificationInboxService.shared
    @StateObject private var quotaManager = QuotaManager.shared
    @State private var selectedNotification: NotificationItem? = nil
    @State private var showNotificationPreferences = false
    @State private var showUpgradePrompt = false
    @State private var showGuestSignInSheet = false  // Guest sign-in prompt for alerts

    var onNavigateToHome: (() -> Void)? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppTheme.Colors.mainBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Personalize alerts button
                    personalizeAlertsButton
                    
                    // Content
                    if service.isLoading && service.notifications.isEmpty {
                        loadingView
                    } else if service.notifications.isEmpty {
                        emptyStateView
                    } else {
                        notificationList
                    }
                }
            }
            .navigationBarHidden(true)
            .accessibilityIdentifier("notifications_screen")
            .task {
                await service.fetchNotifications(refresh: true)
                await service.fetchUnreadCount()
            }
            .sheet(item: $selectedNotification) { notification in
                NotificationDetailSheet(notification: notification) {
                    dismiss()
                    onNavigateToHome?()
                }
            }
            .sheet(isPresented: $showNotificationPreferences) {
                if let email = DataManager.shared.getCurrentUserProfile()?.email {
                    NotificationPreferencesSheet(userEmail: email)
                }
            }
            .sheet(isPresented: $showUpgradePrompt) {
                SubscriptionView()
            }
            .sheet(isPresented: $showGuestSignInSheet) {
                GuestSignInPromptView(
                    message: "personalized_alerts_sign_in_prompt".localized,
                    onBack: { showGuestSignInSheet = false }
                )
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.Colors.cardBackground)
                    .clipShape(Circle())
            }
            .accessibilityLabel("a11y_close".localized)
            
            Spacer()
            
            // Title
            VStack(spacing: 2) {
                Text("notifications_title".localized)
                    .font(AppTheme.Fonts.title(size: 18))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if service.unreadCount > 0 {
                    Text(String(format: "unread_count_format".localized, service.unreadCount))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.Colors.gold)
                }
            }
            
            Spacer()
            
            // Mark all read button
            Button(action: {
                Task { await service.markAllAsRead() }
            }) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(service.unreadCount > 0 ? AppTheme.Colors.gold : AppTheme.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.Colors.cardBackground)
                    .clipShape(Circle())
            }
            .disabled(service.unreadCount == 0)
            .accessibilityLabel("a11y_mark_all_read".localized)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Personalize Alerts Button
    private var personalizeAlertsButton: some View {
        let isGuestUser = UserDefaults.standard.string(forKey: "userEmail")?.hasSuffix("@daa.com") ?? false
        
        return Button {
            if isGuestUser {
                showGuestSignInSheet = true
            } else if quotaManager.hasFeature(.alerts) {
                showNotificationPreferences = true
            } else {
                showUpgradePrompt = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isGuestUser ? "person.badge.plus" : "bell.badge")
                    .font(.system(size: 15, weight: .semibold))
                
                Text(isGuestUser ? "sign_up_to_personalize_alerts".localized : "personalize_alerts_cta".localized)
                    .font(.system(size: 16, weight: .semibold))
                
                if !isGuestUser {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                }
            }
            .foregroundColor(AppTheme.Colors.mainBackground)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                LinearGradient(
                    colors: isGuestUser ? 
                        [AppTheme.Colors.textSecondary, AppTheme.Colors.textSecondary.opacity(0.85)] :
                        [AppTheme.Colors.gold, AppTheme.Colors.gold.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }
    
    // MARK: - Notification List
    private var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(service.notifications) { notification in
                    NotificationRow(notification: notification)
                        .onTapGesture {
                            Task {
                                await service.markAsRead(notification.id)
                            }
                            selectedNotification = notification
                        }
                        .onAppear {
                            // Load more when reaching end
                            if notification.id == service.notifications.last?.id {
                                Task { await service.loadMore() }
                            }
                        }
                }
                
                // Loading indicator for pagination
                if service.isLoading && !service.notifications.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.gold))
                        .padding()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .refreshable {
            await service.fetchNotifications(refresh: true)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.gold))
                .scaleEffect(1.5)
            
            Text("loading_notifications".localized)
                .font(AppTheme.Fonts.caption(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(AppTheme.Colors.goldDim)
            
            VStack(spacing: 8) {
                Text("no_notifications".localized)
                    .font(AppTheme.Fonts.title(size: 20))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("no_notifications_desc".localized)
                    .font(AppTheme.Fonts.body(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: NotificationItem

    private var accentColor: Color {
        switch (notification.overallTone ?? "").lowercased() {
        case "positive":            return AppTheme.Colors.gold
        case "cautionary", "caution": return Color(red: 1.0, green: 0.65, blue: 0.0)
        default:                    return AppTheme.Colors.textSecondary.opacity(0.5)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Tone accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor)
                .frame(width: 4)
                .padding(.vertical, 12)
                .padding(.leading, 12)
                .padding(.trailing, 10)

            // Icon
            ZStack {
                Circle()
                    .fill(notification.read ? AppTheme.Colors.cardBackground : accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: notification.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(notification.read ? AppTheme.Colors.textSecondary : accentColor)
            }
            .padding(.top, 14)
            .padding(.trailing, 12)

            // Content
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(notification.displayTitle)
                        .font(.system(size: 15, weight: notification.read ? .medium : .bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text(notification.timeAgo)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                if let chip = notification.topicChip {
                    Text(chip)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(accentColor.opacity(0.12))
                        .clipShape(Capsule())
                }

                Text(notification.displayBody)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 14)
            .padding(.trailing, 12)

            // Unread indicator
            if !notification.read {
                Circle()
                    .fill(AppTheme.Colors.gold)
                    .frame(width: 8, height: 8)
                    .padding(.top, 18)
                    .padding(.trailing, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(notification.read ? AppTheme.Colors.cardBackground : AppTheme.Colors.cardBackground.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(notification.read ? Color.clear : accentColor.opacity(0.25), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: "a11y_notification_detail_format".localized, notification.displayTitle, notification.displayBody, notification.timeAgo, notification.read ? "" : "a11y_unread_suffix".localized))
        .accessibilityIdentifier("notification_row")
    }
}

// MARK: - Notification Detail Sheet
struct NotificationDetailSheet: View {
    let notification: NotificationItem
    @Environment(\.dismiss) private var dismiss
    var onNavigateToHome: (() -> Void)? = nil

    var body: some View {
        ZStack {
            AppTheme.Colors.mainBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Pull indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppTheme.Colors.separator)
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)
                    .padding(.bottom, 16)

                // Header: icon + title + timestamp
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.gold.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: notification.iconName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(notification.displayTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text(notification.timeAgo)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                Divider()

                // Scrollable full body text
                ScrollView(showsIndicators: false) {
                    Text(notification.displayBody)
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                }

                Divider()

                // Buttons
                VStack(spacing: 10) {
                    if canAskMore {
                        Button(action: {
                            let prompt = notification.chatPrompt
                                ?? "Tell me more about \(notification.displayTitle)"
                            NotificationRouter.shared.route(
                                type: notification.type,
                                prefill: prompt,
                                autoSubmit: true,
                                newThread: true
                            )
                            dismiss()
                            onNavigateToHome?()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 15, weight: .semibold))
                                Text(notification.chatPrompt ?? "ask_more".localized)
                                    .font(AppTheme.Fonts.caption(size: 15))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundColor(AppTheme.Colors.mainBackground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppTheme.Colors.gold)
                            .cornerRadius(12)
                        }
                        .accessibilityIdentifier("notification_action_button")
                    } else if notification.type.uppercased() == "COMPATIBILITY_READY" {
                        Button(action: {
                            NotificationRouter.shared.route(type: notification.type)
                            dismiss()
                            onNavigateToHome?()
                        }) {
                            Text("notification_action_compat".localized)
                                .font(AppTheme.Fonts.caption(size: 16))
                                .foregroundColor(AppTheme.Colors.mainBackground)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AppTheme.Colors.gold)
                                .cornerRadius(12)
                        }
                    } else if notification.type.uppercased() == "SUBSCRIPTION_EXPIRING" {
                        Button(action: {
                            NotificationRouter.shared.route(type: notification.type)
                            dismiss()
                            onNavigateToHome?()
                        }) {
                            Text("manage_subscription".localized)
                                .font(AppTheme.Fonts.caption(size: 16))
                                .foregroundColor(AppTheme.Colors.mainBackground)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AppTheme.Colors.gold)
                                .cornerRadius(12)
                        }
                    }

                    Button(action: { dismiss() }) {
                        Text("done".localized)
                            .font(AppTheme.Fonts.caption(size: 16))
                            .foregroundColor(AppTheme.Colors.gold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.Colors.gold.opacity(0.5), lineWidth: 1)
                            )
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 32)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var canAskMore: Bool {
        let t = notification.type.uppercased()
        return ["DAILY_PREDICTION_READY", "DAILY_PREDICTION", "TRANSIT_ALERT",
                "LIFE_ALERT", "CUSTOM_ALERT", "WELCOME"].contains(t)
    }
}

// MARK: - Preview
#Preview {
    NotificationInboxView()
}
