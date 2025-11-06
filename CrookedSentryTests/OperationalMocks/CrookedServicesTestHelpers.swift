//
//  CrookedServicesTestHelpers.swift
//  CrookedSentryTests
//
//  XCTest integration utilities for operational mock infrastructure
//  Provides base test classes and utilities for seamless mock integration
//

import XCTest
import Foundation
@testable import CrookedSentry

/// Base test class that automatically configures operational mock infrastructure
/// Inherit from this class to get consistent mock setup across all tests
class CrookedServicesTestCase: XCTestCase {
    
    // MARK: - Test Configuration
    
    /// Override this in subclasses to set the default mock mode
    var defaultMockMode: CrookedServicesMockData.MockMode { .healthy }
    
    /// Override this to customize which hosts should be mocked
    var mockedHosts: [String] { 
        ["192.168.0.200", "crookedservices.local", "localhost"] 
    }
    
    /// Override this to disable automatic mock setup
    var enableAutomaticMocking: Bool { true }
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        
        if enableAutomaticMocking {
            setupOperationalMocks()
        }
    }
    
    override func tearDown() {
        if enableAutomaticMocking {
            cleanupOperationalMocks()
        }
        
        super.tearDown()
    }
    
    // MARK: - Mock Setup Methods
    
    /// Configure operational mock infrastructure for testing
    func setupOperationalMocks() {
        // Enable URL protocol interception
        CrookedServicesMockURLProtocol.enableMocking()
        
        // Configure additional hosts
        for host in mockedHosts {
            CrookedServicesMockURLProtocol.addInterceptedHost(host)
        }
        
        // Set initial mock mode
        CrookedServicesMockData.setMode(defaultMockMode)
        
        // Bridge with existing mock infrastructure
        CrookedServicesMockURLProtocol.bridgeWithExistingMocks()

    // Ensure the test-defined default mock mode wins — bridge may reflect
    // global simulated VPN state; tests should be able to override it.
    CrookedServicesMockData.setMode(defaultMockMode)
        
        print("🧪 Test setup: Operational mocks configured in \(defaultMockMode.rawValue) mode")
    }
    
    /// Clean up mock infrastructure after testing
    func cleanupOperationalMocks() {
        CrookedServicesMockURLProtocol.disableMocking()
        CrookedServicesMockData.setMode(.healthy) // Reset to default
        
        print("🧹 Test cleanup: Operational mocks disabled")
    }
}

// MARK: - Mock Mode Test Utilities

extension CrookedServicesTestCase {
    
    /// Test a specific scenario across all mock modes
    func testAcrossAllModes(_ testBlock: @escaping (CrookedServicesMockData.MockMode) -> Void) {
        for mode in CrookedServicesMockData.MockMode.allCases {
            print("🎛️ Testing in \(mode.rawValue) mode")
            CrookedServicesMockData.setMode(mode)
            testBlock(mode)
        }
    }
    
    /// Temporarily switch to a different mock mode for a test block
    func withMockMode<T>(_ mode: CrookedServicesMockData.MockMode, execute: () throws -> T) rethrows -> T {
        let originalMode = CrookedServicesMockData.currentMode
        CrookedServicesMockData.setMode(mode)
        
        defer {
            CrookedServicesMockData.setMode(originalMode)
        }
        
        return try execute()
    }
    
    /// Test VPN bypass vulnerability scenario
    func testVPNBypassScenario(_ testBlock: @escaping () -> Void) {
        withMockMode(.testing) {
            // Simulate bypass: leave network infra as "not blocking" so local services are accessible
            MockNetworkInfrastructure.shared.simulateVPNState(.disconnected)
            CrookedServicesMockURLProtocol.simulateVPNBypassScenario()
            testBlock()
            // No VPN state change needed after bypass scenario
        }
    }
    
    /// Test normal VPN operation (services blocked)
    func testNormalVPNOperation(_ testBlock: @escaping () -> Void) {
        withMockMode(.offline) {
            // Block local services while VPN is connected
            MockNetworkInfrastructure.shared.simulateVPNState(.connected)
            CrookedServicesMockURLProtocol.simulateNormalVPNOperation()
            testBlock()
            // Restore default network state
            MockNetworkInfrastructure.shared.simulateVPNState(.disconnected)
        }
    }
}

// MARK: - Network Request Test Helpers

extension CrookedServicesTestCase {
    
    /// Make a mock API request and validate the response
        func makeMockAPIRequest(
        to endpoint: String,
        service: String,
        expectedStatus: Int = 200,
            timeout: TimeInterval = 6.0,
        completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void
    ) {
        let baseURL: String
        
        switch service.lowercased() {
        case "frigate":
            baseURL = "http://192.168.0.200:5000"
        case "homeassistant", "ha":
            baseURL = "http://192.168.0.200:8123"
        case "crookedkeys":
            baseURL = "http://crookedservices.local"
        default:
            baseURL = "http://localhost"
        }
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            XCTFail("Invalid URL: \(baseURL)\(endpoint)")
            return
        }
        
        let expectation = XCTestExpectation(description: "API request to \(endpoint)")
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { expectation.fulfill() }
            
            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, expectedStatus, 
                             "Expected status \(expectedStatus), got \(httpResponse.statusCode)")
            }
            
            completion(data, response as? HTTPURLResponse, error)
        }
        
        task.resume()
        wait(for: [expectation], timeout: timeout)
    }
    
    /// Test Frigate API endpoint with operational mock data
    func testFrigateAPI(endpoint: String, expectedStatus: Int = 200) {
        makeMockAPIRequest(to: endpoint, service: "frigate", expectedStatus: expectedStatus) { data, response, error in
            XCTAssertNil(error, "Frigate API request should not fail")
            XCTAssertNotNil(data, "Frigate API should return data")
            
            if let data = data,
               let jsonString = String(data: data, encoding: .utf8) {
                print("📡 Frigate API Response (\(endpoint)): \(jsonString)")
            }
        }
    }
    
    /// Test Home Assistant API endpoint with operational mock data
    func testHomeAssistantAPI(endpoint: String, expectedStatus: Int = 200) {
        makeMockAPIRequest(to: endpoint, service: "homeassistant", expectedStatus: expectedStatus) { data, response, error in
            XCTAssertNil(error, "Home Assistant API request should not fail")
            XCTAssertNotNil(data, "Home Assistant API should return data")
            
            if let data = data,
               let jsonString = String(data: data, encoding: .utf8) {
                print("🏠 Home Assistant API Response (\(endpoint)): \(jsonString)")
            }
        }
    }
    
    /// Test CrookedKeys API endpoint (network info/whoami)
    func testCrookedKeysAPI(endpoint: String, expectedStatus: Int = 200) {
        makeMockAPIRequest(to: endpoint, service: "crookedkeys", expectedStatus: expectedStatus) { data, response, error in
            XCTAssertNil(error, "CrookedKeys API request should not fail")
            XCTAssertNotNil(data, "CrookedKeys API should return data")
            
            if let data = data,
               let jsonString = String(data: data, encoding: .utf8) {
                print("🔑 CrookedKeys API Response (\(endpoint)): \(jsonString)")
            }
        }
    }
}

// MARK: - SSH Mock Test Helpers

extension CrookedServicesTestCase {
    
    /// Simulate SSH command execution using operational mock data
    func simulateSSHCommand(_ command: String, expectedExitCode: Int? = nil) -> SSHCommandResult? {
        let result = CrookedServicesMockData.getSSHResponse(command: command)
        
        if let result = result {
            if let expected = expectedExitCode {
                XCTAssertEqual(result.exitCode, expected,
                               "SSH command '\(command)' expected exit code \(expected), got \(result.exitCode)")
            }
            print("🖥️  SSH Command: \(command)")
            print("   Exit Code: \(result.exitCode)")
            print("   Stdout: \(result.stdout)")
            if !result.stderr.isEmpty {
                print("   Stderr: \(result.stderr)")
            }
        }
        
        return result
    }
    
    /// Test SSH connectivity with operational mock responses
    func testSSHConnectivity(expectSuccess: Bool = true) {
        let sshInfra = MockSSHInfrastructure.shared
        let result = sshInfra.simulateSSHConnection(host: "192.168.0.200", user: "pi")
        
        if expectSuccess {
            XCTAssertTrue(result.success, "SSH connection should succeed: \(result.error ?? "unknown error")")
            XCTAssertNotNil(result.connectionTime, "Should have connection timing")
        } else {
            XCTAssertFalse(result.success, "SSH connection should fail")
            XCTAssertNotNil(result.error, "Should have error message")
        }
    }
}

// MARK: - Network Connectivity Test Helpers

extension CrookedServicesTestCase {
    
    /// Test network connectivity using operational mock data
    func testNetworkConnectivity(host: String, expectReachable: Bool = true) {
        if let result = CrookedServicesMockData.getNetworkResult(host: host) {
            if expectReachable {
                XCTAssertTrue(result.isReachable, "Host \(host) should be reachable: \(result.error ?? "unknown error")")
                XCTAssertNotNil(result.latency, "Reachable host should have latency measurement")
                XCTAssertLessThan(result.packetLoss, 50.0, "Reachable host should have low packet loss")
            } else {
                XCTAssertFalse(result.isReachable, "Host \(host) should not be reachable")
            }
            
            print("🌐 Network Test - \(host): reachable=\(result.isReachable), latency=\(result.latency ?? -1)ms, loss=\(result.packetLoss)%")
        } else {
            XCTFail("No network connectivity data for host: \(host)")
        }
    }
}

// MARK: - VPN Investigation Test Utilities

extension CrookedServicesTestCase {
    
    /// Perform comprehensive VPN bypass investigation using operational mocks
    func performVPNBypassInvestigation() -> VPNBypassInvestigationResult {
        var results: [String: Any] = [:]
        
        // Test network connectivity (should fail if VPN properly blocks)
        testNetworkConnectivity(host: "192.168.0.200", expectReachable: false)
        testNetworkConnectivity(host: "crookedservices.local", expectReachable: false)
        
        // Test SSH connectivity (should fail if VPN properly blocks)
        testSSHConnectivity(expectSuccess: false)
        
        // Test API accessibility
        testFrigateAPI(endpoint: "/api/version", expectedStatus: 503) // Should be blocked
        testHomeAssistantAPI(endpoint: "/api/config", expectedStatus: 503) // Should be blocked
        
        // Test CrookedKeys (should work - external service)
        testCrookedKeysAPI(endpoint: "/whoami", expectedStatus: 200)
        
        return VPNBypassInvestigationResult(
            vpnActive: true,
            localServicesBlocked: true,
            bypassDetected: false,
            investigationComplete: true
        )
    }
    
    /// Test the VPN bypass vulnerability scenario
    func performVPNBypassVulnerabilityTest() -> VPNBypassInvestigationResult {
        testVPNBypassScenario {
            // In bypass scenario, local services remain accessible despite VPN
            self.testNetworkConnectivity(host: "192.168.0.200", expectReachable: true)
            self.testSSHConnectivity(expectSuccess: true)
            self.testFrigateAPI(endpoint: "/api/version", expectedStatus: 200)
        }
        
        return VPNBypassInvestigationResult(
            vpnActive: true,
            localServicesBlocked: false,
            bypassDetected: true,
            investigationComplete: true
        )
    }
}

// MARK: - Investigation Result Types

struct VPNBypassInvestigationResult {
    let vpnActive: Bool
    let localServicesBlocked: Bool
    let bypassDetected: Bool
    let investigationComplete: Bool
    
    var securityRisk: String {
        if bypassDetected {
            return "HIGH - VPN bypass vulnerability detected"
        } else if vpnActive && localServicesBlocked {
            return "LOW - VPN operating normally"
        } else {
            return "MEDIUM - Inconclusive results"
        }
    }
}

// MARK: - Integration Validation Helpers

extension CrookedServicesTestCase {
    
    /// Validate that operational mock responses match expected format
    func validateOperationalMockIntegration() {
        // Test that all mock modes have required endpoints
        for mode in CrookedServicesMockData.MockMode.allCases {
            CrookedServicesMockData.setMode(mode)
            
            // Validate Frigate API responses exist
            XCTAssertNotNil(CrookedServicesMockData.getAPIResponse(service: "frigate", endpoint: "/api/version"),
                          "Frigate /api/version should exist in \(mode) mode")
            
            // Validate SSH responses exist for healthy mode
            if mode == .healthy {
                XCTAssertNotNil(CrookedServicesMockData.getSSHResponse(command: "whoami"),
                              "SSH whoami command should exist in healthy mode")
                XCTAssertNotNil(CrookedServicesMockData.getNetworkResult(host: "192.168.0.200"),
                              "Network result for Pi should exist in healthy mode")
            }
        }
        
        print("✅ Operational mock integration validation complete")
    }
    
    /// Test cross-repo consistency between Python and iOS mocks
    func validateCrossRepoConsistency() {
        // Test that iOS mock responses match expected operational format
        
        CrookedServicesMockData.setMode(.healthy)
        
        // Validate Frigate version response format
        if let versionResponse = CrookedServicesMockData.getAPIResponse(service: "frigate", endpoint: "/api/version"),
           let jsonData = try? JSONSerialization.jsonObject(with: versionResponse.data) as? [String: Any] {
            
            XCTAssertNotNil(jsonData["version"], "Frigate version response should have 'version' field")
            XCTAssertNotNil(jsonData["api_version"], "Frigate version response should have 'api_version' field")
            XCTAssertEqual(jsonData["version"] as? String, "0.13.2", "Version should match operational mock")
        } else {
            XCTFail("Could not parse Frigate version response")
        }
        
        print("✅ Cross-repo consistency validation complete")
    }
}