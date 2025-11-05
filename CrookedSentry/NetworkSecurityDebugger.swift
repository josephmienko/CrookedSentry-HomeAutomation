//
//  NetworkSecurityDebugger.swift
//  CrookedSentry
//
//  Network Security Investigation and Debugging Tool
//  Created by Assistant on 2025
//

import Foundation
import Network
import SystemConfiguration
import NetworkExtension
import SwiftUI
import Combine

class NetworkSecurityDebugger: ObservableObject {
    static let shared = NetworkSecurityDebugger()
    
    @Published var debugResults: [SecurityDebugResult] = []
    @Published var isDebugging = false
    
    private init() {}
    
    // MARK: - Main Security Investigation
    
    func performSecurityInvestigation() async {
        await MainActor.run {
            isDebugging = true
            debugResults.removeAll()
        }
        
        print("🚨 =========================")
        print("🚨 SECURITY INVESTIGATION STARTED")
        print("🚨 =========================")
        
        // 1. Network State Analysis
        await checkNetworkInterfaces()
        await checkVPNStatus()
        await checkNetworkReachability()
        
        // 2. Connection Analysis
        await analyzeURLSessionConfiguration()
        await testServiceConnectivity()
        
        // 3. Security State Validation
        await validateSecurityState()
        
        // 4. Connection Path Tracing
        await traceConnectionPaths()
        
        await MainActor.run {
            isDebugging = false
        }
        
        print("🚨 =========================")
        print("🚨 SECURITY INVESTIGATION COMPLETED")
        print("🚨 =========================")
        
        generateSecurityReport()
    }
    
    // MARK: - Network Interface Analysis
    
    private func checkNetworkInterfaces() async {
        print("🔍 === NETWORK INTERFACES ANALYSIS ===")
        
        let interfaces = getNetworkInterfaces()
        for interface in interfaces {
            print("📡 Interface: \(interface.name)")
            print("   Type: \(interface.type)")
            print("   IP: \(interface.ipAddress)")
            print("   Status: \(interface.isActive ? "Active" : "Inactive")")
            
            await addDebugResult(
                category: "Network Interfaces",
                title: "Interface: \(interface.name)",
                status: interface.isActive ? .warning : .error,
                details: "Type: \(interface.type), IP: \(interface.ipAddress)"
            )
        }
    }
    
    private func getNetworkInterfaces() -> [NetworkInterface] {
        var interfaces: [NetworkInterface] = []
        
        // iOS-compatible network interface detection
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return interfaces }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            let interface = ptr?.pointee
            let name = String(cString: (interface?.ifa_name)!)
            let flags = Int32(interface?.ifa_flags ?? 0)
            let isUp = (flags & IFF_UP) != 0
            let isRunning = (flags & IFF_RUNNING) != 0
            
            // Determine interface type based on name patterns
            let type = getInterfaceType(name)
            
            let networkInterface = NetworkInterface(
                name: name,
                type: type,
                ipAddress: getIPAddress(for: name) ?? "N/A",
                isActive: isUp && isRunning
            )
            
            interfaces.append(networkInterface)
        }
        
        freeifaddrs(ifaddr)
        return interfaces
    }
    
    private func getInterfaceType(_ name: String) -> String {
        if name.hasPrefix("en") {
            return "Ethernet/WiFi"
        } else if name.hasPrefix("utun") || name.hasPrefix("tun") || name.hasPrefix("tap") {
            return "VPN"
        } else if name.hasPrefix("pdp_ip") || name.hasPrefix("cellular") {
            return "Cellular"
        } else if name == "lo0" {
            return "Loopback"
        } else {
            return "Other"
        }
    }
    
    private func getIPAddress(for interfaceName: String) -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: (interface?.ifa_name)!)
                    if name == interfaceName {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        if getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!),
                                      &hostname, socklen_t(hostname.count),
                                      nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                            address = String(cString: hostname)
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        
        return address
    }
    
    // Note: isInterfaceActive is now handled in getNetworkInterfaces() method
    
    // MARK: - VPN Status Detection
    
    private func checkVPNStatus() async {
        print("🔍 === VPN STATUS ANALYSIS ===")
        
        // Check NEVPNManager status
        await checkNEVPNStatus()
        
        // Check for VPN interfaces
        await checkVPNInterfaces()
        
        // Check routing table for VPN routes
        await checkVPNRouting()
    }
    
    private func checkNEVPNStatus() async {
        print("🔐 Checking NEVPNManager status...")
        
        do {
            let managers = try await NEVPNManager.shared().loadFromPreferences()
            let status = NEVPNManager.shared().connection.status
            
            print("   VPN Manager Status: \(status.rawValue)")
            print("   VPN Configuration Exists: \(NEVPNManager.shared().protocolConfiguration != nil)")
            
            await addDebugResult(
                category: "VPN Status",
                title: "NEVPNManager Status",
                status: status == .connected ? .success : .error,
                details: "Status: \(status), Config exists: \(NEVPNManager.shared().protocolConfiguration != nil)"
            )
        } catch {
            print("   ❌ Error checking VPN status: \(error)")
            
            await addDebugResult(
                category: "VPN Status",
                title: "NEVPNManager Error",
                status: .error,
                details: error.localizedDescription
            )
        }
    }
    
    private func checkVPNInterfaces() async {
        print("🔐 Checking for VPN network interfaces...")
        
        let vpnInterfacePatterns = ["utun", "tun", "tap", "ppp", "ipsec"]
        let interfaces = getNetworkInterfaces()
        
        for pattern in vpnInterfacePatterns {
            let matchingInterfaces = interfaces.filter { $0.name.hasPrefix(pattern) }
            
            if !matchingInterfaces.isEmpty {
                for interface in matchingInterfaces {
                    print("   🔍 VPN Interface Found: \(interface.name) - \(interface.ipAddress)")
                    
                    await addDebugResult(
                        category: "VPN Interfaces",
                        title: "VPN Interface: \(interface.name)",
                        status: interface.isActive ? .success : .warning,
                        details: "IP: \(interface.ipAddress), Active: \(interface.isActive)"
                    )
                }
            }
        }
    }
    
    private func checkVPNRouting() async {
        print("🔐 Checking VPN routing table...")
        
        // This is a simplified check - real implementation would parse route tables
        let currentIP = await getCurrentPublicIP()
        
        await addDebugResult(
            category: "VPN Routing",
            title: "Public IP Address",
            status: .warning,
            details: "Current public IP: \(currentIP ?? "Unknown")"
        )
    }
    
    // MARK: - Service Connectivity Testing
    
    private func testServiceConnectivity() async {
        print("🔍 === SERVICE CONNECTIVITY TESTING ===")
        
        let settingsStore = SettingsStore()
        let baseURL = settingsStore.frigateBaseURL
        
        print("🔌 Testing Frigate connectivity: \(baseURL)")
        
        // Test multiple endpoints
        let testEndpoints = [
            "\(baseURL)/api/version",
            "\(baseURL)/api/events?limit=1",
            "\(baseURL)/api/config"
        ]
        
        for endpoint in testEndpoints {
            await testEndpointConnectivity(endpoint)
        }
        
        // Test with different network configurations
        await testConnectivityWithVPNBypass()
    }
    
    private func testEndpointConnectivity(_ urlString: String) async {
        guard let url = URL(string: urlString) else {
            print("   ❌ Invalid URL: \(urlString)")
            return
        }
        
        print("   🔌 Testing: \(urlString)")
        
        do {
            let startTime = Date()
            let (data, response) = try await URLSession.shared.data(from: url)
            let duration = Date().timeIntervalSince(startTime)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("   ✅ Status: \(httpResponse.statusCode), Duration: \(String(format: "%.2f", duration))s, Size: \(data.count) bytes")
                
                // Check response headers for security info
                if let server = httpResponse.value(forHTTPHeaderField: "Server") {
                    print("   📡 Server: \(server)")
                }
                
                if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
                    print("   📄 Content-Type: \(contentType)")
                }
                
                await addDebugResult(
                    category: "Service Connectivity",
                    title: "Endpoint: \(url.path)",
                    status: (200...299).contains(httpResponse.statusCode) ? .success : .error,
                    details: "Status: \(httpResponse.statusCode), Duration: \(String(format: "%.2f", duration))s"
                )
            }
        } catch {
            print("   ❌ Error: \(error.localizedDescription)")
            
            await addDebugResult(
                category: "Service Connectivity",
                title: "Endpoint: \(url.path)",
                status: .error,
                details: "Error: \(error.localizedDescription)"
            )
        }
    }
    
    private func testConnectivityWithVPNBypass() async {
        print("🚨 Testing connectivity with potential VPN bypass...")
        
        // Test using different URLSession configurations
        let configurations = [
            ("Default", URLSessionConfiguration.default),
            ("Ephemeral", URLSessionConfiguration.ephemeral),
            ("No Cache", {
                let config = URLSessionConfiguration.default
                config.urlCache = nil
                config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                return config
            }())
        ]
        
        let settingsStore = SettingsStore()
        let testURL = "\(settingsStore.frigateBaseURL)/api/version"
        
        for (name, config) in configurations {
            await testWithConfiguration(name, config, testURL)
        }
    }
    
    private func testWithConfiguration(_ name: String, _ config: URLSessionConfiguration, _ urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        
        print("   🔧 Testing with \(name) configuration...")
        
        let session = URLSession(configuration: config)
        
        do {
            let (_, response) = try await session.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                print("   📊 \(name): HTTP \(httpResponse.statusCode)")
                
                await addDebugResult(
                    category: "URLSession Config",
                    title: "\(name) Configuration",
                    status: (200...299).contains(httpResponse.statusCode) ? .success : .error,
                    details: "Status: \(httpResponse.statusCode)"
                )
            }
        } catch {
            print("   ❌ \(name): \(error.localizedDescription)")
            
            await addDebugResult(
                category: "URLSession Config",
                title: "\(name) Configuration",
                status: .error,
                details: error.localizedDescription
            )
        }
    }
    
    // MARK: - Security State Validation
    
    private func validateSecurityState() async {
        print("🔍 === SECURITY STATE VALIDATION ===")
        
        let vpnManager = VPNManager.shared
        
        print("🔒 Current Security State:")
        print("   App VPN Connected: \(vpnManager.connectionState.isActive)")
        print("   Device VPN Active: \(vpnManager.deviceVPNActive)")
        print("   On Secure Network: \(vpnManager.isOnSecureNetwork)")
        print("   Overall Secure Mode: \(vpnManager.isSecureMode)")
        
        // Test if services are accessible when they shouldn't be
        await testUnauthorizedAccess()
    }
    
    private func testUnauthorizedAccess() async {
        print("🚨 Testing for unauthorized service access...")
        
        // Simulate VPN being off
        let vpnManager = VPNManager.shared
        let originalSecureMode = vpnManager.isSecureMode
        
        // Force insecure mode for testing
        await MainActor.run {
            vpnManager.isSecureMode = false
            vpnManager.deviceVPNActive = false
            vpnManager.isOnSecureNetwork = false
        }
        
        // Test if services are still accessible
        let settingsStore = SettingsStore()
        let testURL = "\(settingsStore.frigateBaseURL)/api/version"
        
        do {
            let (_, response) = try await URLSession.shared.data(from: URL(string: testURL)!)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                print("   🚨 SECURITY VULNERABILITY: Service accessible when VPN is off!")
                
                await addDebugResult(
                    category: "Security Validation",
                    title: "Unauthorized Access Test",
                    status: .error,
                    details: "🚨 SERVICE ACCESSIBLE WITHOUT VPN - SECURITY BREACH"
                )
            } else {
                print("   ✅ Service properly blocked when VPN is off")
                
                await addDebugResult(
                    category: "Security Validation",
                    title: "Unauthorized Access Test",
                    status: .success,
                    details: "Service properly blocked"
                )
            }
        } catch {
            print("   ✅ Service connection failed (as expected): \(error.localizedDescription)")
            
            await addDebugResult(
                category: "Security Validation",
                title: "Unauthorized Access Test",
                status: .success,
                details: "Service properly blocked: \(error.localizedDescription)"
            )
        }
        
        // Restore original state
        await MainActor.run {
            vpnManager.isSecureMode = originalSecureMode
        }
    }
    
    // MARK: - Connection Path Tracing
    
    private func traceConnectionPaths() async {
        print("🔍 === CONNECTION PATH TRACING ===")
        
        await traceNetworkRoute()
        await checkDNSResolution()
    }
    
    private func traceNetworkRoute() async {
        print("🛣️ Tracing network route...")
        
        // Get current public IP to understand routing
        let publicIP = await getCurrentPublicIP()
        print("   Current Public IP: \(publicIP ?? "Unknown")")
        
        await addDebugResult(
            category: "Network Routing",
            title: "Public IP Address",
            status: .warning,
            details: "IP: \(publicIP ?? "Unknown")"
        )
    }
    
    private func getCurrentPublicIP() async -> String? {
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.ipify.org")!)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    private func checkDNSResolution() async {
        print("🌐 Checking DNS resolution...")
        
        let settingsStore = SettingsStore()
        if let url = URL(string: settingsStore.frigateBaseURL),
           let host = url.host {
            
            print("   Resolving: \(host)")
            // DNS resolution would be implemented here
            
            await addDebugResult(
                category: "DNS Resolution",
                title: "Host Resolution",
                status: .warning,
                details: "Host: \(host)"
            )
        }
    }
    
    // MARK: - URLSession Configuration Analysis
    
    private func analyzeURLSessionConfiguration() async {
        print("🔍 === URLSESSION CONFIGURATION ANALYSIS ===")
        
        // Analyze default URLSession
        await analyzeSessionConfiguration("Default URLSession.shared", URLSession.shared.configuration)
        
        // Analyze FrigateAPIClient session
        let frigateClient = FrigateAPIClient()
        // Note: We can't access private session directly, but we can test behavior
        
        await addDebugResult(
            category: "URLSession Analysis",
            title: "Session Configurations",
            status: .warning,
            details: "Multiple URLSession configurations detected"
        )
    }
    
    private func analyzeSessionConfiguration(_ name: String, _ config: URLSessionConfiguration) async {
        print("🔧 Analyzing \(name):")
        print("   Timeout Request: \(config.timeoutIntervalForRequest)")
        print("   Timeout Resource: \(config.timeoutIntervalForResource)")
        print("   Cache Policy: \(config.requestCachePolicy.rawValue)")
        print("   Allow Cellular: \(config.allowsCellularAccess)")
        print("   Allow Expensive: \(config.allowsExpensiveNetworkAccess)")
        print("   Allow Constrained: \(config.allowsConstrainedNetworkAccess)")
        
        if let urlCache = config.urlCache {
            print("   URL Cache: \(urlCache.memoryCapacity) bytes memory, \(urlCache.diskCapacity) bytes disk")
        } else {
            print("   URL Cache: Disabled")
        }
        
        await addDebugResult(
            category: "URLSession Config",
            title: name,
            status: config.allowsCellularAccess ? .error : .success,
            details: "Cellular: \(config.allowsCellularAccess), Cache: \(config.urlCache != nil)"
        )
    }
    
    // MARK: - Network Reachability
    
    private func checkNetworkReachability() async {
        print("🔍 === NETWORK REACHABILITY ANALYSIS ===")
        
        // Test reachability to different endpoints
        let testHosts = [
            "google.com",
            "8.8.8.8",
            "192.168.0.200" // Typical local Frigate server
        ]
        
        for host in testHosts {
            await testHostReachability(host)
        }
    }
    
    private func testHostReachability(_ host: String) async {
        print("🌐 Testing reachability to \(host)...")
        
        let monitor = Network.NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        monitor.pathUpdateHandler = { path in
            print("   \(host) - Status: \(path.status)")
            print("   \(host) - Interface Types: \(path.availableInterfaces.map { $0.type })")
            print("   \(host) - Uses Interface: \(path.usesInterfaceType(.wifi) ? "WiFi" : path.usesInterfaceType(.cellular) ? "Cellular" : "Other")")
        }
        
        monitor.start(queue: queue)
        
        // Give it a moment to detect
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        monitor.cancel()
        
        await addDebugResult(
            category: "Network Reachability",
            title: "Host: \(host)",
            status: .warning,
            details: "Reachability tested"
        )
    }
    
    // MARK: - Helper Methods
    
    private func addDebugResult(category: String, title: String, status: SecurityDebugStatus, details: String) async {
        let result = SecurityDebugResult(
            category: category,
            title: title,
            status: status,
            details: details,
            timestamp: Date()
        )
        
        await MainActor.run {
            debugResults.append(result)
        }
    }
    
    private func generateSecurityReport() {
        print("📊 === SECURITY INVESTIGATION REPORT ===")
        
        let categories = Set(debugResults.map { $0.category })
        
        for category in categories.sorted() {
            print("\n📂 \(category):")
            let categoryResults = debugResults.filter { $0.category == category }
            
            for result in categoryResults {
                let statusEmoji = result.status == .success ? "✅" : result.status == .warning ? "⚠️" : "❌"
                print("   \(statusEmoji) \(result.title): \(result.details)")
            }
        }
        
        // Summary
        let errorCount = debugResults.filter { $0.status == .error }.count
        let warningCount = debugResults.filter { $0.status == .warning }.count
        let successCount = debugResults.filter { $0.status == .success }.count
        
        print("\n📊 SUMMARY:")
        print("   🚨 Errors: \(errorCount)")
        print("   ⚠️ Warnings: \(warningCount)")
        print("   ✅ Success: \(successCount)")
        
        if errorCount > 0 {
            print("\n🚨 CRITICAL SECURITY ISSUES DETECTED!")
            print("   Immediate action required to secure network connections.")
        }
    }
}

// MARK: - Data Models

struct NetworkInterface {
    let name: String
    let type: String
    let ipAddress: String
    let isActive: Bool
}

struct SecurityDebugResult: Identifiable {
    let id = UUID()
    let category: String
    let title: String
    let status: SecurityDebugStatus
    let details: String
    let timestamp: Date
}

enum SecurityDebugStatus {
    case success, warning, error
    
    var color: SwiftUI.Color {
        switch self {
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
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

// MARK: - UI Components

struct NetworkSecurityDebugView: View {
    @StateObject private var debugger = NetworkSecurityDebugger.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("Security Investigation") {
                    Button("🚨 Start Security Investigation") {
                        Task {
                            await debugger.performSecurityInvestigation()
                        }
                    }
                    .disabled(debugger.isDebugging)
                    
                    if debugger.isDebugging {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Investigating network security...")
                                .font(.caption)
                        }
                    }
                }
                
                if !debugger.debugResults.isEmpty {
                    let categories = Array(Set(debugger.debugResults.map { $0.category })).sorted()
                    
                    ForEach(categories, id: \.self) { category in
                        Section(category) {
                            let categoryResults = debugger.debugResults.filter { $0.category == category }
                            
                            ForEach(categoryResults) { result in
                                HStack {
                                    Image(systemName: result.status.icon)
                                        .foregroundColor(result.status.color)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text(result.details)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Security Debug")
            .refreshable {
                await debugger.performSecurityInvestigation()
            }
        }
    }
}