import SwiftUI
import StoreKit

/// Subscription screen using native StoreKit 2 (iOS 17+)
struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Custom header
                    headerSection
                    
                    // Features list
                    featuresSection
                    
                    // Pricing card
                    pricingCard
                    
                    // Subscribe button
                    subscribeButton
                    
                    // Restore purchases
                    restoreButton
                    
                    // Disclaimer
                    disclaimerText
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
                .padding(.bottom, 40)
            }
            .background(AppTheme.Colors.mainBackground.ignoresSafeArea())
            .navigationTitle("Premium")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                #endif
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }

    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Crown icon
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.premiumGradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: AppTheme.Colors.gold.opacity(0.4), radius: 15, y: 5)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: "0B0F19"))
            }
            
            VStack(spacing: 8) {
                Text("unlock_premium".localized)
                    .font(AppTheme.Fonts.display(size: 26))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("get_cosmic_guidance".localized)
                    .font(AppTheme.Fonts.body(size: 16))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: 16) {
            FeatureRow(icon: "infinity", title: "Unlimited Questions", description: "Ask as many questions as you want")
            FeatureRow(icon: "heart.fill", title: "Unlimited Matches", description: "Compare unlimited birth charts")
            FeatureRow(icon: "chart.pie.fill", title: "Advanced Charts", description: "Detailed planetary analysis")
            FeatureRow(icon: "sparkles", title: "Priority Responses", description: "Faster, more detailed answers")
        }
        .padding(20)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.Colors.gold.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, y: 4)
    }
    
    // MARK: - Pricing Card
    private var pricingCard: some View {
        VStack(spacing: 12) {
            if let product = subscriptionManager.monthlyProduct {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(product.displayPrice)
                        .font(AppTheme.Fonts.display(size: 36))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("/ month")
                        .font(AppTheme.Fonts.body(size: 16))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$4.99")
                        .font(AppTheme.Fonts.display(size: 36))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("/ month")
                        .font(AppTheme.Fonts.body(size: 16))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Text("cancel_anytime".localized)
                .font(AppTheme.Fonts.caption(size: 14))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Subscribe Button
    private var subscribeButton: some View {
        Button(action: {
            Task {
                await purchaseSubscription()
            }
        }) {
            HStack(spacing: 10) {
                if isPurchasing || subscriptionManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "0B0F19")))
                } else {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                }
                Text(isPurchasing ? "Processing..." : "Subscribe Now")
                    .font(AppTheme.Fonts.title(size: 17))
            }
            .foregroundColor(Color(hex: "0B0F19"))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppTheme.Colors.premiumGradient)
            .cornerRadius(16)
            .shadow(color: AppTheme.Colors.gold.opacity(0.3), radius: 10, y: 5)
        }
        .disabled(isPurchasing || subscriptionManager.isLoading)
    }
    
    // MARK: - Restore Button
    private var restoreButton: some View {
        Button(action: {
            Task {
                await subscriptionManager.restorePurchases()
                if subscriptionManager.isPremium {
                    dismiss()
                }
            }
        }) {
            Text("restore_purchases".localized)
                .font(AppTheme.Fonts.body(size: 15))
                .foregroundColor(AppTheme.Colors.gold)
        }
    }
    
    // MARK: - Disclaimer
    private var disclaimerText: some View {
        Text("subscription_terms".localized)
            .font(AppTheme.Fonts.caption(size: 11))
            .foregroundColor(AppTheme.Colors.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
    }
    
    // MARK: - Purchase Action
    private func purchaseSubscription() async {
        guard let product = subscriptionManager.monthlyProduct else {
            errorMessage = "Product not available"
            showError = true
            return
        }
        
        isPurchasing = true
        
        do {
            let success = try await subscriptionManager.purchase(product)
            isPurchasing = false
            
            if success {
                dismiss()
            }
        } catch {
            isPurchasing = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.gold.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.Colors.gold)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Fonts.title(size: 15))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(description)
                    .font(AppTheme.Fonts.body(size: 13))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(Color.green)
        }
    }
}

// MARK: - Preview
#Preview {
    SubscriptionView()
}
