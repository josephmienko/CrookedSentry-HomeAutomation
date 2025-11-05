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
                            section: section,
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
            
            // Theme Switcher
            ThemeSwitcher()
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            // Footer
            VStack(spacing: 8) {
                Divider()
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.onSurfaceVariant)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("For Laura 🤗, with ♥️, from GI Joe")
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
    let section: AppSection
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: section.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .onSecondaryContainer : .onSurface)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(section.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? .onSecondaryContainer : .onSurface)
                    
                    Text(section.subtitle)
                        .font(.caption)
                        .foregroundColor(isSelected ? .onSecondaryContainer.opacity(0.8) : .onSurfaceVariant)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.onSecondaryContainer.opacity(0.8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                // Persistent tonal fill for active page (pill shaped)
                Capsule()
                    .fill(isSelected ? Color.outlineVariant : Color.clear)
            )
            .background(
                // Hover state layer (pill shaped)
                Capsule()
                    .fill(Color.onSurface.opacity(isPressed && !isSelected ? 0.1 : 0.0))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .padding(.horizontal, 16)
    }
}

enum AppSection: String, CaseIterable {
    case home = "home"
    case security = "security"
    case media = "media"
    case climate = "climate"
    case uv = "uv"  // New UV section
    case network = "network"  // New VPN/Network section
    case settings = "settings"
    #if DEBUG
    case debug = "debug"  // Debug section for development builds
    #endif
    
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
        case .network:
            return "Secure Access"
        case .settings:
            return "Settings"
        #if DEBUG
        case .debug:
            return "Debug & Testing"
        #endif
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
        case .network:
            return "VPN & Network Security"
        case .settings:
            return "Configuration & Preferences"
        #if DEBUG
        case .debug:
            return "Developer Tools & Material 3 Colors"
        #endif
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
        case .network:
            return "lock.shield.fill"
        case .settings:
            return "gearshape.fill"
        #if DEBUG
        case .debug:
            return "hammer.fill"
        #endif
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
