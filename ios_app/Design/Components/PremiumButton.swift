//
//  PremiumButton.swift
//  ios_app
//
//  Created by Destiny AI.
//

import SwiftUI

struct PremiumButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.play(.medium)
            action()
        }) {
            ZStack {
                AppTheme.Colors.premiumGradient
                
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(.black)
                    } else {
                        if let icon = icon {
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .semibold))
                        }
                        
                        Text(title)
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundColor(Color(hex: "0B0F19")) // Dark Navy text on Gold
            }
            .frame(height: 56)
            .cornerRadius(16) // Slightly tighter than cards
            .shadow(color: AppTheme.Colors.gold.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(isLoading ? 0.98 : 1.0)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isLoading)
    }
}

// Micro-interaction: Scale on press
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { pressed in
                if pressed {
                    HapticManager.shared.play(.light)
                }
            }
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.mainBackground.ignoresSafeArea()
        VStack {
            PremiumButton("Analyze Chart", icon: "sparkles", action: {})
            PremiumButton("Processing...", isLoading: true, action: {})
        }
        .padding()
    }
}
