//
//  NetworkSecurityValidator.swift
//  CrookedSentry
//
//  Enhanced Network Security Validation and Enforcement
//  Created by Assistant on 2025
//

import Foundation
import Network
import SystemConfiguration
import NetworkExtension
import SwiftUI
import Combine

class NetworkSecurityValidator: ObservableObject {
    static let shared = NetworkSecurityValidator()
    
    @Published var isSecureConnectionValidated = false
    @Published var lastValidationResult: ValidationResult?
    
    private let monitor = Network.NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkSecurityValidator")
    
    private init() {
        startNetworkMonitoring()
    }
    
    // Allow deallocation off the MainActor to avoid runtime isolation assertions
    // when instances are freed from background executors during tests.
    nonisolated deinit {
        monitor.cancel()
    }
    
    // MARK: - Core Security Validation
    
    /// Validates if the current network connection is secure before allowing service access
    func validateSecureConnection() async -> ValidationResult {
        print("🔐 === NETWORK SECURITY VALIDATION ===")
        
        var validationChecks: [ValidationCheck] = []
        
        // 1. Check VPN Status
        let vpnCheck = await validateVPNStatus()
        validationChecks.append(vpnCheck)
        
        // 2. Check Network Type
        let networkCheck = await validateNetworkType()
        validationChecks.append(networkCheck)
        
        // 3. Validate Connection Path
        let pathCheck = await validateConnectionPath()
        validationChecks.append(pathCheck)
        
        // 4. Test Service Accessibility
        let serviceCheck = await validateServiceAccess()
        validationChecks.append(serviceCheck)
        
        // 5. Check for bypass attempts
        let bypassCheck = await detectBypassAttempts()
        validationChecks.append(bypassCheck)
        
        // Determine overall result
        let hasFailures = validationChecks.contains { !$0.passed }
        let hasCriticalFailures = validationChecks.contains { $0.severity == .critical && !$0.passed }
        
        let result = ValidationResult(
            isValid: !hasCriticalFailures,
            checks: validationChecks,
            timestamp: Date(),
            summary: generateValidationSummary(validationChecks)
        )
        
        await MainActor.run {
            self.lastValidationResult = result
            self.isSecureConnectionValidated = result.isValid
        }
        
        print("🔐 Validation Result: \(result.isValid ? "✅ SECURE" : "❌ INSECURE")")
        
        return result
    }
    
    // MARK: - Individual Validation Checks
    
    private func validateVPNStatus() async -> ValidationCheck {
        print("🔍 Validating VPN Status...")
        
        let vpnManager = VPNManager.shared
        
        // Check multiple VPN indicators
        var vpnIndicators: [String] = []
        
        // 1. App VPN Connection
        if vpnManager.connectionState.isActive {
            vpnIndicators.append("App VPN Connected")
        }
        
        // 2. System VPN Detection
        if await checkSystemVPN() {
            vpnIndicators.append("System VPN Active")
        }
        
        // 3. VPN Interface Detection
        if detectVPNInterfaces() {
            vpnIndicators.append("VPN Interface Detected")
        }
        
        // 4. Network Route Analysis
        if await analyzeNetworkRoutes() {
            vpnIndicators.append("VPN Routing Detected")
        }
        
        let hasAnyVPN = !vpnIndicators.isEmpty
        
        return ValidationCheck(
            name: "VPN Status",
            passed: hasAnyVPN,
            severity: .critical,
            details: hasAnyVPN ? vpnIndicators.joined(separator: ", ") : "No VPN connection detected",
            recommendation: hasAnyVPN ? nil : "Connect to VPN or ensure you're on the home network"
        )
    }
    
    private func validateNetworkType() async -> ValidationCheck {
        print("🔍 Validating Network Type...")
        
        let path = await getCurrentNetworkPath()
        var networkInfo: [String] = []
        
        if path.usesInterfaceType(.wifi) {
            networkInfo.append("WiFi")
            
            // Check if it's the home network
            if let ssid = getCurrentWiFiSSID() {
                networkInfo.append("SSID: \(ssid)")
                
                // Check if this is a trusted home network
                if isHomeNetwork(ssid: ssid) {
                    return ValidationCheck(
                        name: "Network Type",
                        passed: true,
                        severity: .medium,
                        details: "On trusted home WiFi: \(ssid)",
                        recommendation: nil
                    )
                }
            }
        } else if path.usesInterfaceType(.cellular) {
            networkInfo.append("Cellular")
        } else if path.usesInterfaceType(.wiredEthernet) {
            networkInfo.append("Ethernet")
        } else {
            networkInfo.append("Unknown")
        }
        
        let isSecureNetwork = path.usesInterfaceType(.wiredEthernet) // Ethernet is typically more secure
        
        return ValidationCheck(
            name: "Network Type",
            passed: isSecureNetwork,
            severity: .medium,
            details: networkInfo.joined(separator: ", "),
            recommendation: isSecureNetwork ? nil : "Use VPN when not on home network"
        )
    }
    
    private func validateConnectionPath() async -> ValidationCheck {
        print("🔍 Validating Connection Path...")
        
        // Test actual connectivity to see how traffic is routed
        let publicIP = await getCurrentPublicIP()
        var pathInfo: [String] = []
        
        if let ip = publicIP {
            pathInfo.append("Public IP: \(ip)")
            
            // Check if IP indicates VPN usage
            if isVPNIP(ip) {
                pathInfo.append("VPN IP detected")
                return ValidationCheck(
                    name: "Connection Path",
                    passed: true,
                    severity: .high,
                    details: pathInfo.joined(separator: ", "),
                    recommendation: nil
                )
            } else {
                pathInfo.append("Direct IP (no VPN)")
            }
        }
        
        return ValidationCheck(
            name: "Connection Path",
            passed: false,
            severity: .high,
            details: pathInfo.joined(separator: ", "),
            recommendation: "Traffic not routing through VPN - potential security risk"
        )
    }
    
    private func validateServiceAccess() async -> ValidationCheck {
        print("🔍 Validating Service Access...")
        
        let settingsStore = SettingsStore()
        let baseURL = settingsStore.frigateBaseURL
        
        // Test if we can reach the service
        guard let url = URL(string: "\(baseURL)/api/version") else {
            return ValidationCheck(
                name: "Service Access",
                passed: false,
                severity: .low,
                details: "Invalid service URL",
                recommendation: "Check service configuration"
            )
        }
        
        do {
            let startTime = Date()
            let (_, response) = try await URLSession.shared.data(from: url)
            let responseTime = Date().timeIntervalSince(startTime)
            
            if let httpResponse = response as? HTTPURLResponse {
                let accessible = (200...299).contains(httpResponse.statusCode)
                
                // Fast response time might indicate local network access
                let likelyLocal = responseTime < 0.1
                
                var details = "Status: \(httpResponse.statusCode), Time: \(String(format: "%.3f", responseTime))s"
                if likelyLocal {
                    details += " (likely local)"
                }
                
                return ValidationCheck(
                    name: "Service Access",
                    passed: accessible,
                    severity: .medium,
                    details: details,
                    recommendation: accessible ? nil : "Service not accessible"
                )
            }
        } catch {
            return ValidationCheck(
                name: "Service Access",
                passed: false,
                severity: .medium,
                details: "Connection failed: \(error.localizedDescription)",
                recommendation: "Check network connectivity or VPN status"
            )
        }
        
        return ValidationCheck(
            name: "Service Access",
            passed: false,
            severity: .medium,
            details: "Unknown response type",
            recommendation: "Service responding unexpectedly"
        )
    }
    
    private func detectBypassAttempts() async -> ValidationCheck {
        print("🔍 Detecting Security Bypass Attempts...")
        
        var bypassIndicators: [String] = []
        
        // 1. Check for DNS bypass
        if await checkDNSBypass() {
            bypassIndicators.append("DNS bypass detected")
        }
        
        // 2. Check for connection caching
        if checkConnectionCaching() {
            bypassIndicators.append("Connection caching active")
        }
        
        // 3. Check for alternative routing
        if await checkAlternativeRouting() {
            bypassIndicators.append("Alternative routing detected")
        }
        
        let hasBypass = !bypassIndicators.isEmpty
        
        return ValidationCheck(
            name: "Bypass Detection",
            passed: !hasBypass,
            severity: .critical,
            details: hasBypass ? bypassIndicators.joined(separator: ", ") : "No bypass detected",
            recommendation: hasBypass ? "Security bypass detected - investigate network configuration" : nil
        )
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentNetworkPath() async -> Network.NWPath {
        return await withCheckedContinuation { continuation in
            let monitor = Network.NWPathMonitor()
            let queue = DispatchQueue(label: "PathMonitor")
            
            monitor.pathUpdateHandler = { path in
                monitor.cancel()
                continuation.resume(returning: path)
            }
            
            monitor.start(queue: queue)
        }
    }
    
    private func getCurrentPublicIP() async -> String? {
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.ipify.org")!)
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("   ❌ Failed to get public IP: \(error)")
            return nil
        }
    }
    
    private func checkSystemVPN() async -> Bool {
        // Check NEVPNManager for active VPN connections
        do {
            let manager = NEVPNManager.shared()
            try await manager.loadFromPreferences()
            return manager.connection.status == .connected
        } catch {
            print("   ❌ Error checking system VPN: \(error)")
            return false
        }
    }
    
    private func detectVPNInterfaces() -> Bool {
        let vpnPatterns = ["utun", "tun", "tap", "ppp", "ipsec"]
        
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return false }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            let interface = ptr?.pointee
            let name = String(cString: (interface?.ifa_name)!)
            
            if vpnPatterns.contains(where: { name.hasPrefix($0) }) {
                let flags = Int32(interface?.ifa_flags ?? 0)
                let isUp = (flags & IFF_UP) != 0
                let isRunning = (flags & IFF_RUNNING) != 0
                
                if isUp && isRunning {
                    print("   ✅ Active VPN interface found: \(name)")
                    freeifaddrs(ifaddr)
                    return true
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return false
    }
    
    private func analyzeNetworkRoutes() async -> Bool {
        // This would analyze routing tables to detect VPN routes
        // Simplified implementation for now
        let publicIP = await getCurrentPublicIP()
        
        // Check if public IP is from a known VPN provider
        if let ip = publicIP {
            return isVPNIP(ip)
        }
        
        return false
    }
    
    private func isVPNIP(_ ip: String) -> Bool {
        // Check against known VPN provider IP ranges
        // This is a simplified check - real implementation would have comprehensive lists
        let vpnProviders = [
            "104.28.", // Cloudflare
            "198.41.", // Another Cloudflare range
            "162.158.", // Cloudflare
            // Add more VPN provider IP ranges
        ]
        
        return vpnProviders.contains { ip.hasPrefix($0) }
    }
    
    private func getCurrentWiFiSSID() -> String? {
        // Note: In iOS 14+, this requires location permission and proper entitlements
        // For now, return nil as SSID access is restricted
        return nil
    }
    
    private func isHomeNetwork(ssid: String) -> Bool {
        // Check against known home network SSIDs
        let homeNetworks = UserDefaults.standard.stringArray(forKey: "HomeNetworkSSIDs") ?? []
        return homeNetworks.contains(ssid)
    }
    
    private func checkDNSBypass() async -> Bool {
        // Check if DNS resolution is being bypassed
        let settingsStore = SettingsStore()
        
        if let url = URL(string: settingsStore.frigateBaseURL),
           let host = url.host {
            
            // If host is already an IP address, DNS bypass is possible
            if isIPAddress(host) {
                return true
            }
        }
        
        return false
    }
    
    private func checkConnectionCaching() -> Bool {
        // Check URLSession configurations for aggressive caching
        let config = URLSession.shared.configuration
        
        // If caching is enabled and cache policy allows cached responses,
        // connections might persist beyond VPN state changes
        return config.urlCache != nil && config.requestCachePolicy != .reloadIgnoringLocalAndRemoteCacheData
    }
    
    private func checkAlternativeRouting() async -> Bool {
        // Test connectivity through multiple paths to detect alternative routing
        let alternativeEndpoints = [
            "8.8.8.8", // Google DNS
            "1.1.1.1", // Cloudflare DNS
        ]
        
        for endpoint in alternativeEndpoints {
            do {
                let url = URL(string: "http://\(endpoint)")!
                let (_, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    // If we can reach external services, alternative routing exists
                    return true
                }
            } catch {
                // Connection failed, which is expected if VPN is properly configured
                continue
            }
        }
        
        return false
    }
    
    private func isIPAddress(_ string: String) -> Bool {
        // Simple check for IPv4 address
        let components = string.components(separatedBy: ".")
        
        return components.count == 4 && components.allSatisfy { component in
            if let number = Int(component) {
                return number >= 0 && number <= 255
            }
            return false
        }
    }
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            print("🔄 Network path changed: \(path.status)")
            
            // Invalidate security validation when network changes
            Task { @MainActor in
                self?.isSecureConnectionValidated = false
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func generateValidationSummary(_ checks: [ValidationCheck]) -> String {
        let passedCount = checks.filter { $0.passed }.count
        let totalCount = checks.count
        let criticalFailures = checks.filter { $0.severity == .critical && !$0.passed }
        
        if !criticalFailures.isEmpty {
            return "SECURITY BREACH: \(criticalFailures.count) critical failure(s)"
        } else if passedCount == totalCount {
            return "All security checks passed (\(passedCount)/\(totalCount))"
        } else {
            return "Partial validation (\(passedCount)/\(totalCount) passed)"
        }
    }
    
    // MARK: - Public Interface
    
    /// Forces re-validation of security state
    func invalidateValidation() {
        Task { @MainActor in
            isSecureConnectionValidated = false
            lastValidationResult = nil
        }
    }
    
    /// Quick check if current connection should be allowed
    func shouldAllowConnection() async -> Bool {
        let result = await validateSecureConnection()
        return result.isValid
    }
}

// MARK: - Data Models

struct ValidationResult {
    let isValid: Bool
    let checks: [ValidationCheck]
    let timestamp: Date
    let summary: String
    
    var criticalFailures: [ValidationCheck] {
        return checks.filter { $0.severity == .critical && !$0.passed }
    }
    
    var warnings: [ValidationCheck] {
        return checks.filter { ($0.severity == .high || $0.severity == .medium) && !$0.passed }
    }
}

struct ValidationCheck {
    let name: String
    let passed: Bool
    let severity: ValidationSeverity
    let details: String
    let recommendation: String?
}

enum ValidationSeverity {
    case low, medium, high, critical
    
    var color: SwiftUI.Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "xmark.octagon"
        case .critical: return "xmark.shield"
        }
    }
}

// MARK: - Enhanced VPN Manager Extension

extension VPNManager {
    /// Enhanced security validation before allowing service access
    func validateSecureAccess() async -> Bool {
        let validator = NetworkSecurityValidator.shared
        return await validator.shouldAllowConnection()
    }
    
    /// Force security re-validation
    func invalidateSecurity() {
        NetworkSecurityValidator.shared.invalidateValidation()
        checkCurrentSecurityState()
    }
}

// MARK: - UI Component

struct NetworkSecurityValidationView: View {
    @StateObject private var validator = NetworkSecurityValidator.shared
    @State private var isValidating = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Status Header
            HStack {
                Image(systemName: validator.isSecureConnectionValidated ? "checkmark.shield.fill" : "xmark.shield.fill")
                    .foregroundColor(validator.isSecureConnectionValidated ? .green : .red)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Network Security")
                        .font(.headline)
                    
                    Text(validator.isSecureConnectionValidated ? "Validated" : "Validation Required")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Validation Button
            Button("Validate Security") {
                Task {
                    isValidating = true
                    await validator.validateSecureConnection()
                    isValidating = false
                }
            }
            .disabled(isValidating)
            
            if isValidating {
                ProgressView("Validating network security...")
                    .font(.caption)
            }
            
            // Last Validation Result
            if let result = validator.lastValidationResult {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last Validation: \(result.timestamp, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(result.summary)
                        .font(.subheadline)
                        .foregroundColor(result.isValid ? .green : .red)
                    
                    if !result.criticalFailures.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Critical Issues:")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            
                            ForEach(result.criticalFailures.indices, id: \.self) { index in
                                let failure = result.criticalFailures[index]
                                Text("• \(failure.name): \(failure.details)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
    }
}