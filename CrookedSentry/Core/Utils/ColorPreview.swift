//
//  ColorPreview.swift
//  CrookedSentry
//
//  Material 3 Color Preview
//  Created by Assistant on 2025
//

import SwiftUI

struct ColorPreviewView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Primary Colors Section
                    ColorSection(title: "Primary Colors") {
                        ColorRow(name: "primary", color: .primary, textColor: .onPrimary)
                        ColorRow(name: "onPrimary", color: .onPrimary, textColor: .primary)
                        ColorRow(name: "primaryContainer", color: .primaryContainer, textColor: .onPrimaryContainer)
                        ColorRow(name: "onPrimaryContainer", color: .onPrimaryContainer, textColor: .primaryContainer)
                    }
                    
                    // Secondary Colors Section
                    ColorSection(title: "Secondary Colors") {
                        ColorRow(name: "secondary", color: .secondary, textColor: .onSecondary)
                        ColorRow(name: "onSecondary", color: .onSecondary, textColor: .secondary)
                        ColorRow(name: "secondaryContainer", color: .secondaryContainer, textColor: .onSecondaryContainer)
                        ColorRow(name: "onSecondaryContainer", color: .onSecondaryContainer, textColor: .secondaryContainer)
                    }
                    
                    // Tertiary Colors Section
                    ColorSection(title: "Tertiary Colors") {
                        ColorRow(name: "tertiary", color: .tertiary, textColor: .onTertiary)
                        ColorRow(name: "onTertiary", color: .onTertiary, textColor: .tertiary)
                        ColorRow(name: "tertiaryContainer", color: .tertiaryContainer, textColor: .onTertiaryContainer)
                        ColorRow(name: "onTertiaryContainer", color: .onTertiaryContainer, textColor: .tertiaryContainer)
                    }
                    
                    // Error Colors Section
                    ColorSection(title: "Error Colors") {
                        ColorRow(name: "error", color: .error, textColor: .onError)
                        ColorRow(name: "onError", color: .onError, textColor: .error)
                        ColorRow(name: "errorContainer", color: .errorContainer, textColor: .onErrorContainer)
                        ColorRow(name: "onErrorContainer", color: .onErrorContainer, textColor: .errorContainer)
                    }
                    
                    // Surface Colors Section
                    ColorSection(title: "Surface Colors") {
                        ColorRow(name: "background", color: .background, textColor: .onBackground)
                        ColorRow(name: "onBackground", color: .onBackground, textColor: .background)
                        ColorRow(name: "surface", color: .surface, textColor: .onSurface)
                        ColorRow(name: "onSurface", color: .onSurface, textColor: .surface)
                        ColorRow(name: "surfaceVariant", color: .surfaceVariant, textColor: .onSurfaceVariant)
                        ColorRow(name: "onSurfaceVariant", color: .onSurfaceVariant, textColor: .surfaceVariant)
                    }
                    
                    // Surface Container Colors Section
                    ColorSection(title: "Surface Container Colors") {
                        ColorRow(name: "surfaceContainerLowest", color: .surfaceContainerLowest, textColor: .onSurface)
                        ColorRow(name: "surfaceContainerLow", color: .surfaceContainerLow, textColor: .onSurface)
                        ColorRow(name: "surfaceContainer", color: .surfaceContainer, textColor: .onSurface)
                        ColorRow(name: "surfaceContainerHigh", color: .surfaceContainerHigh, textColor: .onSurface)
                        ColorRow(name: "surfaceContainerHighest", color: .surfaceContainerHighest, textColor: .onSurface)
                    }
                    
                    // Outline Colors Section
                    ColorSection(title: "Outline Colors") {
                        ColorRow(name: "outline", color: .outline, textColor: .surface)
                        ColorRow(name: "outlineVariant", color: .outlineVariant, textColor: .onSurface)
                    }
                    
                    // Inverse Colors Section
                    ColorSection(title: "Inverse Colors") {
                        ColorRow(name: "inverseSurface", color: .inverseSurface, textColor: .inverseOnSurface)
                        ColorRow(name: "inverseOnSurface", color: .inverseOnSurface, textColor: .inverseSurface)
                        ColorRow(name: "inversePrimary", color: .inversePrimary, textColor: .surface)
                    }
                }
                .padding()
            }
            .background(Color.background)
            .navigationTitle("Material 3 Colors")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ColorSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.onBackground)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                content
            }
            .padding()
            .background(Color.surfaceContainer)
            .cornerRadius(16)
        }
    }
}

struct ColorRow: View {
    let name: String
    let color: Color
    let textColor: Color
    
    var body: some View {
        HStack {
            // Color preview circle
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.outline, lineWidth: 1)
                )
            
            // Color name and usage
            VStack(alignment: .leading, spacing: 4) {
                Text(".\(name)")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(.onSurface)
                
                Text("Color.\(name)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.onSurfaceVariant)
            }
            
            Spacer()
            
            // Example text on this color
            Text("Aa")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(color)
                .cornerRadius(8)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.surface)
        .cornerRadius(12)
    }
}

// MARK: - Usage Examples
struct ColorUsageExamples: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Camera Card Example
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Front Door Camera")
                                .font(.headline)
                                .foregroundColor(.onSurface)
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.primary)
                                    .frame(width: 8, height: 8)
                                
                                Text("Live • HD")
                                    .font(.caption)
                                    .foregroundColor(.onSurfaceVariant)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "gearshape")
                                .foregroundColor(.primary)
                        }
                        .padding(8)
                        .background(Color.primaryContainer)
                        .cornerRadius(8)
                    }
                    .padding()
                    
                    // Video placeholder
                    Rectangle()
                        .fill(Color.surfaceVariant)
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay(
                            VStack {
                                Image(systemName: "video")
                                    .font(.system(size: 40))
                                    .foregroundColor(.onSurfaceVariant)
                                Text("Live Feed")
                                    .foregroundColor(.onSurfaceVariant)
                            }
                        )
                }
                .background(Color.surface)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.outline, lineWidth: 1)
                )
                
                // Settings Card Example
                VStack(alignment: .leading, spacing: 16) {
                    Text("Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.onSurface)
                    
                    VStack(spacing: 12) {
                        SettingsRow(icon: "camera", title: "Camera Settings", color: .primary)
                        SettingsRow(icon: "bell", title: "Notifications", color: .secondary)
                        SettingsRow(icon: "gear", title: "General", color: .tertiary)
                    }
                }
                .padding()
                .background(Color.surfaceContainer)
                .cornerRadius(16)
            }
            .padding()
        }
        .background(Color.background)
        .navigationTitle("Usage Examples")
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            Text(title)
                .foregroundColor(.onSurface)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.onSurfaceVariant)
                .font(.caption)
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }
}

#Preview("Color Preview") {
    ColorPreviewView()
}

#Preview("Usage Examples") {
    NavigationView {
        ColorUsageExamples()
    }
}