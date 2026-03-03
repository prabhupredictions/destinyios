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
            .task {
                await service.fetchNotifications(refresh: true)
                await service.fetchUnreadCount()
            }
            .sheet(item: $selectedNotification) { notification in
                NotificationDetailSheet(notification: notification)
            }
            .sheet(isPresented: $showNotificationPreferences) {
                if let email = DataManager.shared.getCurrentUserProfile()?.email {
                    NotificationPreferencesSheet(userEmail: email)
                }
            }
            .sheet(isPresented: $showUpgradePrompt) {
                SubscriptionView()
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
            .accessibilityLabel("Close")
            
            Spacer()
            
            // Title
            VStack(spacing: 2) {
                Text("Notifications")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if service.unreadCount > 0 {
                    Text("\(service.unreadCount) unread")
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
            .accessibilityLabel("Mark all as read")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Personalize Alerts Button
    private var personalizeAlertsButton: some View {
        Button {
            if quotaManager.hasFeature(.alerts) {
                showNotificationPreferences = true
            } else {
                showUpgradePrompt = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 15, weight: .semibold))
                
                Text("Personalize alerts")
                    .font(.system(size: 16, weight: .semibold))
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 12))
            }
            .foregroundColor(AppTheme.Colors.mainBackground)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                LinearGradient(
                    colors: [AppTheme.Colors.gold, AppTheme.Colors.gold.opacity(0.85)],
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
            
            Text("Loading notifications...")
                .font(.system(size: 14))
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
                Text("No Notifications")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("We'll let you know when there's something new")
                    .font(.system(size: 14))
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
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(notification.read ? AppTheme.Colors.cardBackground : AppTheme.Colors.gold.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: notification.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(notification.read ? AppTheme.Colors.textSecondary : AppTheme.Colors.gold)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
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
                
                Text(notification.displayBody)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            // Unread indicator
            if !notification.read {
                Circle()
                    .fill(AppTheme.Colors.gold)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(notification.read ? AppTheme.Colors.cardBackground : AppTheme.Colors.cardBackground.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(notification.read ? Color.clear : AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(notification.displayTitle), \(notification.displayBody), \(notification.timeAgo)\(notification.read ? "" : ", unread")")
    }
}

// MARK: - Notification Detail Sheet
struct NotificationDetailSheet: View {
    let notification: NotificationItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppTheme.Colors.mainBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Pull indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppTheme.Colors.separator)
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.gold.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: notification.iconName)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(AppTheme.Colors.gold)
                }
                
                // Content
                VStack(spacing: 12) {
                    Text(notification.displayTitle)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(notification.displayBody)
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // Timestamp
                    Label(notification.timeAgo, systemImage: "clock")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.Colors.goldDim)
                        .padding(.top, 8)
                }
                
                Spacer()
                
                // Dismiss button
                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.mainBackground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppTheme.Colors.gold)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Preview
#Preview {
    NotificationInboxView()
}
