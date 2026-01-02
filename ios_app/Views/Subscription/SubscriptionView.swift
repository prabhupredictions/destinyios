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
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.94, blue: 0.96),
                        Color(red: 0.96, green: 0.95, blue: 0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
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
                            .foregroundColor(Color("NavyPrimary").opacity(0.5))
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                #endif
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Crown icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("GoldAccent"), Color("GoldAccent").opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color("GoldAccent").opacity(0.4), radius: 15, y: 5)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("unlock_premium".localized)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color("NavyPrimary"))
                
                Text("get_cosmic_guidance".localized)
                    .font(.system(size: 16))
                    .foregroundColor(Color("TextDark").opacity(0.6))
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
        )
    }
    
    // MARK: - Pricing Card
    private var pricingCard: some View {
        VStack(spacing: 12) {
            if let product = subscriptionManager.monthlyProduct {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color("NavyPrimary"))
                    
                    Text("/ month")
                        .font(.system(size: 16))
                        .foregroundColor(Color("TextDark").opacity(0.6))
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$4.99")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color("NavyPrimary"))
                    
                    Text("/ month")
                        .font(.system(size: 16))
                        .foregroundColor(Color("TextDark").opacity(0.6))
                }
            }
            
            Text("cancel_anytime".localized)
                .font(.system(size: 14))
                .foregroundColor(Color("TextDark").opacity(0.5))
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
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                }
                Text(isPurchasing ? "Processing..." : "Subscribe Now")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color("NavyPrimary"), Color("NavyPrimary").opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color("NavyPrimary").opacity(0.3), radius: 10, y: 5)
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
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color("NavyPrimary"))
        }
    }
    
    // MARK: - Disclaimer
    private var disclaimerText: some View {
        Text("subscription_terms".localized)
            .font(.system(size: 11))
            .foregroundColor(Color("TextDark").opacity(0.4))
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
                    .fill(Color("GoldAccent").opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color("GoldAccent"))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color("NavyPrimary"))
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(Color("TextDark").opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
        }
    }
}

// MARK: - Preview
#Preview {
    SubscriptionView()
}
