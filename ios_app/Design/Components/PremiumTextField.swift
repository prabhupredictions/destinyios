//
//  PremiumTextField.swift
//  ios_app
//
//  Created by Destiny AI.
//

import SwiftUI

struct PremiumTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String?
    let isSecure: Bool
    
    @FocusState private var isFocused: Bool
    
    init(_ title: String, text: Binding<String>, placeholder: String = "", icon: String? = nil, isSecure: Bool = false) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.isSecure = isSecure
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(AppTheme.Fonts.body(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(isFocused ? AppTheme.Colors.gold : AppTheme.Colors.textTertiary)
                        .font(.system(size: 16))
                }
                
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .foregroundColor(AppTheme.Colors.textPrimary)
                .accentColor(AppTheme.Colors.gold)
                .focused($isFocused)
            }
            .padding(.horizontal, 16)
            .frame(height: AppTheme.Styles.inputHeight)
            .background(AppTheme.Colors.inputBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isFocused ? AppTheme.Colors.gold.opacity(0.5) : AppTheme.Colors.gold.opacity(0.15),
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.mainBackground.ignoresSafeArea()
        VStack(spacing: 20) {
            PremiumTextField("Email Address", text: .constant(""), placeholder: "star.gazer@cosmos.com", icon: "envelope")
            PremiumTextField("Password", text: .constant("password"), icon: "lock", isSecure: true)
        }
        .padding()
    }
}
