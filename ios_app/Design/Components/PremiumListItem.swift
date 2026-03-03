//
//  PremiumListItem.swift
//  ios_app
//
//  Created by Destiny AI.
//

import SwiftUI

struct PremiumListItem<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let showChevron: Bool
    let isPremiumFeature: Bool  // Shows crown badge for premium features
    let premiumBadgeText: String  // Customizable badge text (e.g., "Plus", "Core")
    let premiumBadgeColor: Color  // Green if unlocked, gold if locked
    let trailingContent: Content?
    let action: (() -> Void)?
    
    init(title: String, subtitle: String? = nil, icon: String? = nil, showChevron: Bool = true, isPremiumFeature: Bool = false, premiumBadgeText: String = "Plus", premiumBadgeColor: Color = AppTheme.Colors.gold, action: (() -> Void)? = nil, @ViewBuilder trailing: () -> Content = { EmptyView() }) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.showChevron = showChevron
        self.isPremiumFeature = isPremiumFeature
        self.premiumBadgeText = premiumBadgeText
        self.premiumBadgeColor = premiumBadgeColor
        self.action = action
        self.trailingContent = trailing()
    }
    
    var body: some View {
        if let action = action {
            Button(action: {
                HapticManager.shared.play(.light)
                action()
            }) {
                contentView
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            contentView
        }
    }
    
    private var contentView: some View {
        HStack(spacing: 16) {
            if let icon = icon {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.cardBackground)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.Colors.gold.opacity(0.15), lineWidth: 1)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.Colors.gold)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Fonts.body(size: 16))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTheme.Fonts.body(size: 13))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            if let trailingContent = trailingContent {
                trailingContent
            }
            
            // Premium badge for premium features (green = unlocked, gold = locked)
            if isPremiumFeature {
                HStack(spacing: 3) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10))
                    Text(premiumBadgeText)
                        .font(AppTheme.Fonts.caption(size: 10))
                }
                .foregroundColor(premiumBadgeColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(premiumBadgeColor.opacity(0.15))
                )
            }
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding(16)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(16)
        .overlay(
             RoundedRectangle(cornerRadius: 16)
                 .stroke(AppTheme.Colors.gold.opacity(0.05), lineWidth: 1)
        )
        // Ensure content is opaque/tappable
        .contentShape(Rectangle()) 
    }
}
