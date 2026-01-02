//
//  TransitCapsule.swift
//  ios_app
//
//  Created by Destiny AI.
//

import SwiftUI

struct TransitCapsule: View {
    let planet: String
    let sign: String
    
    // Map Planet Short Code to Full Name
    private var planetName: String {
        let map: [String: String] = [
            "Su": "Sun", "Mo": "Moon", "Ma": "Mars", "Me": "Mercury",
            "Ju": "Jupiter", "Ve": "Venus", "Sa": "Saturn", "Ra": "Rahu", "Ke": "Ketu"
        ]
        return map[planet] ?? planet
    }
    
    // Map Sign Short Code to Full Name
    private var signName: String {
        let map: [String: String] = [
            "Ar": "Aries", "Ta": "Taurus", "Ge": "Gemini", "Cn": "Cancer",
            "Le": "Leo", "Vi": "Virgo", "Li": "Libra", "Sc": "Scorpio",
            "Sg": "Sagittarius", "Cp": "Capricorn", "Aq": "Aquarius", "Pi": "Pisces"
        ]
        return map[sign] ?? sign
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Planet Circle
            ZStack {
                Circle()
                    .fill(Color(hex: "FDD835")) // Gold
                    .frame(width: 32, height: 32)
                    .shadow(color: Color(hex: "FDD835").opacity(0.4), radius: 4)
                
                Text(planet.prefix(2))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "1A1208"))
            }
            
            // Arrow
            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.white.opacity(0.4))
            
            // Sign Text
            Text(sign)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.white.opacity(0.9))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "1A1F2E")) // Dark Navy
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
