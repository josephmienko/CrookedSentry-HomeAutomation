//
//  VPNManager.swift
//  CrookedSentry
//
//  VPN Integration Manager for CrookedKeys
//  Created by Assistant on 2025
//

import SwiftUI
import Combine
// import CrookedKeys  // TODO: Add when framework is available

/// VPN connection states for UI feedback
enum VPNConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case error(String)
    
    var isActive: Bool {
        switch self {
        case .connected:
            return true
        default:
            return false
        }
    }
    
    var displayText: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .disconnecting:
            return "Disconnecting..."
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    var statusColor: Color {
        switch self {
        case .disconnected:
            return .onSurfaceVariant
        case .connecting, .disconnecting:
            return .tertiary
        case .connected:
            return .primary
        case .error:
            return .error
        }
    }
}

/// Main VPN manager that integrates with your existing SettingsStore pattern
class VPNManager: ObservableObject {
    static let shared = VPNManager()
    
    @Published var connectionState: VPNConnectionState = .disconnected
    @Published var isVPNRequired = false
    @Published var showVPNSetup = false
    @Published var serverEndpoint: String = ""
    
    // Security-aware feature flags
    @Published var isSecureMode = false {
        didSet {
            // Update UI based on secure mode
            updateSecureFeatureAvailability()
        }
    }
    
    // Network security detection
    @Published var isOnSecureNetwork = false
    @Published var deviceVPNActive = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupVPNStateObserver()
        loadConfiguration()
        
        // Check current network security status
        checkCurrentSecurityState()
        
        // Check CrookedKeys service on startup
        Task {
            await checkCrookedKeysHealth()
        }
    }
    
    // MARK: - Configuration
    
    // CrookedKeys service endpoints (moved to CrookedKeysConfig.swift for better organization)
    
    func configure(serverEndpoint: String) {
        self.serverEndpoint = serverEndpoint
        UserDefaults.standard.set(serverEndpoint, forKey: "VPNServerEndpoint")
        
        // TODO: Configure CrookedKeysManager when available
        // CrookedKeysManager.shared.configure(serverEndpoint: serverEndpoint)
        
        // Validate CrookedKeys service health
        Task {
            await checkCrookedKeysHealth()
        }
    }
    
    // MARK: - CrookedKeys Integration
    
    @Published var crookedKeysAvailable = false
    @Published var crookedKeysHealthStatus: String = "Unknown"
    @Published var supportsMobileQRSetup: Bool = true  // iOS devices support QR code scanning
    
    func checkCrookedKeysHealth() async {
        guard let url = URL(string: CrookedKeysEndpoints.healthURL) else {
            await MainActor.run {
                crookedKeysAvailable = false
                crookedKeysHealthStatus = "Invalid URL"
            }
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    crookedKeysAvailable = false
                    crookedKeysHealthStatus = "Invalid response"
                }
                return
            }
            
            await MainActor.run {
                crookedKeysAvailable = (200...299).contains(httpResponse.statusCode)
                crookedKeysHealthStatus = crookedKeysAvailable ? "Online" : "HTTP \(httpResponse.statusCode)"
                
                if crookedKeysAvailable, let dataString = String(data: data, encoding: .utf8) {
                    print("CrookedKeys Health: \(dataString)")
                }
            }
        } catch {
            await MainActor.run {
                crookedKeysAvailable = false
                crookedKeysHealthStatus = "Offline: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadConfiguration() {
        serverEndpoint = UserDefaults.standard.string(forKey: "VPNServerEndpoint") ?? ""
    }
    
    // Method to update Frigate URL for local network detection
    func updateFrigateURL(_ url: String) {
        UserDefaults.standard.set(url, forKey: "frigateBaseURL")
        // Re-check security state when Frigate URL changes
        checkCurrentSecurityState()
    }
    
    // MARK: - Connection Management
    
    func connect() {
        guard !serverEndpoint.isEmpty else {
            connectionState = .error("Server endpoint not configured")
            return
        }
        
        connectionState = .connecting
        
        // TODO: Implement actual VPN connection
        // CrookedKeysManager.shared.connect()
        
        // Mock connection for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.connectionState = .connected
            self.isSecureMode = true
        }
    }
    
    func disconnect() {
        connectionState = .disconnecting
        
        // TODO: Implement actual VPN disconnection
        // CrookedKeysManager.shared.disconnect()
        
        // Mock disconnection for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.connectionState = .disconnected
            self.isSecureMode = false
        }
    }
    
    // MARK: - Security-Aware Features
    
    func requireVPNForSecureFeatures(_ required: Bool) {
        isVPNRequired = required
        updateSecureFeatureAvailability()
    }
    
    // MARK: - Network Security Detection
    
    func checkCurrentSecurityState() {
        // Check if device VPN is active
        checkDeviceVPNStatus()
        
        // Check if on secure/local network
        checkNetworkSecurity()
        
        // Update overall security mode
        updateSecurityMode()
    }
    
    private func checkDeviceVPNStatus() {
        // Check for active VPN connections on the device
        // This includes system VPN, third-party VPNs, etc.
        
        // Method 1: Check for VPN network interfaces
        let hasVPNInterface = hasActiveVPNInterface()
        
        // Method 2: Check network routing (VPN often changes default route)
        let hasVPNRouting = hasVPNRouting()
        
        deviceVPNActive = hasVPNInterface || hasVPNRouting
        
        if deviceVPNActive {
            print("✅ VPNManager: Device VPN detected")
        }
    }
    
    private func hasActiveVPNInterface() -> Bool {
        // Check for typical VPN interface names
        let vpnInterfaces = ["utun", "ppp", "ipsec", "tun", "tap"]
        
        // This is a simplified check - in production, you'd use more sophisticated detection
        return vpnInterfaces.contains { interface in
            // Placeholder for interface checking logic
            false // Return false for now, can be enhanced with NetworkExtension APIs
        }
    }
    
    private func hasVPNRouting() -> Bool {
        // Check if routing table shows VPN characteristics
        // VPNs often redirect traffic through different gateways
        
        // This would require parsing route tables or using NetworkExtension APIs
        // For now, return false as this needs more complex implementation
        return false
    }
    
    private func checkNetworkSecurity() {
        // Check if we're on a trusted local network
        // This could include checking if we can reach local services directly
        
        Task {
            await checkIfOnLocalNetwork()
        }
    }
    
    private func checkIfOnLocalNetwork() async {
        // Check if we can reach the Frigate server on local network
        // If Frigate is accessible via local IP, we're likely on the home network
        
        // Get the Frigate base URL from settings and check if it's a local address
        let frigateURL = UserDefaults.standard.string(forKey: "frigateBaseURL") ?? ""
        
        if isLocalNetworkAddress(frigateURL) {
            await MainActor.run {
                isOnSecureNetwork = true
                print("✅ VPNManager: On secure local network")
            }
        } else {
            await MainActor.run {
                isOnSecureNetwork = false
            }
        }
    }
    
    private func isLocalNetworkAddress(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let host = url.host else { return false }
        
        // Check for local network patterns
        let localPatterns = [
            "192.168.",
            "10.",
            "172.16.", "172.17.", "172.18.", "172.19.", "172.20.",
            "172.21.", "172.22.", "172.23.", "172.24.", "172.25.",
            "172.26.", "172.27.", "172.28.", "172.29.", "172.30.", "172.31.",
            "127.",
            "localhost"
        ]
        
        return localPatterns.contains { host.hasPrefix($0) }
    }
    
    private func updateSecurityMode() {
        // User is in secure mode if:
        // 1. They have an active VPN connection, OR
        // 2. They're on a trusted local network, OR  
        // 3. Our managed VPN connection is active
        
        let wasSecure = isSecureMode
        isSecureMode = deviceVPNActive || isOnSecureNetwork || connectionState.isActive
        
        if isSecureMode != wasSecure {
            print("🔒 VPNManager: Security mode changed to \(isSecureMode)")
            if isSecureMode {
                print("   - Device VPN: \(deviceVPNActive)")
                print("   - Local Network: \(isOnSecureNetwork)")
                print("   - App VPN: \(connectionState.isActive)")
            }
        }
    }
    
    private func updateSecureFeatureAvailability() {
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .vpnSecurityStateChanged,
            object: nil,
            userInfo: ["isSecure": isSecureMode]
        )
    }
    
    // MARK: - Auto-connection Logic
    
    func connectIfNeeded() {
        guard isVPNRequired else { return }
        
        switch connectionState {
        case .disconnected:
            if canAutoConnect() {
                connect()
            } else {
                showVPNSetup = true
            }
        default:
            break
        }
    }
    
    func canAutoConnect() -> Bool {
        // Check if VPN is already configured
        return !serverEndpoint.isEmpty
        // TODO: Add CrookedKeysManager.shared.canConnect check
    }
    
    // MARK: - Setup State Observation
    
    private func setupVPNStateObserver() {
        // Monitor connection state changes
        $connectionState
            .sink { [weak self] state in
                self?.handleConnectionStateChange(state)
            }
            .store(in: &cancellables)
        
        // Periodically check security state (every 30 seconds)
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkCurrentSecurityState()
            }
            .store(in: &cancellables)
    }
    
    private func handleConnectionStateChange(_ state: VPNConnectionState) {
        // Re-evaluate security mode when connection state changes
        updateSecurityMode()
        
        // Log state changes for debugging
        print("VPN State changed to: \(state.displayText)")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let vpnSecurityStateChanged = Notification.Name("vpnSecurityStateChanged")
    static let vpnConnectionStateChanged = Notification.Name("vpnConnectionStateChanged")
}

// MARK: - Feature Flags Integration

enum VPNFeatureFlags {
    static let vpnIntegration = true
    static let autoVPNConnect = false  // Start conservatively
    static let vpnRequiredForCameras = true
    static let vpnRequiredForLiveFeeds = true
    static let showVPNStatusInDrawer = true
}