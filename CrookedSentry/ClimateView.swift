//
//  ClimateView.swift
//  Crooked Sentry
//
//  Created by Assistant on 2025
//

import SwiftUI

struct ClimateView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Coming Soon Header
                comingSoonHeader
                
                // Planned Features
                plannedFeaturesSection
            }
            .padding()
        }
    }
    
    private var comingSoonHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "thermometer")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            Text("HVAC for the CC")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Climate Control Center")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Coming Soon!")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                Text("This section will manage your heating and cooling systems")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.orange.opacity(0.3), lineWidth: 1)
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
                ClimateFeatureCard(
                    title: "Thermostat",
                    subtitle: "Temperature control",
                    icon: "thermometer.medium",
                    color: .orange,
                    currentValue: "72°F"
                )
                
                ClimateFeatureCard(
                    title: "Humidity",
                    subtitle: "Air moisture control",
                    icon: "humidity",
                    color: .blue,
                    currentValue: "45%"
                )
                
                ClimateFeatureCard(
                    title: "Air Quality",
                    subtitle: "Filter & ventilation",
                    icon: "wind",
                    color: .green,
                    currentValue: "Good"
                )
                
                ClimateFeatureCard(
                    title: "Zones",
                    subtitle: "Room-by-room control",
                    icon: "house.lodge",
                    color: .purple,
                    currentValue: "3 Active"
                )
            }
        }
    }
}

struct ClimateFeatureCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let currentValue: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(currentValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                    
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
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
struct ClimateView_Previews: PreviewProvider {
    static var previews: some View {
        ClimateView()
            .environmentObject(SettingsStore())
    }
}