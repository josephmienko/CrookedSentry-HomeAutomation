//
//  HomeView.swift
//  Crooked Sentry
//
//  Created by Assistant on 2025
//

import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Welcome Header
                welcomeHeader
                
                // Quick Stats Cards
                quickStatsSection
                
                // Quick Actions
                quickActionsSection
                
                // Recent Activity
                recentActivitySection
            }
            .padding()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(currentTime.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "sun.max.fill")
                    .font(.title)
                    .foregroundColor(.orange)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                QuickStatCard(
                    title: "Cameras",
                    value: "2",
                    subtitle: "Active",
                    icon: "video.fill",
                    color: .blue
                )
                
                QuickStatCard(
                    title: "Temperature",
                    value: "72°F",
                    subtitle: "Comfortable",
                    icon: "thermometer",
                    color: .green
                )
                
                QuickStatCard(
                    title: "Lights",
                    value: "8",
                    subtitle: "On",
                    icon: "lightbulb.fill",
                    color: .yellow
                )
                
                QuickStatCard(
                    title: "Security",
                    value: "Armed",
                    subtitle: "Home Mode",
                    icon: "shield.fill",
                    color: .purple
                )
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                QuickActionCard(
                    title: "All Lights Off",
                    icon: "lightbulb.slash",
                    color: .orange
                ) {
                    // Action for lights off
                }
                
                QuickActionCard(
                    title: "Movie Mode",
                    icon: "tv",
                    color: .indigo
                ) {
                    // Action for movie mode
                }
                
                QuickActionCard(
                    title: "Good Night",
                    icon: "moon.fill",
                    color: .purple
                ) {
                    // Action for good night
                }
                
                QuickActionCard(
                    title: "Away Mode",
                    icon: "location.slash",
                    color: .red
                ) {
                    // Action for away mode
                }
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ActivityItem(
                    title: "Motion detected",
                    subtitle: "Backyard Camera",
                    time: "5 min ago",
                    icon: "figure.walk",
                    color: .red
                )
                
                ActivityItem(
                    title: "Living room lights turned on",
                    subtitle: "Automated schedule",
                    time: "1 hour ago",
                    icon: "lightbulb.fill",
                    color: .yellow
                )
                
                ActivityItem(
                    title: "Thermostat adjusted",
                    subtitle: "Set to 72°F",
                    time: "2 hours ago",
                    icon: "thermometer",
                    color: .blue
                )
            }
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
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
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
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(SettingsStore())
    }
}