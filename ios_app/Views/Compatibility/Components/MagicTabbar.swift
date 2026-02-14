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
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tiles) { tile in
                        tabButton(tile, proxy: proxy)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            .background(Color.clear) // Removed inner shadow background
            .padding(.vertical, 2)
            .background(Color.clear) // 100% Transparent - Removed Capsule & Stroke
        }
    }
    
    @ViewBuilder
    private func tabButton(_ tile: DestinyTileType, proxy: ScrollViewProxy) -> some View {
        let isSelected = selectedTab == tile
        let count = counts[tile] ?? 0
        
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = tile
                proxy.scrollTo(tile.id, anchor: .center)
            }
            // Haptic feedback
            HapticManager.shared.play(.light)
        } label: {
            VStack(spacing: 4) {
                // Icon - Glowing when selected
                Text(tile.icon)
                    .font(.system(size: isSelected ? 26 : 22))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .shadow(color: isSelected ? tile.accentColor.opacity(0.8) : .clear, radius: 8, x: 0, y: 0)
                
                Text(tile.rawValue)
                    .font(AppTheme.Fonts.caption(size: 11).weight(isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.textSecondary) // White text for selected
                
                if count > 0 {
                    Text("\(count)")
                        .font(AppTheme.Fonts.caption(size: 9).weight(.bold))
                        .foregroundColor(isSelected ? tile.accentColor : AppTheme.Colors.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? tile.accentColor.opacity(0.2) : Color.clear)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        ZStack {
                            // 1. Glassy Jewel Base
                            Capsule()
                                .fill(tile.accentColor.opacity(0.15))
                            
                            // 2. Border Gradient
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            tile.accentColor.opacity(0.8),
                                            tile.accentColor.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                            
                            // 3. Specular Note (Top Shine)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )
                                .padding(.horizontal, 6)
                                .padding(.top, 2)
                                .padding(.bottom, 15)
                        }
                        .matchedGeometryEffect(id: "TAB_INDICATOR", in: animation)
                        .shadow(color: tile.accentColor.opacity(0.3), radius: 8, y: 4)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .id(tile.id)
    }
}

/// A premium sliding toggle for switching between partners
struct ProfileSwitcher: View {
    @Binding var selectedIndex: Int
    let names: [String]
    
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(names.indices, id: \.self) { index in
                profileButton(index: index, name: names[index])
            }
        }
        .padding(2)

        .background(Color.clear) // 100% Transparent
        // Removed overlay stroke for clean look
    }
    
    @ViewBuilder
    private func profileButton(index: Int, name: String) -> some View {
        let isSelected = selectedIndex == index
        
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedIndex = index
            }
            HapticManager.shared.play(.medium)
        } label: {
            Text(name)
                .font(AppTheme.Fonts.caption(size: 13).weight(isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? AppTheme.Colors.mainBackground : AppTheme.Colors.textSecondary)
                .lineLimit(1)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isSelected {
                        ZStack {
                            // 1. Jewel Base
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AppTheme.Colors.gold,
                                            AppTheme.Colors.gold.opacity(0.7)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            // 2. Glossy Shine (Top Highlight)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )
                                .padding(.horizontal, 4)
                                .padding(.top, 2)
                                .padding(.bottom, 12) // Fade out quickly
                        }
                        .matchedGeometryEffect(id: "PROFILE_INDICATOR", in: animation)
                        .shadow(color: AppTheme.Colors.gold.opacity(0.5), radius: 8, y: 2)
                    }
                }
            )
        }
        .buttonStyle(.plain)
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
