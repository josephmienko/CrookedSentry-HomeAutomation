//
//  Material3ColorTest.swift
//  CrookedSentry
//
//  Material 3 Color System Test
//  Created by Assistant on 2025
//

import SwiftUI

/// Test view to verify Material 3 colors are working properly
struct Material3ColorTest: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Test Primary Colors
                ColorTestSection(title: "Primary Colors") {
                    ColorTestCard(
                        backgroundColor: Color.primaryContainer,
                        textColor: Color.onPrimaryContainer,
                        text: "Primary Container"
                    )
                    
                    ColorTestCard(
                        backgroundColor: Color.primary,
                        textColor: Color.onPrimary,
                        text: "Primary"
                    )
                }
                
                // Test Secondary Colors
                ColorTestSection(title: "Secondary Colors") {
                    ColorTestCard(
                        backgroundColor: Color.secondaryContainer,
                        textColor: Color.onSecondaryContainer,
                        text: "Secondary Container"
                    )
                    
                    ColorTestCard(
                        backgroundColor: Color.secondary,
                        textColor: Color.onSecondary,
                        text: "Secondary"
                    )
                }
                
                // Test Tertiary Colors
                ColorTestSection(title: "Tertiary Colors") {
                    ColorTestCard(
                        backgroundColor: Color.tertiaryContainer,
                        textColor: Color.onTertiaryContainer,
                        text: "Tertiary Container"
                    )
                    
                    ColorTestCard(
                        backgroundColor: Color.tertiary,
                        textColor: Color.onTertiary,
                        text: "Tertiary"
                    )
                }
                
                // Test Error Colors
                ColorTestSection(title: "Error Colors") {
                    ColorTestCard(
                        backgroundColor: Color.errorContainer,
                        textColor: Color.onErrorContainer,
                        text: "Error Container"
                    )
                    
                    ColorTestCard(
                        backgroundColor: Color.error,
                        textColor: Color.onError,
                        text: "Error"
                    )
                }
                
                // Test Surface Colors
                ColorTestSection(title: "Surface Colors") {
                    ColorTestCard(
                        backgroundColor: Color.surface,
                        textColor: Color.onSurface,
                        text: "Surface"
                    )
                    
                    ColorTestCard(
                        backgroundColor: Color.surfaceContainer,
                        textColor: Color.onSurface,
                        text: "Surface Container"
                    )
                    
                    ColorTestCard(
                        backgroundColor: Color.surfaceContainerHigh,
                        textColor: Color.onSurface,
                        text: "Surface Container High"
                    )
                }
                
                // Quick Action Cards Test (like in HomeView)
                ColorTestSection(title: "Quick Actions Test") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        QuickActionTestCard(
                            title: "Lights",
                            icon: "lightbulb.slash",
                            backgroundColor: Color.tertiaryContainer,
                            textColor: Color.onTertiaryContainer
                        )
                        
                        QuickActionTestCard(
                            title: "Movie",
                            icon: "tv",
                            backgroundColor: Color.secondaryContainer,
                            textColor: Color.onSecondaryContainer
                        )
                        
                        QuickActionTestCard(
                            title: "Sleep",
                            icon: "moon.fill",
                            backgroundColor: Color.primaryContainer,
                            textColor: Color.onPrimaryContainer
                        )
                        
                        QuickActionTestCard(
                            title: "Away",
                            icon: "location.slash",
                            backgroundColor: Color.errorContainer,
                            textColor: Color.onErrorContainer
                        )
                    }
                }
            }
            .padding()
        }
        .background(Color.background)
        .navigationTitle("Material 3 Color Test")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ColorTestSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.onSurface)
                .padding(.horizontal)
            
            content
                .padding()
                .background(Color.surfaceContainer)
                .cornerRadius(16)
        }
    }
}

struct ColorTestCard: View {
    let backgroundColor: Color
    let textColor: Color
    let text: String
    
    var body: some View {
        Text(text)
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(textColor)
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(12)
    }
}

struct QuickActionTestCard: View {
    let title: String
    let icon: String
    let backgroundColor: Color
    let textColor: Color
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            print("Tapped: \(title)")
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .overlay(
                        // Material 3 state layer for press feedback
                        RoundedRectangle(cornerRadius: 12)
                            .fill(textColor.opacity(isPressed ? 0.1 : 0.0))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Preview
#Preview("Material 3 Test Light") {
    NavigationView {
        Material3ColorTest()
            .preferredColorScheme(.light)
    }
}

#Preview("Material 3 Test Dark") {
    NavigationView {
        Material3ColorTest()
            .preferredColorScheme(.dark)
    }
}