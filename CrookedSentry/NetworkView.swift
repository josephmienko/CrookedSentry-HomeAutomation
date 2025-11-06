//
//  NetworkView.swift
//  CrookedSentry
//
//  VPN and Network Security Management
//  Created by Assistant on 2025
//

import SwiftUI

struct NetworkView: View {
    @ObservedObject var vpnManager = VPNManager.shared
    @State private var showingVPNSetup = false
    @State private var showingAdvancedSettings = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 24) {
                // VPN Connection Card
                VPNConnectionCard()
                
                // Security Features Card
                SecurityFeaturesCard()
                
                // Network Information Card
                NetworkInfoCard()
                
                // Quick Actions Card
                QuickActionsCard()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(Color.background)
        .navigationTitle("Secure Access")
        .sheet(isPresented: $showingVPNSetup) {
            VPNSetupView()
        }
        .sheet(isPresented: $showingAdvancedSettings) {
            VPNConfigurationView()
        }
    }
}

// MARK: - VPN Connection Card

struct VPNConnectionCard: View {
    @ObservedObject var vpnManager = VPNManager.shared
    @State private var showingSetup = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VPN Connection")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.onSurface)
                    
                    Text("Secure access to your home network")
                        .font(.body)
                        .foregroundColor(.onSurfaceVariant)
                }
                
                Spacer()
                
                // Status Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(vpnManager.connectionState.statusColor)
                        .frame(width: 8, height: 8)
                    
                    Text(vpnManager.connectionState.displayText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(vpnManager.connectionState.statusColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(vpnManager.connectionState.statusColor.opacity(0.1))
                )
            }
            
            // Connection Controls
            VStack(spacing: 16) {
                // Main Connection Button
                Button(action: handleConnectionAction) {
                    HStack {
                        Group {
                            if case .connecting = vpnManager.connectionState {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .onPrimary))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: connectionButtonIcon)
                            }
                        }
                        
                        Text(connectionButtonText)
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(connectionButtonColor)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isConnectionDisabled)
                
                // Secondary Actions
                if vpnManager.connectionState.isActive {
                    HStack(spacing: 16) {
                        Button("Configure") {
                            showingSetup = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("Connected since: Just now")
                            .font(.caption)
                            .foregroundColor(.onSurfaceVariant)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceContainer)
        )
        .sheet(isPresented: $showingSetup) {
            VPNSetupView()
        }
    }
    
    // MARK: - Computed Properties
    
    private var connectionButtonIcon: String {
        switch vpnManager.connectionState {
        case .connected:
            return "stop.circle.fill"
        case .disconnected, .error:
            return "play.circle.fill"
        default:
            return "lock.shield.fill"
        }
    }
    
    private var connectionButtonText: String {
        switch vpnManager.connectionState {
        case .connected:
            return "Disconnect"
        case .connecting:
            return "Connecting..."
        case .disconnecting:
            return "Disconnecting..."
        case .disconnected:
            return vpnManager.serverEndpoint.isEmpty ? "Setup VPN" : "Connect"
        case .error:
            return "Retry Connection"
        }
    }
    
    private var connectionButtonColor: Color {
        switch vpnManager.connectionState {
        case .connected:
            return .error
        case .error:
            return .tertiary
        default:
            return .primary
        }
    }
    
    private var isConnectionDisabled: Bool {
        switch vpnManager.connectionState {
        case .connecting, .disconnecting:
            return true
        default:
            return false
        }
    }
    
    private func handleConnectionAction() {
        switch vpnManager.connectionState {
        case .connected:
            vpnManager.disconnect()
        case .disconnected, .error:
            if vpnManager.serverEndpoint.isEmpty {
                showingSetup = true
            } else {
                vpnManager.connect()
            }
        default:
            break
        }
    }
}

// MARK: - Security Features Card

struct SecurityFeaturesCard: View {
    @ObservedObject var vpnManager = VPNManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Security Features")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.onSurface)
            
            VStack(spacing: 12) {
                SecurityFeatureRow(
                    icon: "video.fill",
                    title: "Secure Camera Access",
                    description: "Cameras require VPN connection",
                    isEnabled: VPNFeatureFlags.vpnRequiredForCameras,
                    isActive: vpnManager.isSecureMode
                )
                
                SecurityFeatureRow(
                    icon: "play.rectangle.fill",
                    title: "Protected Live Feeds",
                    description: "Live streams through secure tunnel",
                    isEnabled: VPNFeatureFlags.vpnRequiredForLiveFeeds,
                    isActive: vpnManager.isSecureMode
                )
                
                SecurityFeatureRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Auto-Connect",
                    description: "Automatically connect when needed",
                    isEnabled: VPNFeatureFlags.autoVPNConnect,
                    isActive: vpnManager.isSecureMode
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceContainer)
        )
    }
}

struct SecurityFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let isEnabled: Bool
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(statusColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.onSurface)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.onSurfaceVariant)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                
                Text(statusText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        if !isEnabled {
            return .onSurfaceVariant
        }
        return isActive ? .primary : .tertiary
    }
    
    private var statusText: String {
        if !isEnabled {
            return "Disabled"
        }
        return isActive ? "Active" : "Inactive"
    }
}

// MARK: - Network Info Card

struct NetworkInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Network Information")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.onSurface)
            
            VStack(spacing: 12) {
                NetworkInfoRow(label: "Local IP", value: "192.168.1.100")  // TODO: Get actual IP
                NetworkInfoRow(label: "VPN IP", value: "73.35.176.251")
                NetworkInfoRow(label: "VPN Server", value: VPNManager.shared.serverEndpoint.isEmpty ? "Not configured" : VPNManager.shared.serverEndpoint)
                
                Divider()
                    .padding(.vertical, 4)
                
                NetworkInfoRow(label: "CrookedKeys API", value: VPNManager.CrookedKeysEndpoints.baseURL)
                NetworkInfoRow(label: "Onboarding URL", value: VPNManager.CrookedKeysEndpoints.onboardingURL)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceContainer)
        )
    }
}

struct NetworkInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.onSurfaceVariant)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.onSurface)
        }
    }
}

// MARK: - Quick Actions Card

struct QuickActionsCard: View {
    @State private var showingAdvancedSettings = false
    @State private var showingDiagnostics = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.onSurface)
            
            VStack(spacing: 8) {
                QuickActionButton(
                    icon: "gear",
                    title: "Advanced Settings",
                    action: { showingAdvancedSettings = true }
                )
                
                QuickActionButton(
                    icon: "stethoscope",
                    title: "Network Diagnostics",
                    action: { showingDiagnostics = true }
                )
                
                QuickActionButton(
                    icon: "qrcode.viewfinder",
                    title: "Open Family Onboarding",
                    action: openCrookedKeysOnboarding
                )
                
                QuickActionButton(
                    icon: "arrow.clockwise",
                    title: "Reset VPN Configuration",
                    action: resetVPNConfiguration
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceContainer)
        )
        .sheet(isPresented: $showingAdvancedSettings) {
            VPNConfigurationView()
        }
        .sheet(isPresented: $showingDiagnostics) {
            NetworkDiagnosticsView()
        }
    }
    
    private func openCrookedKeysOnboarding() {
        guard let url = URL(string: VPNManager.CrookedKeysEndpoints.onboardingURL) else { return }
        UIApplication.shared.open(url)
    }
    
    private func resetVPNConfiguration() {
        VPNManager.shared.disconnect()
        VPNManager.shared.configure(serverEndpoint: "")
        // TODO: Clear stored credentials
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.onSurface)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.onSurfaceVariant)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.surface)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Network Diagnostics View

struct NetworkDiagnosticsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isRunningTests = false
    @State private var testResults: [DiagnosticResult] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if testResults.isEmpty && !isRunningTests {
                    // Initial State
                    VStack(spacing: 16) {
                        Image(systemName: "stethoscope")
                            .font(.system(size: 48))
                            .foregroundColor(.primary)
                        
                        Text("Network Diagnostics")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Run tests to check your network connection and VPN status")
                            .font(.body)
                            .foregroundColor(.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    Button("Run Diagnostics") {
                        runDiagnostics()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.primary)
                    )
                    .padding(.horizontal, 24)
                    
                } else if isRunningTests {
                    // Running Tests
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Running network tests...")
                            .font(.body)
                            .foregroundColor(.onSurfaceVariant)
                    }
                    .padding(.top, 100)
                    
                    Spacer()
                    
                } else {
                    // Test Results
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(testResults, id: \.name) { result in
                                DiagnosticResultRow(result: result)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color.background)
            .navigationTitle("Diagnostics")
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: !testResults.isEmpty ? Button("Re-run") {
                    runDiagnostics()
                } : nil
            )
        }
    }
    
    private func runDiagnostics() {
        isRunningTests = true
        testResults = []
        
        // Run actual diagnostics
        Task {
            var results: [DiagnosticResult] = []
            
            // Test internet connectivity
            results.append(await testInternetConnection())
            
            // Test CrookedKeys service health
            results.append(await testCrookedKeysHealth())
            
            // Test CrookedKeys onboarding page
            results.append(await testCrookedKeysOnboarding())
            
            // Test VPN server if configured
            if !VPNManager.shared.serverEndpoint.isEmpty {
                results.append(await testVPNServerReachability())
            }
            
            await MainActor.run {
                testResults = results
                isRunningTests = false
            }
        }
    }
    
    // MARK: - Diagnostic Test Methods
    
    private func testInternetConnection() async -> DiagnosticResult {
        guard let url = URL(string: "https://www.google.com") else {
            return DiagnosticResult(name: "Internet Connection", status: .error, message: "Invalid test URL")
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                return DiagnosticResult(name: "Internet Connection", status: .success, message: "Connected")
            } else {
                return DiagnosticResult(name: "Internet Connection", status: .error, message: "No response")
            }
        } catch {
            return DiagnosticResult(name: "Internet Connection", status: .error, message: error.localizedDescription)
        }
    }
    
    private func testCrookedKeysHealth() async -> DiagnosticResult {
        guard let url = URL(string: VPNManager.CrookedKeysEndpoints.healthURL) else {
            return DiagnosticResult(name: "CrookedKeys Health", status: .error, message: "Invalid URL")
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    return DiagnosticResult(name: "CrookedKeys Health", status: .success, message: "Service online")
                } else {
                    return DiagnosticResult(name: "CrookedKeys Health", status: .error, message: "HTTP \(httpResponse.statusCode)")
                }
            } else {
                return DiagnosticResult(name: "CrookedKeys Health", status: .error, message: "Invalid response")
            }
        } catch {
            return DiagnosticResult(name: "CrookedKeys Health", status: .error, message: "Service offline")
        }
    }
    
    private func testCrookedKeysOnboarding() async -> DiagnosticResult {
        guard let url = URL(string: VPNManager.CrookedKeysEndpoints.onboardingURL) else {
            return DiagnosticResult(name: "Onboarding Page", status: .error, message: "Invalid URL")
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    return DiagnosticResult(name: "Onboarding Page", status: .success, message: "Available")
                } else {
                    return DiagnosticResult(name: "Onboarding Page", status: .warning, message: "HTTP \(httpResponse.statusCode)")
                }
            } else {
                return DiagnosticResult(name: "Onboarding Page", status: .error, message: "Invalid response")
            }
        } catch {
            return DiagnosticResult(name: "Onboarding Page", status: .error, message: "Not reachable")
        }
    }
    
    private func testVPNServerReachability() async -> DiagnosticResult {
        let serverEndpoint = VPNManager.shared.serverEndpoint
        guard let url = URL(string: "http://\(serverEndpoint)") else {
            return DiagnosticResult(name: "VPN Server", status: .error, message: "Invalid endpoint")
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    return DiagnosticResult(name: "VPN Server", status: .success, message: "Reachable")
                } else {
                    return DiagnosticResult(name: "VPN Server", status: .warning, message: "HTTP \(httpResponse.statusCode)")
                }
            } else {
                return DiagnosticResult(name: "VPN Server", status: .warning, message: "Slow response")
            }
        } catch {
            return DiagnosticResult(name: "VPN Server", status: .error, message: "Not reachable")
        }
    }
}

struct DiagnosticResult {
    let name: String
    let status: DiagnosticStatus
    let message: String
}

enum DiagnosticStatus {
    case success, warning, error
    
    var color: Color {
        switch self {
        case .success: return .primary
        case .warning: return .tertiary
        case .error: return .error
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

struct DiagnosticResultRow: View {
    let result: DiagnosticResult
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: result.status.icon)
                .foregroundColor(result.status.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(result.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.onSurface)
                
                Text(result.message)
                    .font(.caption)
                    .foregroundColor(.onSurfaceVariant)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.surfaceContainer)
        )
    }
}

// MARK: - Preview

struct NetworkView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkView()
    }
}