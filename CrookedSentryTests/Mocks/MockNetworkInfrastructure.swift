//
//  MockNetworkInfrastructure.swift
//  CrookedSentryTests
//
//  Created by Assistant on 2025
//

import Foundation
import Network
@testable import CrookedSentry

/// Mock infrastructure that simulates the real Pi/home automation environment
/// Matches the operational mock infrastructure for consistent testing
class MockNetworkInfrastructure {
    
    // MARK: - Mock Configuration
    
    static let shared = MockNetworkInfrastructure()
    
    /// Simulated Pi server hosts from infrastructure mocks
    let mockHosts: [String: MockHost] = [
        "192.168.0.200": MockHost(
            name: "crookedservices.local",
            ip: "192.168.0.200",
            services: [
                .frigate(port: 5000, version: "0.13.2"),
                .homeAssistant(port: 8123, version: "2023.11.3"),
                .nginx(port: 80),
                .ssh(port: 22),
                .wireguard(port: 51820)
            ]
        ),
        "crookedservices.local": MockHost(
            name: "crookedservices.local", 
            ip: "192.168.0.200",
            services: [
                .frigate(port: 5000, version: "0.13.2"),
                .homeAssistant(port: 8123, version: "2023.11.3")
            ]
        )
    ]
    
    /// Mock API responses matching infrastructure HTTP mock
    let mockAPIResponses: [String: MockAPIResponse] = [
        "/api/version": MockAPIResponse(
            statusCode: 200,
            data: """
                {"version": "0.13.2", "api_version": "1.0"}
                """.data(using: .utf8)!,
            headers: ["Content-Type": "application/json"]
        ),
        "/api/config": MockAPIResponse(
            statusCode: 200,
            data: """
                {
                  "cameras": {
                    "backyard": {"name": "backyard"},
                    "cam1": {"name": "cam1"}
                  }
                }
                """.data(using: .utf8)!,
            headers: ["Content-Type": "application/json"]
        ),
        "/api/events": MockAPIResponse(
            statusCode: 200,
            data: """
                [
                  {
                    "id": "test-event-1",
                    "camera": "backyard", 
                    "label": "person",
                    "start_time": 1699142400.0,
                    "end_time": 1699142460.0,
                    "has_clip": true,
                    "has_snapshot": true,
                    "zones": ["driveway"],
                    "data": {
                      "score": 0.85,
                      "top_score": 0.92,
                      "type": "object"
                    }
                  }
                ]
                """.data(using: .utf8)!,
            headers: ["Content-Type": "application/json"]
        ),
        "/whoami": MockAPIResponse(
            statusCode: 200,
            data: """
                {
                  "ip": "192.168.0.100",
                  "hostname": "iPhone-Test",
                  "vpn_detected": false,
                  "network": "local"
                }
                """.data(using: .utf8)!,
            headers: ["Content-Type": "application/json"]
        )
    ]
    
    // MARK: - VPN State Simulation
    
    var simulatedVPNState: VPNConnectionState = .disconnected
    var simulatedNetworkInterface: String = "en0" // WiFi by default
    
    /// Simulate different VPN states for testing bypass scenarios
    func simulateVPNState(_ state: VPNConnectionState) {
        simulatedVPNState = state
    }
    
    /// Simulate network interface changes (WiFi, Cellular, VPN)
    func simulateNetworkInterface(_ interface: String) {
        simulatedNetworkInterface = interface
    }
    
    // MARK: - Network Connectivity Simulation
    
    /// Simulate network reachability like infrastructure ping mock
    func simulateNetworkReachability(host: String) -> NetworkReachabilityResult {
        guard let mockHost = mockHosts[host] else {
            return NetworkReachabilityResult(
                isReachable: false,
                latency: nil,
                error: "Host not found: \(host)"
            )
        }
        
        // Simulate different connectivity scenarios
        switch simulatedVPNState {
        case .connected:
            // When VPN is connected, home services should NOT be reachable
            if host.contains("192.168.0") || host.contains("crookedservices") {
                return NetworkReachabilityResult(
                    isReachable: false,
                    latency: nil,
                    error: "Timeout: VPN blocks local network access"
                )
            }
        case .disconnected:
            // When VPN is disconnected, local services should be reachable
            if host.contains("192.168.0") || host.contains("crookedservices") {
                return NetworkReachabilityResult(
                    isReachable: true,
                    latency: 12.5, // Typical local network latency
                    error: nil
                )
            }
        case .connecting, .disconnecting, .error:
            // Unstable connectivity during transitions or errors
            return NetworkReachabilityResult(
                isReachable: Bool.random(),
                latency: Bool.random() ? Double.random(in: 10...100) : nil,
                error: Bool.random() ? "Connection unstable" : nil
            )
        }
        
        return NetworkReachabilityResult(isReachable: true, latency: 25.0, error: nil)
    }
    
    /// Simulate port connectivity like infrastructure nc mock
    func simulatePortConnectivity(host: String, port: Int) -> PortConnectivityResult {
        guard let mockHost = mockHosts[host] else {
            return PortConnectivityResult(isOpen: false, error: "Host not found")
        }
        
        let hasService = mockHost.services.contains { service in
            switch service {
            case .frigate(let p, _): return p == port
            case .homeAssistant(let p, _): return p == port
            case .nginx(let p): return p == port
            case .ssh(let p): return p == port
            case .wireguard(let p): return p == port
            }
        }
        
        // Apply VPN state logic
        if simulatedVPNState == .connected && (host.contains("192.168.0") || host.contains("crookedservices")) {
            return PortConnectivityResult(isOpen: false, error: "VPN blocks local access")
        }
        
        return PortConnectivityResult(isOpen: hasService, error: hasService ? nil : "Connection refused")
    }
    
    // MARK: - Security Investigation Simulation
    
    /// Simulate the VPN bypass vulnerability scenario
    func simulateVPNBypassScenario() -> VPNBypassSimulation {
        return VPNBypassSimulation(
            reportedVPNState: .connected,        // iOS reports VPN as connected
            actualNetworkAccess: .local,         // But actually accessing local network
            bypassDetected: true,                // Security framework detects the bypass
            affectedServices: [
                "192.168.0.200:5000",           // Frigate accessible when it shouldn't be
                "192.168.0.200:8123",           // Home Assistant accessible
                "crookedservices.local:80"       // Nginx accessible
            ],
            securityRisk: .high,
            recommendedAction: .killSwitchActivation
        )
    }
}

// MARK: - Mock Data Structures

struct MockHost {
    let name: String
    let ip: String
    let services: [MockService]
}

enum MockService {
    case frigate(port: Int, version: String)
    case homeAssistant(port: Int, version: String) 
    case nginx(port: Int)
    case ssh(port: Int)
    case wireguard(port: Int)
}

// Use MockAPIResponse from OperationalMocks/CrookedServicesMockData.swift

struct NetworkReachabilityResult {
    let isReachable: Bool
    let latency: Double? // milliseconds
    let error: String?
}

struct PortConnectivityResult {
    let isOpen: Bool
    let error: String?
}

// MARK: - VPN Bypass Investigation Types

// Use VPNConnectionState from main app (VPNManager.swift)

enum NetworkAccessType {
    case local      // Accessing local network (192.168.x.x)
    case external   // Accessing internet
    case vpnTunnel  // Accessing through VPN tunnel
}

enum SecurityRiskLevel {
    case low, medium, high, critical
}

enum SecurityAction {
    case monitoring
    case alerting
    case killSwitchActivation
    case emergencyShutdown
}

struct VPNBypassSimulation {
    let reportedVPNState: VPNConnectionState
    let actualNetworkAccess: NetworkAccessType
    let bypassDetected: Bool
    let affectedServices: [String]
    let securityRisk: SecurityRiskLevel
    let recommendedAction: SecurityAction
}

// MARK: - URLProtocol Mock for HTTP Testing

class MockURLProtocol: URLProtocol {
    
    static var mockResponses: [String: MockAPIResponse] = [:]
    
    override class func canInit(with request: URLRequest) -> Bool {
        // Only handle requests to our mock infrastructure
        guard let url = request.url,
              let host = url.host else { return false }
        
        return host.contains("192.168.0") || 
               host.contains("crookedservices") ||
               host.contains("localhost")
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        
        let path = url.path.isEmpty ? "/" : url.path
        let mockInfra = MockNetworkInfrastructure.shared
        
        // Check if we have a mock response for this path
        if let mockResponse = mockInfra.mockAPIResponses[path] {
            let response = HTTPURLResponse(
                url: url,
                statusCode: mockResponse.statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: mockResponse.headers
            )!
            
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: mockResponse.data)
            client?.urlProtocolDidFinishLoading(self)
        } else {
            // Simulate network error for unknown endpoints
            let error = URLError(.resourceUnavailable)
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {
        // No cleanup needed for our simple mock
    }
}

// MARK: - Test Helper Extensions

extension MockNetworkInfrastructure {
    
    /// Configure for VPN bypass vulnerability testing
    func configureForVPNBypassTesting() {
        simulateVPNState(.connected)
        simulateNetworkInterface("ipsec0") // VPN interface
        
        // Register URL protocol for HTTP mocking
        MockURLProtocol.mockResponses = mockAPIResponses
        URLProtocol.registerClass(MockURLProtocol.self)
    }
    
    /// Configure for normal operation testing  
    func configureForNormalOperation() {
        simulateVPNState(.disconnected)
        simulateNetworkInterface("en0") // WiFi interface
        
        URLProtocol.registerClass(MockURLProtocol.self)
    }
    
    /// Reset all mock states
    func reset() {
        simulateVPNState(.disconnected)
        simulateNetworkInterface("en0")
        URLProtocol.unregisterClass(MockURLProtocol.self)
    }
}