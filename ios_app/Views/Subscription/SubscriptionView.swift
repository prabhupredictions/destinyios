import SwiftUI
import StoreKit

/// Subscription screen matching target mockup design
/// Features displayed from backend with marketing_text
struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var quotaManager = QuotaManager.shared
    @State private var isPurchasing = false
    @State private var purchasingPlanId: String?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var plans: [PlanInfo] = []
    @State private var isLoading = true
    @State private var isRefreshing = false  // For manual refresh button
    @State private var showDestinyMatchingInfo = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Loading plans...")
                            .padding(.vertical, 40)
                    } else if plans.isEmpty {
                        Text("No plans available")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .padding(.vertical, 40)
                    } else {
                        // Plan cards with feature lists
                        planCardsSection
                        
                        // Collapsible "What is Destiny Matching™?"
                        destinyMatchingSection
                        
                        // Restore purchases
                        restoreButton
                        
                        // Footer disclaimers
                        footerDisclaimers
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(AppTheme.Colors.mainBackground.ignoresSafeArea())
            .navigationTitle("Choose a plan")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await refreshStatus() }
                    } label: {
                        if isRefreshing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.gold))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(AppTheme.Colors.gold)
                        }
                    }
                    .disabled(isRefreshing)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.Colors.gold)
                }
                #endif
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await loadPlans()
            }
        }
    }
    
    // MARK: - Load Plans from Backend
    private func loadPlans() async {
        isLoading = true
        do {
            var fetchedPlans = try await quotaManager.fetchPlans()
            // Filter to show only paid plans (core, plus)
            fetchedPlans = fetchedPlans.filter { !$0.isFree && $0.planId != "free_guest" && $0.planId != "free_registered" }
            // Sort by price (cheapest first)
            fetchedPlans.sort { ($0.priceMonthly ?? 0) < ($1.priceMonthly ?? 0) }
            await MainActor.run {
                plans = fetchedPlans
                isLoading = false
            }
        } catch {
            print("Failed to load plans: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    // MARK: - Refresh Status
    /// Manually refresh subscription status from StoreKit
    private func refreshStatus() async {
        isRefreshing = true
        
        // Sync with App Store to get latest entitlements
        try? await AppStore.sync()
        
        // Update purchased products and check for pending upgrades
        await subscriptionManager.updatePurchasedProducts()
        
        // Small delay to ensure UI updates
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        isRefreshing = false
        print("🔄 [SubscriptionView] Manual refresh completed")
    }
    
    // MARK: - Plan Cards Section
    private var planCardsSection: some View {
        VStack(spacing: 16) {
            // Find core plan for reference
            let corePlan = plans.first { $0.planId == "core" }
            // Get user's current plan for dynamic button text
            let userCurrentPlanId = quotaManager.currentPlanId ?? "free_guest"
            
            ForEach(plans) { plan in
                PlanCardWithFeatures(
                    plan: plan,
                    product: subscriptionManager.monthlyProduct(for: plan.planId),
                    isPurchasing: isPurchasing && purchasingPlanId == plan.planId,
                    isPlus: plan.planId == "plus",
                    corePlan: corePlan,
                    userCurrentPlanId: userCurrentPlanId,
                    pendingUpgradePlanId: subscriptionManager.pendingUpgradePlanId,
                    pendingUpgradeDate: subscriptionManager.pendingUpgradeEffectiveDate
                ) {
                    Task {
                        await purchaseSubscription(planId: plan.planId)
                    }
                }
            }
        }
    }
    
    // MARK: - Destiny Matching Info Section
    private var destinyMatchingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDestinyMatchingInfo.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showDestinyMatchingInfo ? "chevron.up" : "chevron.down")
                        .font(AppTheme.Fonts.title(size: 14))
                    Text("What is Destiny Matching™?")
                        .font(AppTheme.Fonts.body(size: 15))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(AppTheme.Fonts.body(size: 14))
                }
                .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            if showDestinyMatchingInfo {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Destiny Matching™ looks beyond surface-level compatibility.")
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text("While many astrology apps focus on pointing out mismatches, Destiny examines how two charts interact, where differences show up, and how alignment can be found even when things feel misaligned.")
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text("It uses astrology to help you understand and navigate relationships in context, not simply label them as good or bad.")
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding()
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(12)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Restore Button
    private var restoreButton: some View {
        Button(action: {
            Task {
                await subscriptionManager.restorePurchases()
                if quotaManager.isPremium {
                    dismiss()
                }
            }
        }) {
            Text("restore_purchases".localized)
                .font(AppTheme.Fonts.body(size: 15))
                .foregroundColor(AppTheme.Colors.gold)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Footer Disclaimers
    private var footerDisclaimers: some View {
        VStack(spacing: 8) {
            Text("Subscription automatically renews unless canceled at least 24 hours before the end of the current period.")
                .font(AppTheme.Fonts.caption(size: 11))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
            
            Text("Unlimited access is subject to fair use.")
                .font(AppTheme.Fonts.caption(size: 11))
                .italic()
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    // MARK: - Purchase Action
    private func purchaseSubscription(planId: String) async {
        guard let product = subscriptionManager.monthlyProduct(for: planId) else {
            errorMessage = "Product not available. Please try again later."
            showError = true
            return
        }
        
        isPurchasing = true
        purchasingPlanId = planId
        
        do {
            let success = try await subscriptionManager.purchase(product)
            isPurchasing = false
            purchasingPlanId = nil
            
            if success {
                dismiss()
            }
        } catch {
            isPurchasing = false
            purchasingPlanId = nil
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Plan Card with Full Feature List
struct PlanCardWithFeatures: View {
    let plan: PlanInfo
    let product: Product?
    let isPurchasing: Bool
    let isPlus: Bool
    let corePlan: PlanInfo?
    let userCurrentPlanId: String  // User's current plan for dynamic button text
    let pendingUpgradePlanId: String?  // If non-nil, user has scheduled upgrade to this plan
    let pendingUpgradeDate: Date?  // When the upgrade takes effect
    let onPurchase: () -> Void
    
    /// Features to display - DYNAMIC based on marketing_text from database
    /// Only shows features that have marketing_text (differentiators from free plan)
    private var displayFeatures: [PlanEntitlement] {
        guard let entitlements = plan.entitlements else { 
            print("[SubscriptionView] No entitlements for plan: \(plan.planId)")
            return [] 
        }
        
        print("[SubscriptionView] Plan \(plan.planId) has \(entitlements.count) entitlements")
        
        if isPlus {
            // For Plus: show only plus-exclusive features with marketing_text
            // Features that are either not in Core OR have different text (like "unlimited")
            let coreFeatureTexts = Dictionary(uniqueKeysWithValues: 
                (corePlan?.entitlements ?? []).compactMap { e -> (String, String)? in
                    guard let text = e.marketingText else { return nil }
                    return (e.featureId, text)
                }
            )
            
            let plusOnly = entitlements.filter { ent in
                // Must have marketing_text to display
                guard let text = ent.marketingText, !text.isEmpty else { return false }
                // Show if: not in core, OR has different marketing_text than core
                if let coreText = coreFeatureTexts[ent.featureId] {
                    return text != coreText  // Different text (e.g., "unlimited" vs "up to 3")
                }
                return true  // Feature not in Core at all
            }
            print("[SubscriptionView] Plus exclusive features: \(plusOnly.map { $0.featureId })")
            return plusOnly
        } else {
            // For Core: show ONLY features with marketing_text (paid differentiators)
            let filtered = entitlements.filter { ent in
                ent.marketingText != nil && !ent.marketingText!.isEmpty
            }
            print("[SubscriptionView] Core features: \(filtered.map { $0.featureId })")
            return filtered
        }
    }
    
    /// Check if this plan is the user's current plan
    private var isCurrentPlan: Bool {
        plan.planId == userCurrentPlanId
    }
    
    /// Check if user has a pending upgrade TO this plan
    private var isPendingUpgrade: Bool {
        pendingUpgradePlanId == plan.planId
    }
    
    /// Format pending upgrade date
    private var pendingUpgradeDateText: String? {
        guard let date = pendingUpgradeDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Plan Name + Price + Current Plan Badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.displayName)
                            .font(AppTheme.Fonts.title(size: 24))
                            .foregroundColor(AppTheme.Colors.gold)
                        
                        // Current Plan badge
                        if isCurrentPlan {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(AppTheme.Fonts.caption(size: 10))
                                Text("Current")
                                    .font(AppTheme.Fonts.caption(size: 10))
                            }
                            .foregroundColor(AppTheme.Colors.mainBackground)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(AppTheme.Colors.gold)
                            )
                        }
                        
                        // Pending upgrade badge (when user scheduled upgrade to this plan)
                        if isPendingUpgrade && !isCurrentPlan {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(AppTheme.Fonts.caption(size: 10))
                                Text("Scheduled")
                                    .font(AppTheme.Fonts.caption(size: 10))
                            }
                            .foregroundColor(AppTheme.Colors.mainBackground)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.orange)
                            )
                        }
                    }
                    
                    if let desc = plan.description {
                        Text(desc)
                            .font(AppTheme.Fonts.body(size: 14))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    if let product = product {
                        Text(product.displayPrice)
                            .font(AppTheme.Fonts.title(size: 20))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    } else {
                        Text("$\(String(format: "%.2f", plan.priceMonthly ?? 0))")
                            .font(AppTheme.Fonts.title(size: 20))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    Text("/ month")
                        .font(AppTheme.Fonts.caption(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            // For Plus: "Everything in Core, plus:" header
            if isPlus {
                Text("Everything in Core, plus:")
                    .font(AppTheme.Fonts.title(size: 15))
                    .foregroundColor(AppTheme.Colors.gold)
                    .padding(.top, 4)
            }
            
            // Feature List with checkmarks and descriptions
            VStack(alignment: .leading, spacing: 14) {
                ForEach(displayFeatures) { feature in
                    FeatureItemRow(feature: feature)
                }
            }
            .padding(.top, 4)
            
            // CTA Button
            Button(action: onPurchase) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.mainBackground))
                    }
                    if isCurrentPlan {
                        Image(systemName: "checkmark")
                            .font(AppTheme.Fonts.title(size: 14))
                    }
                    Text(isPurchasing ? "Processing..." : buttonText)
                        .font(AppTheme.Fonts.title(size: 16))
                }
                .foregroundColor(isCurrentPlan ? AppTheme.Colors.textSecondary : AppTheme.Colors.mainBackground)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isCurrentPlan ? AppTheme.Colors.cardBackground : AppTheme.Colors.gold)
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(isCurrentPlan ? AppTheme.Colors.gold.opacity(0.5) : Color.clear, lineWidth: 1)
                )
            }
            .disabled(isPurchasing || isCurrentPlan || isPendingUpgrade)
            .padding(.top, 8)
            
            // Show pending upgrade effective date below button
            if isPendingUpgrade, let dateText = pendingUpgradeDateText {
                Text("Starts \(dateText)")
                    .font(AppTheme.Fonts.caption(size: 12))
                    .foregroundColor(Color.orange)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrentPlan ? AppTheme.Colors.gold : AppTheme.Colors.gold.opacity(0.3), lineWidth: isCurrentPlan ? 2 : 1)
        )
    }
    
    private var priceDisplay: String {
        if let product = product {
            return "\(product.displayPrice) / month"
        }
        return "$\(String(format: "%.2f", plan.priceMonthly ?? 0)) / month"
    }
    
    /// Dynamic button text based on user's current plan
    private var buttonText: String {
        // Pending upgrade takes priority
        if isPendingUpgrade {
            return "Upgrade Scheduled ✓"
        }
        if isCurrentPlan {
            return "Current Plan"
        }
        if isPlus {
            // Plus card: "Choose Plus" for free users, "Upgrade to Plus" for Core users
            return userCurrentPlanId == "core" ? "Upgrade to Plus" : "Choose Plus"
        } else {
            // Core card: "Choose Core" for all users
            return "Choose Core"
        }
    }
}

// MARK: - Feature Item Row (Checkmark + Title + Description)
struct FeatureItemRow: View {
    let feature: PlanEntitlement
    
    /// Check if feature is "coming soon" (based on display_name_override from backend)
    private var isComingSoon: Bool {
        feature.displayName.lowercased().contains("coming soon")
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Gold checkmark
            Image(systemName: "checkmark")
                .font(AppTheme.Fonts.title(size: 14))
                .foregroundColor(AppTheme.Colors.gold)
                .frame(width: 16, height: 16)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                // Feature title (bold) with optional "(coming soon)"
                HStack(spacing: 4) {
                    Text(feature.displayName)
                        .font(AppTheme.Fonts.title(size: 15))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if isComingSoon {
                        Text("(coming soon)")
                            .font(AppTheme.Fonts.caption(size: 12))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                
                // Description below (from marketing_text)
                if let description = feature.marketingText, !description.isEmpty {
                    Text(description)
                        .font(AppTheme.Fonts.body(size: 13))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SubscriptionView()
}
