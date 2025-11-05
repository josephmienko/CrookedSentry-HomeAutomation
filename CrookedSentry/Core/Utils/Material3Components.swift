//
//  Material3Components.swift
//  CrookedSentry
//
//  Material 3 Button Components
//  Created by Assistant on 2025
//

import SwiftUI

// MARK: - Material 3 Hamburger Button
struct M3HamburgerButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.onSecondaryContainer)
                .frame(width: 24, height: 24)
                .padding(16) // Creates 56x56 total button area (24 + 16*2)
                .background(
                    // State layer for hover/press
                    RoundedRectangle(cornerRadius: 28) // Full radius for pill shape
                        .fill(Color.onSecondaryContainer.opacity(isPressed ? 0.1 : 0.0))
                        .frame(width: 56, height: 56)
                )
                .background(
                    // Base container
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.secondaryContainer)
                        .frame(width: 56, height: 56)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Material 3 App Title Button
struct M3AppTitleButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.onSurface)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    // State layer for hover/press
                    Capsule()
                        .fill(Color.onSurface.opacity(isPressed ? 0.1 : 0.0))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Combined Top Navigation Bar
struct M3TopNavigationBar: View {
    let onMenuTap: () -> Void
    let onTitleTap: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Hamburger button
            M3HamburgerButton(action: onMenuTap)
            
            // 32px spacing as specified (8px margin + 24px for label's hover state)
            Spacer()
                .frame(width: 32)
            
            // App title button
            M3AppTitleButton(title: "Crooked Sentry", action: onTitleTap)
            
            Spacer()
        }
        .padding(.horizontal, 8) // Overall 8px margin
        .frame(height: 72) // Height as specified
        .background(Color.surface)
    }
}

// MARK: - Theme Aware Logo
struct ThemeAwareLogo: View {
    var body: some View {
        // CrookedSentryIcon automatically switches between light/dark variants
        Image("CrookedSentryIcon")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

// MARK: - Usage Example
struct M3TopNavigationBar_Preview: PreviewProvider {
    static var previews: some View {
        VStack {
            M3TopNavigationBar(
                onMenuTap: {
                    print("Menu tapped")
                },
                onTitleTap: {
                    print("Title tapped - navigate to home")
                }
            )
            
            Spacer()
        }
        .background(Color.background)
    }
}