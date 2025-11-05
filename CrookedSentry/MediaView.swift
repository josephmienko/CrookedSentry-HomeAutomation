//
//  MediaView.swift
//  Crooked Sentry
//
//  Created by Assistant on 2025
//

import SwiftUI

struct MediaView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {
                // Coming Soon Header
                comingSoonHeader
                
                // Planned Features
                plannedFeaturesSection
            }
            .padding()
        }
        .background(Color.background)
    }
    
    private var comingSoonHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "tv.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text("MC @ the CC")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Media Control Center")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Coming Soon!")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Text("This section will control your entertainment devices")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.blue.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private var plannedFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Planned Features")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                PlannedFeatureCard(
                    title: "TV Control",
                    subtitle: "Power, volume, channels",
                    icon: "tv",
                    color: .blue
                )
                
                PlannedFeatureCard(
                    title: "Roku Control",
                    subtitle: "Apps, navigation, remote",
                    icon: "appletv",
                    color: .purple
                )
                
                PlannedFeatureCard(
                    title: "Sound System",
                    subtitle: "Audio zones, playlists",
                    icon: "speaker.wave.3",
                    color: .green
                )
                
                PlannedFeatureCard(
                    title: "Streaming",
                    subtitle: "Netflix, Hulu, etc.",
                    icon: "play.rectangle",
                    color: .red
                )
            }
        }
    }
}

struct PlannedFeatureCard: View {
    let title: String
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
                
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// Preview
struct MediaView_Previews: PreviewProvider {
    static var previews: some View {
        MediaView()
            .environmentObject(SettingsStore())
    }
}