//
//  NavigationDrawer.swift
//  Crooked Sentry
//
//  Created by Assistant on 2025
//

import SwiftUI

struct NavigationDrawer: View {
    @Binding var selectedSection: AppSection
    @Binding var isDrawerOpen: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 16) {
                Text("Crooked Sentry")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer(minLength: 8)
                
                ThemeAwareLogo()
                    .frame(width: 48, height: 48)
            }
            .padding()
            
            // Navigation Items
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(AppSection.allCases, id: \.self) { section in
                        NavigationDrawerItem(
                            title: section.title,
                            isSelected: selectedSection == section
                        ) {
                            selectedSection = section
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                isDrawerOpen = false
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
            
            // VPN Status (if feature enabled)
            if VPNFeatureFlags.showVPNStatusInDrawer {
                VPNStatusIndicator()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
            
            // Utility Controls
            HStack(spacing: 12) {
                // Theme toggle pill
                Button(action: {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        let isDark = windowScene.windows.first?.overrideUserInterfaceStyle == .dark
                        windowScene.windows.first?.overrideUserInterfaceStyle = isDark ? .light : .dark
                    }
                }) {
                    Image(systemName: colorScheme == .dark ? "moon.fill" : "sun.max.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.onSurfaceVariant)
                        .frame(width: 44, height: 44)
                }
                .background(Color.surfaceContainerHigh)
                .clipShape(Circle())
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // Footer
            VStack(spacing: 8) {
                Divider()
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.onSurfaceVariant)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Made with 🤗 and ♥️ by GI Joe 🪖")
                            .font(.caption2)
                            .foregroundColor(.onSurfaceVariant)                                                     
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .frame(width: 280)
        .background(Color.surface)
        .shadow(color: Color.shadow.opacity(0.1), radius: 10, x: 2, y: 0)
    }
}

struct NavigationDrawerItem: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .onSecondaryContainer : .onSurfaceVariant)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(isSelected ? Color.secondaryContainer : Color.clear)
            )
        }
        .padding(.horizontal, 12)
    }
}

enum AppSection: String, CaseIterable {
    case home = "home"
    case security = "security"
    case media = "media"
    case climate = "climate"
    case uv = "uv"
    case settings = "settings"
    
    var title: String {
        switch self {
        case .home:
            return "The CC"
        case .security:
            return "CCTV @ the CC"
        case .media:
            return "MC @ the CC"
        case .climate:
            return "HVAC @ the CC"
        case .uv:
            return "UV @ the CC"
        case .settings:
            return "Settings"
        }
    }
    
    var subtitle: String {
        switch self {
        case .home:
            return "Dashboard & Overview"
        case .security:
            return "Security & Surveillance"
        case .media:
            return "TV & Entertainment"
        case .climate:
            return "Climate & Comfort"
        case .uv:
            return "UV Monitoring & Control"
        case .settings:
            return "Configuration & Preferences"
        }
    }
    
    var icon: String {
        switch self {
        case .home:
            return "house.fill"
        case .security:
            return "video.fill"
        case .media:
            return "tv.fill"
        case .climate:
            return "thermometer"
        case .uv:
            return "sun.max.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
}

struct ThemeSwitcher: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var isDarkMode: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Theme label
            HStack(spacing: 8) {
                Image(systemName: "paintbrush.fill")
                    .foregroundColor(.onSurfaceVariant)
                    .font(.caption)
                
                Text("Theme")
                    .font(.caption)
                    .foregroundColor(.onSurfaceVariant)
            }
            
            Spacer()
            
            // Theme toggle
            HStack(spacing: 4) {
                // Light mode indicator
                Image(systemName: "sun.max.fill")
                    .foregroundColor(isDarkMode ? .onSurfaceVariant.opacity(0.5) : .tertiary)
                    .font(.caption)
                
                // Toggle switch
                Toggle("", isOn: $isDarkMode)
                    .toggleStyle(SwitchToggleStyle(tint: .primary))
                    .scaleEffect(0.8)
                    .onChange(of: isDarkMode) { _, newValue in
                        // Force the interface style change
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            windowScene.windows.first?.overrideUserInterfaceStyle = newValue ? .dark : .light
                        }
                    }
                
                // Dark mode indicator
                Image(systemName: "moon.fill")
                    .foregroundColor(isDarkMode ? .primary : .onSurfaceVariant.opacity(0.5))
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.surfaceContainer)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.outline.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            // Initialize with current color scheme
            isDarkMode = colorScheme == .dark
        }
        .onChange(of: colorScheme) { _, newColorScheme in
            // Update toggle when system theme changes
            isDarkMode = newColorScheme == .dark
        }
    }
}

// Preview
struct NavigationDrawer_Previews: PreviewProvider {
    static var previews: some View {
        NavigationDrawer(
            selectedSection: .constant(.home),
            isDrawerOpen: .constant(true)
        )
        .previewLayout(.sizeThatFits)
    }
}
