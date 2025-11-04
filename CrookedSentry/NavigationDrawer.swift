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
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "eye.fill")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    Text("Crooked Sentry")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                Text("Home Automation & Security")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
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
            
            // Footer
            VStack(spacing: 8) {
                Divider()
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Version 1.0")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("Built with ❤️")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .frame(width: 280)
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 2, y: 0)
    }
}

struct NavigationDrawerItem: View {
    let section: AppSection
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: section.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(section.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(section.subtitle)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? 
                          LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                                       startPoint: .leading, endPoint: .trailing) :
                          LinearGradient(gradient: Gradient(colors: [Color.clear, Color.clear]),
                                       startPoint: .leading, endPoint: .trailing)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.1), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
    }
}

enum AppSection: String, CaseIterable {
    case home = "home"
    case security = "security"
    case media = "media"
    case climate = "climate"
    case settings = "settings"
    
    var title: String {
        switch self {
        case .home:
            return "Home"
        case .security:
            return "CC-CC-TV"
        case .media:
            return "MC at the CC"
        case .climate:
            return "HVAC for the CC"
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
        case .settings:
            return "gearshape.fill"
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