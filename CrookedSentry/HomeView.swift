//
//  HomeView.swift
//  Crooked Sentry
//
//  Created by Assistant on 2025
//

import SwiftUI
import Combine
import UIKit

struct HomeView: View {
    let events: [FrigateEvent]
    let inProgressEvents: [FrigateEvent]
    // Navigate to different app sections (e.g., CCTV/Security, Climate/HVAC) with optional Security tab
    let onNavigateToSection: (AppSection, SecurityTab?) -> Void
    
    @EnvironmentObject var settingsStore: SettingsStore
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Welcome Header
                welcomeHeader
                
                // Quick Stats Cards
                quickStatsSection
                
                // Recent Activity
                recentActivitySection
            }
            .padding()
        }
        .background(Color.background)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingWithName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(currentTime.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.onSurfaceVariant)
                }
                
                Spacer()
                
                Image("CrookedSentryIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.surfaceContainer)
            )
        }
    }
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                QuickStatCard(
                    title: "Events",
                    value: "\(events.count)",
                    subtitle: events.isEmpty ? "None loaded" : "Available",
                    icon: "video.circle.fill",
                    color: events.isEmpty ? Color.error : Color.primary,
                    onTap: { onNavigateToSection(.security, .events) }
                )
                
                QuickStatCard(
                    title: "Live Feed",
                    value: "2",
                    subtitle: "Active",
                    icon: "video.fill",
                    color: .primary,
                    onTap: { onNavigateToSection(.security, .live) }
                )
                
                QuickStatCard(
                    title: "Inside",
                    value: "72°F",
                    subtitle: "Comfortable",
                    icon: "thermometer",
                    color: .secondary,
                    onTap: { onNavigateToSection(.climate, nil) }
                )
                
                WeatherOutsideCard()
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.onSurface)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                QuickActionCard(
                    title: "All Lights Off",
                    icon: "lightbulb.slash",
                    color: Color.tertiaryContainer,
                    textColor: Color.onTertiaryContainer
                ) {
                    // Action for lights off
                }
                
                QuickActionCard(
                    title: "Movie Mode", 
                    icon: "tv",
                    color: Color.secondaryContainer,
                    textColor: Color.onSecondaryContainer
                ) {
                    // Action for movie mode
                }
                
                QuickActionCard(
                    title: "Good Night",
                    icon: "moon.fill",
                    color: Color.primaryContainer,
                    textColor: Color.onPrimaryContainer
                ) {
                    // Action for good night
                }
                
                QuickActionCard(
                    title: "Away Mode",
                    icon: "location.slash",
                    color: Color.errorContainer,
                    textColor: Color.onErrorContainer
                ) {
                    // Action for away mode
                }
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.onSurface)
                
                Spacer()
                
                // Debug button when no events are loaded
                if events.isEmpty {
                    Button(action: {
                        Task {
                            print("🔍 Starting Events Debug...")
                            await EventsDebugHelper.testEventAPIConnectivity(baseURL: settingsStore.frigateBaseURL)
                            await EventsDebugHelper.testEventsParsing(baseURL: settingsStore.frigateBaseURL)
                            EventsDebugHelper.checkAppSettings()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "wrench.and.screwdriver")
                            Text("Debug")
                        }
                        .font(.caption)
                        .foregroundColor(.tertiary)
                    }
                }
            }
            
            if events.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(.tertiary)
                    
                    Text("No events loaded")
                        .font(.body)
                        .foregroundColor(.onSurfaceVariant)
                    
                    Text("Check console for debug output after tapping Debug button")
                        .font(.caption)
                        .foregroundColor(.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    // Show actual recent events when available
                    ForEach(events.prefix(4)) { event in
                        Button(action: { onNavigateToSection(.security, .events) }) {
                            ActivityItem(
                                title: "\(event.friendlyLabelName) detected in \(event.friendlyCameraName)",
                                subtitle: event.zones.isEmpty ? "No zones" : "Zones: \(event.friendlyZoneNames)",
                                time: formatEventTime(event.start_time),
                                icon: getIconForLabel(event.label),
                                color: .primary
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    // Helper functions for events
    private func formatEventTime(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private func getIconForLabel(_ label: String) -> String {
        switch label.lowercased() {
        case "person":
            return "figure.walk"
        case "car", "vehicle":
            return "car"
        case "cat":
            return "cat"
        case "dog":
            return "dog"
        case "bird":
            return "bird"
        default:
            return "eye"
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<22:
            return "Good Evening"
        default:
            return "Good Night"
        }
    }

    private var greetingWithName: String {
        let deviceName = UIDevice.current.name
        return "\(greeting), \(deviceName)!"
    }
}

struct WeatherOutsideCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Left side - Text content
            VStack(alignment: .leading, spacing: 2) {
                Text("Outside")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.onSurfaceVariant)
                    .lineLimit(1)
                
                Text("45°F")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.onSurface)
                    .lineLimit(1)
                
                Text("Down 5° tomorrow")
                    .font(.caption2)
                    .foregroundColor(.onSurfaceVariant)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfaceContainerHigh)
        )
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    var onTap: (() -> Void)? = nil
    @State private var isIconPressed = false
    @State private var isPressed = false
    
    var body: some View {
        let content = HStack(alignment: .top, spacing: 8) {
            // Left side - Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.onSurfaceVariant)
                
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.onSurface)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.onSurfaceVariant)
            }
            
            Spacer()
            
            // Right side - decorative icon pill
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color.onSecondaryContainer)
                .frame(width: 52, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.secondaryContainer)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.onSecondaryContainer.opacity((onTap != nil && isPressed) ? 0.1 : 0.0))
                        )
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfaceContainerHigh)
        )
        
        Group {
            if let onTap = onTap {
                Button(action: onTap) { content }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(isPressed ? 0.98 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !isPressed {
                                    withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
                            }
                    )
            } else {
                content
            }
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let textColor: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
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
                    .fill(color)
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

struct ActivityItem: View {
    let title: String
    let subtitle: String
    let time: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.onSurface)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.onSurfaceVariant)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption2)
                .foregroundColor(.onSurfaceVariant)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfaceContainer)
        )
    }
}

// Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light Mode Preview
            HomeView(events: [], inProgressEvents: [], onNavigateToSection: { _, _ in })
                .environmentObject(SettingsStore())
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            // Dark Mode Preview
            HomeView(events: [], inProgressEvents: [], onNavigateToSection: { _, _ in })
                .environmentObject(SettingsStore())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            // Color Test Preview
            VStack(spacing: 20) {
                Text("Material 3 Color Test")
                    .font(.title)
                    .foregroundColor(.onSurface)
                
                HStack(spacing: 16) {
                    VStack {
                        Text("Primary")
                            .foregroundColor(.onPrimary)
                            .padding()
                            .background(Color.primary)
                            .cornerRadius(8)
                        
                        Text("Primary Container")
                            .foregroundColor(.onPrimaryContainer)
                            .padding()
                            .background(Color.primaryContainer)
                            .cornerRadius(8)
                    }
                    
                    VStack {
                        Text("Secondary")
                            .foregroundColor(.onSecondary)
                            .padding()
                            .background(Color.secondary)
                            .cornerRadius(8)
                        
                        Text("Secondary Container")
                            .foregroundColor(.onSecondaryContainer)
                            .padding()
                            .background(Color.secondaryContainer)
                            .cornerRadius(8)
                    }
                }
                
                HStack(spacing: 16) {
                    VStack {
                        Text("Tertiary")
                            .foregroundColor(.onTertiary)
                            .padding()
                            .background(Color.tertiary)
                            .cornerRadius(8)
                        
                        Text("Tertiary Container")
                            .foregroundColor(.onTertiaryContainer)
                            .padding()
                            .background(Color.tertiaryContainer)
                            .cornerRadius(8)
                    }
                    
                    VStack {
                        Text("Error")
                            .foregroundColor(.onError)
                            .padding()
                            .background(Color.error)
                            .cornerRadius(8)
                        
                        Text("Error Container")
                            .foregroundColor(.onErrorContainer)
                            .padding()
                            .background(Color.errorContainer)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color.background)
            .previewDisplayName("Color Test Light")
            
            // Color Test Dark Mode
            VStack(spacing: 20) {
                Text("Material 3 Color Test")
                    .font(.title)
                    .foregroundColor(.onSurface)
                
                HStack(spacing: 16) {
                    VStack {
                        Text("Primary")
                            .foregroundColor(.onPrimary)
                            .padding()
                            .background(Color.primary)
                            .cornerRadius(8)
                        
                        Text("Primary Container")
                            .foregroundColor(.onPrimaryContainer)
                            .padding()
                            .background(Color.primaryContainer)
                            .cornerRadius(8)
                    }
                    
                    VStack {
                        Text("Secondary")
                            .foregroundColor(.onSecondary)
                            .padding()
                            .background(Color.secondary)
                            .cornerRadius(8)
                        
                        Text("Secondary Container")
                            .foregroundColor(.onSecondaryContainer)
                            .padding()
                            .background(Color.secondaryContainer)
                            .cornerRadius(8)
                    }
                }
                
                HStack(spacing: 16) {
                    VStack {
                        Text("Tertiary")
                            .foregroundColor(.onTertiary)
                            .padding()
                            .background(Color.tertiary)
                            .cornerRadius(8)
                        
                        Text("Tertiary Container")
                            .foregroundColor(.onTertiaryContainer)
                            .padding()
                            .background(Color.tertiaryContainer)
                            .cornerRadius(8)
                    }
                    
                    VStack {
                        Text("Error")
                            .foregroundColor(.onError)
                            .padding()
                            .background(Color.error)
                            .cornerRadius(8)
                        
                        Text("Error Container")
                            .foregroundColor(.onErrorContainer)
                            .padding()
                            .background(Color.errorContainer)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color.background)
            .preferredColorScheme(.dark)
            .previewDisplayName("Color Test Dark")
        }
    }
}
