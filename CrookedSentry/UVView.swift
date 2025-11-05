//
//  UVView.swift
//  CrookedSentry
//
//  UV Monitoring & Control View
//  Created by Assistant on 2025
//

import SwiftUI

struct UVView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("UV @ the CC")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.onSurface)
                            
                            Text("Ultraviolet monitoring and protection systems")
                                .font(.subheadline)
                                .foregroundColor(.onSurfaceVariant)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.primary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.surfaceContainer)
                )
                
                // UV Index Card
                UVIndexCard()
                
                // UV Protection Controls
                UVProtectionControlsCard()
                
                // UV Monitoring History
                UVHistoryCard()
                
                // UV Settings Quick Access
                UVSettingsCard()
            }
            .padding()
        }
        .background(Color.background)
        .navigationBarHidden(true)
    }
}

struct UVIndexCard: View {
    @State private var currentUVIndex: Double = 7.2
    @State private var uvRiskLevel: String = "High"
    @State private var isRefreshing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Current UV Index")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.onSurface)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isRefreshing.toggle()
                    }
                    // Simulate refresh
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation {
                            isRefreshing = false
                        }
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.onPrimaryContainer)
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(.linear(duration: 1).repeatCount(isRefreshing ? 10 : 0), value: isRefreshing)
                }
                .padding(8)
                .background(Color.primaryContainer)
                .cornerRadius(8)
            }
            
            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(currentUVIndex, specifier: "%.1f")")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("UV Index")
                        .font(.caption)
                        .foregroundColor(.onSurfaceVariant)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(uvRiskLevel)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(uvRiskLevel == "High" ? .error : .primary)
                    
                    Text("Risk Level")
                        .font(.caption)
                        .foregroundColor(.onSurfaceVariant)
                }
            }
            
            // UV Scale Visual
            HStack(spacing: 2) {
                ForEach(0..<11) { index in
                    Rectangle()
                        .fill(uvScaleColor(for: index))
                        .frame(height: 8)
                        .opacity(Double(index) <= currentUVIndex ? 1.0 : 0.3)
                }
            }
            .cornerRadius(4)
            
            Text("Protection recommended after 15 minutes of exposure")
                .font(.caption)
                .foregroundColor(.onSurfaceVariant)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceContainer)
        )
    }
    
    private func uvScaleColor(for index: Int) -> Color {
        switch index {
        case 0...2:
            return .green
        case 3...5:
            return .yellow
        case 6...7:
            return .orange
        case 8...10:
            return .red
        default:
            return .purple
        }
    }
}

struct UVProtectionControlsCard: View {
    @State private var autoBlindsClosed = true
    @State private var uvAlertsEnabled = true
    @State private var outdoorLightsAuto = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("UV Protection Controls")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.onSurface)
            
            VStack(spacing: 12) {
                UVControlRow(
                    icon: "window.vertical.closed",
                    title: "Auto Window Shades",
                    subtitle: "Close when UV > 6",
                    isOn: $autoBlindsClosed,
                    color: .tertiary
                )
                
                UVControlRow(
                    icon: "bell.badge",
                    title: "UV Alerts",
                    subtitle: "Notify when UV is high",
                    isOn: $uvAlertsEnabled,
                    color: .primary
                )
                
                UVControlRow(
                    icon: "lightbulb.led",
                    title: "Smart Outdoor Lighting",
                    subtitle: "Adjust for UV protection",
                    isOn: $outdoorLightsAuto,
                    color: .secondary
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceContainer)
        )
    }
}

struct UVControlRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.onSurface)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.onSurfaceVariant)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: color))
        }
        .padding(.vertical, 8)
    }
}

struct UVHistoryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("UV History")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.onSurface)
                
                Spacer()
                
                Button(action: {
                    // Navigate to detailed UV history
                }) {
                    Text("View All")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            
            // Simplified UV chart placeholder
            VStack(spacing: 8) {
                HStack {
                    Text("Today's Peak: 8.4")
                        .font(.body)
                        .foregroundColor(.onSurface)
                    
                    Spacer()
                    
                    Text("Yesterday: 7.1")
                        .font(.body)
                        .foregroundColor(.onSurfaceVariant)
                }
                
                // Simple bar chart representation
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<7) { day in
                        Rectangle()
                            .fill(Color.primary.opacity(0.7))
                            .frame(width: 20, height: CGFloat.random(in: 20...60))
                    }
                }
                .frame(height: 80)
                
                HStack {
                    Text("7 days ago")
                        .font(.caption2)
                        .foregroundColor(.onSurfaceVariant)
                    
                    Spacer()
                    
                    Text("Today")
                        .font(.caption2)
                        .foregroundColor(.onSurfaceVariant)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceContainer)
        )
    }
}

struct UVSettingsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.onSurface)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                UVQuickSettingButton(
                    title: "Calibrate Sensors",
                    icon: "slider.horizontal.3",
                    color: .secondaryContainer,
                    textColor: .onSecondaryContainer
                ) {
                    // Calibrate UV sensors
                }
                
                UVQuickSettingButton(
                    title: "Alert Settings",
                    icon: "bell.and.waveform",
                    color: .tertiaryContainer,
                    textColor: .onTertiaryContainer
                ) {
                    // Configure UV alerts
                }
                
                UVQuickSettingButton(
                    title: "Export Data",
                    icon: "square.and.arrow.up",
                    color: .primaryContainer,
                    textColor: .onPrimaryContainer
                ) {
                    // Export UV data
                }
                
                UVQuickSettingButton(
                    title: "Device Status",
                    icon: "antenna.radiowaves.left.and.right",
                    color: .surfaceContainerHigh,
                    textColor: .onSurface
                ) {
                    // Check UV sensor status
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceContainer)
        )
    }
}

struct UVQuickSettingButton: View {
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
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .overlay(
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
#Preview("UV View Light") {
    UVView()
        .environmentObject(SettingsStore())
        .preferredColorScheme(.light)
}

#Preview("UV View Dark") {
    UVView()
        .environmentObject(SettingsStore())
        .preferredColorScheme(.dark)
}