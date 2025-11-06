//
//  CrookedServicesMockURLProtocol.swift
//  CrookedSentryTests
//
//  Network interception system bridging operational mocks with iOS URLSession
//  Ensures identical responses between Python operational scripts and iOS tests
//

import Foundation
@testable import CrookedSentry

/// URLProtocol that intercepts network requests and returns operational mock responses
/// This bridges your packaged infrastructure mocks with iOS URLSession requests
class CrookedServicesMockURLProtocol: URLProtocol {
    
    // MARK: - Configuration
    
    private static var isEnabled = false
    private static var interceptedHosts: Set<String> = [
        "192.168.0.200",
        "crookedservices.local", 
        "localhost",
        "127.0.0.1"
    ]
    
    // MARK: - URLProtocol Implementation
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard isEnabled,
              let url = request.url,
              let host = url.host else { return false }
        
        // Only intercept requests to our mock infrastructure hosts
        return interceptedHosts.contains(host) || 
               host.hasPrefix("192.168.0.") ||
               host.hasSuffix(".local")
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        
        // Determine service based on port and host
        let service = determineService(from: url)
        let endpoint = url.path.isEmpty ? "/" : url.path
        
        // Get operational mock response
        if let mockResponse = CrookedServicesMockData.getAPIResponse(service: service, endpoint: endpoint) {
            deliverMockResponse(mockResponse, for: url)
        } else {
            // Handle VPN bypass scenario or unknown endpoints
            handleUnknownEndpoint(url: url, service: service)
        }
    }
    
    override func stopLoading() {
        // No cleanup needed for our mock system
    }
    
    // MARK: - Service Detection
    
    private func determineService(from url: URL) -> String {
        let port = url.port
        let host = url.host ?? ""
        
        // Match operational infrastructure port mapping
        switch port {
        case 5000:
            return "frigate"
        case 8123:
            return "homeassistant"  
        case 80, 443:
            if host.contains("crookedkeys") || url.path.starts(with: "/whoami") {
                return "crookedkeys"
            }
            return "nginx"
        default:
            // Determine by host or path patterns
            if host.contains("frigate") || url.path.contains("frigate") {
                return "frigate"
            } else if host.contains("homeassistant") || host.contains("ha") {
                return "homeassistant"
            } else if url.path.starts(with: "/whoami") || url.path.starts(with: "/network-info") {
                return "crookedkeys"
            }
            return "unknown"
        }
    }
    
    // MARK: - Response Delivery
    
    private func deliverMockResponse(_ mockResponse: MockAPIResponse, for url: URL) {
        // Create HTTP response matching operational mock structure
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: mockResponse.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: mockResponse.headers
        )
        
        guard let response = httpResponse else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotCreateFile))
            return
        }
        
        // Simulate network delay based on mock mode
        let delay = getNetworkDelay()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: mockResponse.data)
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    private func handleUnknownEndpoint(url: URL, service: String) {
        let currentMode = CrookedServicesMockData.currentMode
        
        // Handle VPN bypass scenarios and service outages
        switch currentMode {
        case .offline:
            // Simulate complete service outage
            let error = URLError(.timedOut)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.client?.urlProtocol(self!, didFailWithError: error)
            }
            
        case .degraded:
            // Simulate intermittent failures deterministically for tests
            // (avoid randomness to prevent flaky test results)
            deliverServiceUnavailableResponse(for: url)
            
        default:
            // Unknown endpoint - return 404
            deliverNotFoundResponse(for: url)
        }
    }
    
    private func deliverServiceUnavailableResponse(for url: URL) {
        let response = HTTPURLResponse(
            url: url,
            statusCode: 503,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        
        let errorData = """
        {
          "error": "Service Temporarily Unavailable",
          "message": "Service is experiencing intermittent issues",
          "retry_after": 30,
          "mode": "\(CrookedServicesMockData.currentMode.rawValue)"
        }
        """.data(using: .utf8)!
        
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: errorData)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    private func deliverNotFoundResponse(for url: URL) {
        let response = HTTPURLResponse(
            url: url,
            statusCode: 404,
            httpVersion: "HTTP/1.1", 
            headerFields: ["Content-Type": "application/json"]
        )!
        
        let errorData = """
        {
          "error": "Not Found",
          "message": "The requested endpoint was not found",
          "endpoint": "\(url.path)",
          "available_endpoints": ["/api/version", "/api/config", "/api/events", "/api/states", "/whoami"]
        }
        """.data(using: .utf8)!
        
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: errorData)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    // MARK: - Network Simulation
    
    private func getNetworkDelay() -> TimeInterval {
        let mode = CrookedServicesMockData.currentMode
        
        switch mode {
        case .healthy:
            return 0.1                                 // Fast and deterministic
        case .degraded:
            return 0.8                                 // Slower, deterministic to avoid flakiness
        case .offline:
            return 0.6                                // Quick failure to keep overall tests performant
        case .testing:
            return 0.1                                // Predictable timing
        }
    }
}

// MARK: - Mock Protocol Management

extension CrookedServicesMockURLProtocol {
    
    /// Enable operational mock interception for testing
    static func enableMocking() {
        guard !isEnabled else { return }
        
        URLProtocol.registerClass(CrookedServicesMockURLProtocol.self)
        isEnabled = true
        
        print("🌐 Operational mock URL protocol enabled")
        print("🎯 Intercepting hosts: \(interceptedHosts.joined(separator: ", "))")
    }
    
    /// Disable mock interception (restore normal networking)
    static func disableMocking() {
        guard isEnabled else { return }
        
        URLProtocol.unregisterClass(CrookedServicesMockURLProtocol.self)
        isEnabled = false
        
        print("🌐 Operational mock URL protocol disabled")
    }
    
    /// Add custom host for interception
    static func addInterceptedHost(_ host: String) {
        interceptedHosts.insert(host)
        print("🎯 Added intercepted host: \(host)")
    }
    
    /// Remove host from interception
    static func removeInterceptedHost(_ host: String) {
        interceptedHosts.remove(host)
        print("🎯 Removed intercepted host: \(host)")
    }
    
    /// Check if mocking is currently active
    static var isMockingEnabled: Bool {
        return isEnabled
    }
}

// MARK: - VPN Bypass Investigation Support

extension CrookedServicesMockURLProtocol {
    
    /// Simulate VPN bypass vulnerability scenario
    /// When VPN is "active" but local services remain accessible
    static func simulateVPNBypassScenario() {
        // In real VPN bypass, local services would be accessible despite VPN
        // Our mock simulates this by allowing local traffic in "VPN active" mode
        
        CrookedServicesMockData.setMode(.testing)
        
        // Add VPN-specific mock responses
        let vpnBypassResponse = MockAPIResponse(
            statusCode: 200,
            data: """
            {
              "vpn_bypass_detected": true,
              "local_services_accessible": true,
              "security_risk": "HIGH",
              "recommendation": "Activate kill switch immediately",
              "affected_services": [
                "192.168.0.200:5000",
                "192.168.0.200:8123",
                "crookedservices.local:80"
              ]
            }
            """.data(using: .utf8)!,
            headers: ["Content-Type": "application/json", "X-Security-Alert": "VPN-Bypass-Detected"]
        )
        
        // This would normally be blocked by VPN, but bypass allows it through
        print("🚨 Simulating VPN bypass vulnerability scenario")
        print("⚠️  Local services accessible despite VPN active state")
    }
    
    /// Simulate normal VPN operation (local services blocked)
    static func simulateNormalVPNOperation() {
        CrookedServicesMockData.setMode(.offline)
        // Also reflect VPN connected state in network/SSH infrastructure so
        // helpers like testSSHConnectivity(expectSuccess: false) behave correctly.
        MockNetworkInfrastructure.shared.simulateVPNState(.connected)
        print("🔒 Simulating normal VPN operation - local services blocked")
    }
}

// MARK: - Integration with Existing Mock Infrastructure

extension CrookedServicesMockURLProtocol {
    
    /// Bridge with existing MockNetworkInfrastructure for compatibility
    static func bridgeWithExistingMocks() {
        // Sync with existing mock state
        let existingMockInfra = MockNetworkInfrastructure.shared
        
        // Apply VPN state from existing mocks
        switch existingMockInfra.simulatedVPNState {
        case .connected:
            // VPN active - use appropriate mode based on bypass detection
            if existingMockInfra.simulateVPNBypassScenario().bypassDetected {
                CrookedServicesMockData.setMode(.testing)  // Bypass scenario
            } else {
                CrookedServicesMockData.setMode(.offline)   // Normal VPN blocking
            }
        case .disconnected:
            CrookedServicesMockData.setMode(.healthy)      // Normal operation
        case .connecting, .disconnecting, .error:
            CrookedServicesMockData.setMode(.degraded)     // Unstable connectivity or error
        }
        
        print("🔄 Bridged operational mocks with existing infrastructure")
        print("📊 Current mode: \(CrookedServicesMockData.currentMode.rawValue)")
    }
}