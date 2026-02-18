//
//  MagicTabbar.swift
//  ios_app
//
//  Premium animated horizontal tab bar for topic navigation
//

import SwiftUI

/// A premium horizontal scrollable tab bar with sliding indicator animation
struct MagicTabbar: View {
    @Binding var selectedTab: DestinyTileType
    let tiles: [DestinyTileType]
    let counts: [DestinyTileType: Int]
    
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(tiles) { tile in
                tabButton(tile)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4) // Reduced from 8
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private func tabButton(_ tile: DestinyTileType) -> some View {
        let isSelected = selectedTab == tile
        let count = counts[tile] ?? 0
        
        Button {
            withAnimation(.easeOut(duration: 0.3)) {
                selectedTab = tile
            }
            HapticManager.shared.play(.light)
        } label: {
            VStack(spacing: 4) {
                // Icon
                Image(isSelected ? tile.activeIconImage : tile.inactiveIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .scaleEffect(isSelected ? 1.12 : 1.0)
                
                // Label
                Text(tile.rawValue.uppercased())
                    .font(.system(size: 9, weight: isSelected ? .semibold : .medium))
                    .tracking(0.5)
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.textSecondary)
                
                // Active indicator dot
                Circle()
                    .fill(isSelected ? tile.accentColor : Color.clear)
                    .frame(width: 3, height: 3)
                    .shadow(color: isSelected ? tile.accentColor.opacity(0.6) : .clear, radius: 6, x: 0, y: 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .padding(.horizontal, 2)
            .padding(.bottom, 6)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.07))
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .id(tile.id)
    }
}

/// A premium cosmic toggle switch for switching between partners
/// iOS-style sliding pill with gold accent and hint text
struct ProfileSwitcher: View {
    @Binding var selectedIndex: Int
    let names: [String]
    
    @Namespace private var animation
    
    var body: some View {
        VStack(spacing: 8) {
            // Toggle Switch
            HStack(spacing: 4) {
                ForEach(names.indices, id: \.self) { index in
                    toggleButton(index: index, name: names[index])
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
        }
    }
    
    @ViewBuilder
    private func toggleButton(index: Int, name: String) -> some View {
        let isSelected = selectedIndex == index
        let firstName = getFirstName(from: name)
        
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedIndex = index
            }
            HapticManager.shared.play(.medium)
        } label: {
            Text(firstName)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? 
                    AppTheme.Colors.mainBackground : 
                    AppTheme.Colors.textSecondary
                )
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AppTheme.Colors.gold,
                                            AppTheme.Colors.gold.opacity(0.85)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(
                                    color: AppTheme.Colors.gold.opacity(0.5),
                                    radius: 12,
                                    x: 0,
                                    y: 4
                                )
                                .matchedGeometryEffect(id: "activeTab", in: animation)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
    
    /// Get first name from full name
    private func getFirstName(from name: String) -> String {
        String(name.split(separator: " ").first ?? Substring(name))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        CosmicBackgroundView()
            .ignoresSafeArea()
        
        VStack(spacing: 24) {
            ProfileSwitcher(
                selectedIndex: .constant(0),
                names: ["Prabhu", "Smita"]
            )
            .padding(.horizontal)
            
            MagicTabbar(
                selectedTab: .constant(.wealth),
                tiles: DestinyTileType.topicTiles,
                counts: [.wealth: 5, .career: 3, .love: 2, .family: 1, .wisdom: 4, .health: 2]
            )
            
            Spacer()
        }
        .padding(.top)
    }
}
