//
//  PremiumCard.swift
//  ios_app
//
//  Created by Destiny AI.
//

import SwiftUI

enum PremiumCardStyle {
    case standard
    case hero  // Dark Navy with Faded Gold Glow + Shiny Gold Badge context
}

struct PremiumCard<Content: View>: View {
    let style: PremiumCardStyle
    let bordered: Bool
    let content: Content
    
    init(style: PremiumCardStyle = .standard, bordered: Bool = true, @ViewBuilder content: () -> Content) {
        self.style = style
        self.bordered = bordered
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(backgroundLayer)
            .overlay(glossySheen)
            .overlay(borderLayer)
            .shadow(
                color: style == .hero ? Color(red: 0.1, green: 0.1, blue: 0.2).opacity(0.5) : AppTheme.Styles.cardShadow.color,
                radius: style == .hero ? 15 : AppTheme.Styles.cardShadow.radius,
                x: 0,
                y: style == .hero ? 8 : AppTheme.Styles.cardShadow.y
            )
    }
    
    @ViewBuilder
    private var backgroundLayer: some View {
        if style == .hero {
            // ===== SHINY GRADIENT: Focus on Bottom =====
            ZStack {
                // 1. Glassmorphism Base Layer
                Color(red: 30/255, green: 34/255, blue: 50/255).opacity(0.3)
                    .background(.ultraThinMaterial)
                
                // 2. Enhanced Gradient: Brighter at bottom, darker center
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 120/255, green: 100/255, blue: 70/255).opacity(0.5), location: 0.0),   // TOP: Softer golden
                        .init(color: Color(red: 50/255, green: 50/255, blue: 55/255).opacity(0.9), location: 0.25),   // Transition to dark
                        .init(color: Color(red: 35/255, green: 38/255, blue: 50/255).opacity(0.95), location: 0.5),   // CENTER: DARKEST
                        .init(color: Color(red: 70/255, green: 60/255, blue: 45/255).opacity(0.85), location: 0.75),  // Transition
                        .init(color: Color(red: 180/255, green: 150/255, blue: 90/255).opacity(0.8), location: 1.0)   // BOTTOM: BRIGHT GOLDEN
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // 3. Extra Bottom Glow for "Shiny" effect
                RadialGradient(
                    colors: [Color(hex: "D4AF37").opacity(0.5), Color.clear],
                    center: .bottom,
                    startRadius: 0,
                    endRadius: 200
                )
            }
            .cornerRadius(20)
        } else {
            // Standard
            ZStack {
                AppTheme.Colors.cardBackground
                LinearGradient(
                    colors: [Color.white.opacity(0.03), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .cornerRadius(AppTheme.Styles.cornerRadius)
        }
    }
    
    @ViewBuilder
    private var glossySheen: some View {
        if style == .hero {
            // Stronger Glossy Sheen for "Shiny" effect
            ZStack {
                // Top-down white reflection (Glass feel)
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.white.opacity(0.25), location: 0.0),
                        .init(color: Color.white.opacity(0.05), location: 0.4),
                        .init(color: Color.clear, location: 0.6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Diagonal sheen for extra "shiny gradient" look
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .cornerRadius(16)
            .allowsHitTesting(false)
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var borderLayer: some View {
        if style == .hero {
            // Subtle Gold Border: 1.5px, rgba(200, 168, 100, 0.35)
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    Color(red: 200/255, green: 168/255, blue: 100/255).opacity(0.35),
                    lineWidth: 1.5
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.Styles.cornerRadius)
                .strokeBorder(
                    bordered ? AppTheme.Colors.gold.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        }
    }
}
