//
//  ClimateView.swift
//  Crooked Sentry
//
//  Created by Assistant on 2025
//

import SwiftUI

struct ClimateView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @State private var currentTemp: Double = 72
    @State private var minTemp: Double = 65  // ~268° on the arc
    @State private var maxTemp: Double = 75  // ~276° on the arc
    @State private var selectedMode: ThermostatMode = .off
    
    var body: some View {
        ZStack {
            // Keep the background as is
            Color.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 40) {
                    // Thermostat title
                    Text("Thermostat")
                        .font(.largeTitle)
                        .fontWeight(.medium)
                        .foregroundColor(.onSurface)
                        .padding(.top, 40)
                    
                    // Temperature range subtitle
                    Text("\(Int(minTemp))°–\(Int(maxTemp))°")
                        .font(.title2)
                        .foregroundColor(.onSurface.opacity(0.7))
                    
                    // Circular thermostat control
                    ThermostatRing(
                        currentTemp: $currentTemp,
                        minTemp: $minTemp,
                        maxTemp: $maxTemp
                    )
                    .frame(width: 320, height: 320)
                    .padding(.vertical, 20)
                    
                    // Mode selector
                    VStack(spacing: 16) {
                        ModeButton(title: "Off", mode: .off, selectedMode: $selectedMode)
                        ModeButton(title: "Cool", mode: .cool, selectedMode: $selectedMode)
                        ModeButton(title: "Heat", mode: .heat, selectedMode: $selectedMode)
                        ModeButton(title: "Auto", mode: .auto, selectedMode: $selectedMode)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                    
                    // Settings button
                    HStack {
                        Spacer()
                        Button(action: {
                            // Settings action
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(.white.opacity(0.1)))
                        }
                        .padding(.trailing, 30)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
    }
}

enum ThermostatMode {
    case off, cool, heat, auto
}

struct ThermostatRing: View {
    @Binding var currentTemp: Double
    @Binding var minTemp: Double
    @Binding var maxTemp: Double
    
    // Temperature range: 32°F to 104°F (72°F range)
    private let tempMin: Double = 32
    private let tempMax: Double = 104
    // Arc range: 330° to 210° going counter-clockwise (240° total, blank space at bottom)
    // 330° is at ~5 o'clock (32°F, blue/min)
    // 210° is at ~7 o'clock (104°F, orange/max)
    private let arcStart: Double = 330 // Start at 5 o'clock (32°F)
    private let arcEnd: Double = 210   // End at 7 o'clock (104°F)
    // Total arc: 240° (goes counter-clockwise from 330° to 210°)
    // Degrees per Fahrenheit: 240° / 72°F ≈ 3.333° per °F
    private let degreesPerF: Double = 240.0 / 72.0
    // Minimum separation: 2° of arc
    private let minSeparation: Double = 2.0
    
    @State private var minAngle: Double = 345 // ~65°F
    @State private var maxAngle: Double = 315 // ~75°F
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = size / 2 - 20
            
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 40)
                    .frame(width: size - 40, height: size - 40)
                
                // Temperature range arc (filled portion between min and max handles)
                ThermostatArc(
                    startAngle: maxAngle, // Start from max (orange) handle
                    endAngle: minAngle,   // End at min (blue) handle
                    radius: radius,
                    lineWidth: 40
                )
                
                // Min temperature control
                ThermostatHandle(
                    angle: $minAngle,
                    color: .blue,
                    center: center,
                    radius: radius,
                    onAngleChanged: { angle in
                        let newAngle = constrainAngle(angle, isMin: true)
                        minAngle = newAngle
                        minTemp = angleToTemperature(newAngle)
                    }
                )
                
                // Max temperature control
                ThermostatHandle(
                    angle: $maxAngle,
                    color: .orange,
                    center: center,
                    radius: radius,
                    onAngleChanged: { angle in
                        let newAngle = constrainAngle(angle, isMin: false)
                        maxAngle = newAngle
                        maxTemp = angleToTemperature(newAngle)
                    }
                )
                
                // Center content
                VStack(spacing: 8) {
                    Text("KEEP BETWEEN")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.onSurface.opacity(0.6))
                    
                    Text("\(Int(minTemp))–\(Int(maxTemp))")
                        .font(.system(size: 72, weight: .thin))
                        .foregroundColor(.onSurface)
                }
            }
        }
    }
    
    private func angleToTemperature(_ angle: Double) -> Double {
        // Map angle going counter-clockwise from 330° to 210°
        // Normalize angle to handle wrap-around at 0°/360°
        var normalizedAngle = angle
        if normalizedAngle < 210 {
            normalizedAngle += 360
        }
        
        // Clamp to valid range (330° to 210° = 330° to 570° normalized)
        let clampedAngle = min(max(normalizedAngle, 330), 570)
        
        // Calculate temperature (330° = 32°F, 570° = 104°F)
        let temperature = tempMin + (clampedAngle - 330) / degreesPerF
        return round(temperature)
    }
    
    private func constrainAngle(_ angle: Double, isMin: Bool) -> Double {
        // Normalize angle for comparison
        var normalizedAngle = angle
        if normalizedAngle < 210 {
            normalizedAngle += 360
        }
        
        var normalizedMin = minAngle
        if normalizedMin < 210 {
            normalizedMin += 360
        }
        
        var normalizedMax = maxAngle
        if normalizedMax < 210 {
            normalizedMax += 360
        }
        
        // Clamp to arc range (330° to 570°)
        var clampedAngle = min(max(normalizedAngle, 330), 570)
        
        // Enforce minimum separation of 2° between handles
        if isMin {
            // Min handle can't go past max handle - 2°
            if clampedAngle > normalizedMax - minSeparation {
                clampedAngle = normalizedMax - minSeparation
            }
        } else {
            // Max handle can't go before min handle + 2°
            if clampedAngle < normalizedMin + minSeparation {
                clampedAngle = normalizedMin + minSeparation
            }
        }
        
        // Convert back to 0-360 range
        if clampedAngle >= 360 {
            clampedAngle -= 360
        }
        
        return clampedAngle
    }
}

struct ThermostatArc: View {
    let startAngle: Double
    let endAngle: Double
    let radius: CGFloat
    let lineWidth: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            Path { path in
                // Draw the arc from minAngle to maxAngle (the filled portion between handles)
                // Convert to SwiftUI's coordinate system (subtract 90°)
                let startRad = (startAngle - 90) * .pi / 180
                let endRad = (endAngle - 90) * .pi / 180
                
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: Angle(radians: startRad),
                    endAngle: Angle(radians: endRad),
                    clockwise: true // Go clockwise from max to min (orange to blue)
                )
            }
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [.orange, .blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
        }
    }
}

struct ThermostatHandle: View {
    @Binding var angle: Double
    let color: Color
    let center: CGPoint
    let radius: CGFloat
    let onAngleChanged: (Double) -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 60, height: 60)
            .overlay(
                Circle()
                    .fill(.white)
                    .frame(width: 28, height: 28)
            )
            .position(handlePosition)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        updateAngle(for: value.location)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
    }
    
    private var handlePosition: CGPoint {
        // Convert angle to radians (adjusting for SwiftUI's 0° being at 3 o'clock)
        // Our 240° should be at 8 o'clock position, 300° at 10 o'clock
        let angleInRadians = (angle - 90) * .pi / 180
        let x = center.x + radius * cos(angleInRadians)
        let y = center.y + radius * sin(angleInRadians)
        return CGPoint(x: x, y: y)
    }
    
    private func updateAngle(for location: CGPoint) {
        let dx = location.x - center.x
        let dy = location.y - center.y
        // Calculate angle and adjust for SwiftUI's coordinate system
        var newAngle = (atan2(dy, dx) * 180 / .pi) + 90
        
        // Normalize to 0-360 range
        if newAngle < 0 {
            newAngle += 360
        }
        
        onAngleChanged(newAngle)
    }
}

struct ModeButton: View {
    let title: String
    let mode: ThermostatMode
    @Binding var selectedMode: ThermostatMode
    
    var body: some View {
        Button(action: {
            selectedMode = mode
        }) {
            Text(title)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(selectedMode == mode ? .white : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
    }
}

// Preview
struct ClimateView_Previews: PreviewProvider {
    static var previews: some View {
        ClimateView()
            .environmentObject(SettingsStore())
    }
}