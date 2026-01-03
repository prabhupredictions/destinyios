//
//  PremiumCloseButton.swift
//  ios_app
//
//  Created by Destiny AI.
//

import SwiftUI

struct PremiumCloseButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.play(.light)
            action()
        }) {
            Circle()
                .fill(AppTheme.Colors.secondaryBackground)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.gold)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.mainBackground
        PremiumCloseButton(action: {})
    }
}
