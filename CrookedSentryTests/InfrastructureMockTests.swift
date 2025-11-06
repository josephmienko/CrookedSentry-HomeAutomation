//
//  InfrastructureMockTests.swift
//  CrookedSentryTests
//
//  Created by Assistant on 2025
//

import XCTest
import Network
@testable import CrookedSentry

/// Integration tests for the mock infrastructure system
/// Validates that mocks accurately represent the operational environment
class InfrastructureMockTests: XCTestCase {
    
    var mockNetworkInfra: MockNetworkInfrastructure!
    var mockSSHInfra: MockSSHInfrastructure!
    
    override func setUp() {
        super.setUp()
        mockNetworkInfra = MockNetworkInfrastructure.shared
        mockSSHInfra = MockSSHInfrastructure.shared
        
        // Reset to clean state
        mockNetworkInfra.reset()
    }
    
    override func tearDown() {
        mockNetworkInfra.reset()
        super.tearDown()
    }
    
    // MARK: - Network Infrastructure Tests
    
    func testMockNetworkInfrastructure_NormalOperation() {
        // Given: Normal operation (VPN disconnected)
        mockNetworkInfra.configureForNormalOperation()
        
        // When: Testing connectivity to local services
        let frigateReachability = mockNetworkInfra.simulateNetworkReachability(host: "192.168.0.200")
        let haReachability = mockNetworkInfra.simulateNetworkReachability(host: "crookedservices.local")
        
        // Then: Local services should be reachable
        XCTAssertTrue(frigateReachability.isReachable, "Frigate should be reachable when VPN is off")
        XCTAssertTrue(haReachability.isReachable, "Home Assistant should be reachable when VPN is off")
        XCTAssertNotNil(frigateReachability.latency, "Should have latency measurement")
        XCTAssertLessThan(frigateReachability.latency!, 50.0, "Local network latency should be low")
    }
    
    func testMockNetworkInfrastructure_VPNBypassScenario() {
        // Given: VPN is reported as connected
        mockNetworkInfra.configureForVPNBypassTesting()
        
        // When: Testing connectivity to local services (should fail)
        let frigateReachability = mockNetworkInfra.simulateNetworkReachability(host: "192.168.0.200")
        let haReachability = mockNetworkInfra.simulateNetworkReachability(host: "crookedservices.local")
        
        // Then: Local services should NOT be reachable through VPN
        XCTAssertFalse(frigateReachability.isReachable, "Frigate should NOT be reachable when VPN is active")
        XCTAssertFalse(haReachability.isReachable, "Home Assistant should NOT be reachable when VPN is active")
        XCTAssertNotNil(frigateReachability.error, "Should have error explaining VPN block")
        XCTAssertTrue(frigateReachability.error!.contains("VPN"), "Error should mention VPN")
    }
    
    func testMockNetworkInfrastructure_PortConnectivity() {
        // Given: Normal operation
        mockNetworkInfra.configureForNormalOperation()
        
        // When: Testing specific port connectivity
        let frigatePort = mockNetworkInfra.simulatePortConnectivity(host: "192.168.0.200", port: 5000)
        let haPort = mockNetworkInfra.simulatePortConnectivity(host: "192.168.0.200", port: 8123)
        let unknownPort = mockNetworkInfra.simulatePortConnectivity(host: "192.168.0.200", port: 9999)
        
        // Then: Known services should be open, unknown should be closed
        XCTAssertTrue(frigatePort.isOpen, "Frigate port 5000 should be open")
        XCTAssertTrue(haPort.isOpen, "Home Assistant port 8123 should be open")
        XCTAssertFalse(unknownPort.isOpen, "Unknown port 9999 should be closed")
        XCTAssertNil(frigatePort.error, "Open ports should not have errors")
        XCTAssertNotNil(unknownPort.error, "Closed ports should have error message")
    }
    
    func testMockNetworkInfrastructure_VPNBypassSimulation() {
        // Given: VPN bypass scenario setup
        mockNetworkInfra.configureForVPNBypassTesting()
        
        // When: Running full VPN bypass simulation
        let simulation = mockNetworkInfra.simulateVPNBypassScenario()
        
        // Then: Should detect bypass vulnerability
        XCTAssertEqual(simulation.reportedVPNState, .connected, "VPN should be reported as connected")
        XCTAssertEqual(simulation.actualNetworkAccess, .local, "Should detect local network access")
        XCTAssertTrue(simulation.bypassDetected, "Should detect VPN bypass")
        XCTAssertEqual(simulation.securityRisk, .high, "Should classify as high security risk")
        XCTAssertEqual(simulation.recommendedAction, .killSwitchActivation, "Should recommend kill switch")
        XCTAssertFalse(simulation.affectedServices.isEmpty, "Should list affected services")
        XCTAssertTrue(simulation.affectedServices.contains("192.168.0.200:5000"), "Should include Frigate service")
    }
    
    // MARK: - SSH Infrastructure Tests
    
    func testMockSSHInfrastructure_NormalConnection() {
        // Given: Normal network conditions (VPN off)
        mockNetworkInfra.configureForNormalOperation()
        
        // When: Attempting SSH connection to Pi
        let connectionResult = mockSSHInfra.simulateSSHConnection(host: "192.168.0.200", user: "pi")
        
        // Then: Connection should succeed
        XCTAssertTrue(connectionResult.success, "SSH connection should succeed when VPN is off")
        XCTAssertNil(connectionResult.error, "Should not have connection error")
        XCTAssertNotNil(connectionResult.connectionTime, "Should have connection timing")
        XCTAssertNotNil(connectionResult.hostKey, "Should receive host key")
        XCTAssertLessThan(connectionResult.connectionTime!, 1.0, "Connection should be fast on local network")
    }
    
    func testMockSSHInfrastructure_VPNBlocksSSH() {
        // Given: VPN is active (should block local SSH)
        mockNetworkInfra.configureForVPNBypassTesting()
        
        // When: Attempting SSH connection to Pi
        let connectionResult = mockSSHInfra.simulateSSHConnection(host: "192.168.0.200", user: "pi")
        
        // Then: Connection should fail due to VPN
        XCTAssertFalse(connectionResult.success, "SSH connection should fail when VPN is active")
        XCTAssertNotNil(connectionResult.error, "Should have connection error")
        XCTAssertTrue(connectionResult.error!.contains("timed out"), "Error should indicate timeout")
        XCTAssertNil(connectionResult.connectionTime, "Failed connection should not have timing")
        XCTAssertNil(connectionResult.hostKey, "Failed connection should not have host key")
    }
    
    func testMockSSHInfrastructure_CommandExecution() {
        // Given: Successful SSH connection
        mockNetworkInfra.configureForNormalOperation()
        _ = mockSSHInfra.simulateSSHConnection(host: "192.168.0.200", user: "pi")
        
        // When: Executing various SSH commands
        let whoamiResult = mockSSHInfra.executeSSHCommand(host: "192.168.0.200", user: "pi", command: "whoami")
        let hostnameResult = mockSSHInfra.executeSSHCommand(host: "192.168.0.200", user: "pi", command: "hostname")
        let uptimeResult = mockSSHInfra.executeSSHCommand(host: "192.168.0.200", user: "pi", command: "uptime")
        let invalidResult = mockSSHInfra.executeSSHCommand(host: "192.168.0.200", user: "pi", command: "invalidcommand")
        
        // Then: Commands should execute with appropriate responses
        XCTAssertEqual(whoamiResult.exitCode, 0, "whoami should succeed")
        XCTAssertEqual(whoamiResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines), "pi", "whoami should return 'pi'")
        
        XCTAssertEqual(hostnameResult.exitCode, 0, "hostname should succeed")
        XCTAssertTrue(hostnameResult.stdout.contains("crookedservices"), "hostname should match mock host")
        
        XCTAssertEqual(uptimeResult.exitCode, 0, "uptime should succeed")
        XCTAssertTrue(uptimeResult.stdout.contains("days"), "uptime should show system uptime")
        
        XCTAssertEqual(invalidResult.exitCode, 127, "invalid command should return command not found")
        XCTAssertTrue(invalidResult.stderr.contains("command not found"), "stderr should indicate command not found")
    }
    
    func testMockSSHInfrastructure_ServiceStatusChecking() {
        // Given: SSH connection to Pi
        mockNetworkInfra.configureForNormalOperation()
        _ = mockSSHInfra.simulateSSHConnection(host: "192.168.0.200", user: "pi")
        
        // When: Checking service statuses
        let frigateStatus = mockSSHInfra.executeSSHCommand(
            host: "192.168.0.200", 
            user: "pi", 
            command: "systemctl status frigate.service"
        )
        let haStatus = mockSSHInfra.executeSSHCommand(
            host: "192.168.0.200", 
            user: "pi", 
            command: "systemctl status homeassistant.service"
        )
        let unknownStatus = mockSSHInfra.executeSSHCommand(
            host: "192.168.0.200", 
            user: "pi", 
            command: "systemctl status unknown.service"
        )
        
        // Then: Service status commands should work appropriately
        XCTAssertEqual(frigateStatus.exitCode, 0, "Frigate service status should succeed")
        XCTAssertTrue(frigateStatus.stdout.contains("active (running)"), "Frigate should be active")
        XCTAssertTrue(frigateStatus.stdout.contains("frigate.service"), "Output should contain service name")
        
        XCTAssertEqual(haStatus.exitCode, 0, "Home Assistant service status should succeed")
        XCTAssertTrue(haStatus.stdout.contains("active (running)"), "Home Assistant should be active")
        
        XCTAssertEqual(unknownStatus.exitCode, 4, "Unknown service should return not found error")
        XCTAssertTrue(unknownStatus.stderr.contains("could not be found"), "Should indicate service not found")
    }
    
    func testMockSSHInfrastructure_DockerCommands() {
        // Given: SSH connection to Pi
        mockNetworkInfra.configureForNormalOperation()
        _ = mockSSHInfra.simulateSSHConnection(host: "192.168.0.200", user: "pi")
        
        // When: Checking Docker containers
        let dockerResult = mockSSHInfra.executeSSHCommand(host: "192.168.0.200", user: "pi", command: "docker ps")
        
        // Then: Docker command should show running containers
        XCTAssertEqual(dockerResult.exitCode, 0, "Docker ps should succeed")
        XCTAssertTrue(dockerResult.stdout.contains("frigate:latest"), "Should show Frigate container")
        XCTAssertTrue(dockerResult.stdout.contains("homeassistant/home"), "Should show Home Assistant container")
        XCTAssertTrue(dockerResult.stdout.contains("Up"), "Containers should be running")
    }
    
    // MARK: - VPN Bypass Investigation Tests
    
    func testSSHVPNBypassInvestigation_NormalOperation() {
        // Given: Normal operation (VPN off)
        mockNetworkInfra.configureForNormalOperation()
        
        // When: Running SSH VPN bypass investigation
        let investigation = mockSSHInfra.investigateSSHVPNBypass()
        
        // Then: No bypass should be detected
        XCTAssertFalse(investigation.vpnReportedAsActive, "VPN should not be reported as active")
        XCTAssertFalse(investigation.bypassDetected, "No bypass should be detected")
        XCTAssertEqual(investigation.securityRisk, .low, "Security risk should be low")
        XCTAssertGreaterThan(investigation.localHostsAccessible, 0, "Local hosts should be accessible")
        XCTAssertTrue(investigation.recommendation.contains("no bypass detected"), "Recommendation should indicate normal state")
    }
    
    func testSSHVPNBypassInvestigation_VPNBypassDetected() {
        // Given: VPN is active but SSH still works (bypass scenario)
        mockNetworkInfra.simulateVPNState(.connected)
        
        // When: Running SSH VPN bypass investigation  
        let investigation = mockSSHInfra.investigateSSHVPNBypass()
        
        // Then: Bypass should be detected as security issue
        XCTAssertTrue(investigation.vpnReportedAsActive, "VPN should be reported as active")
        XCTAssertEqual(investigation.localHostsAccessible, 0, "Local hosts should NOT be accessible via SSH when VPN active")
        XCTAssertFalse(investigation.bypassDetected, "No bypass detected since SSH properly blocked")
        XCTAssertEqual(investigation.securityRisk, .low, "Security risk should be low when SSH properly blocked")
    }
    
    // MARK: - HTTP Mock Integration Tests
    
    func testMockURLProtocol_FrigateAPI() {
        // Given: Mock URL protocol registered
        mockNetworkInfra.configureForNormalOperation()
        
        // Create expectation for async URL request
        let expectation = XCTestExpectation(description: "HTTP request completes")
        
        // When: Making HTTP request to Frigate API
        let url = URL(string: "http://192.168.0.200:5000/api/version")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { expectation.fulfill() }
            
            // Then: Should receive mock response
            XCTAssertNil(error, "Should not have HTTP error")
            XCTAssertNotNil(data, "Should receive response data")
            XCTAssertNotNil(response, "Should receive HTTP response")
            
            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 200, "Should return HTTP 200")
            }
            
            if let data = data,
               let jsonString = String(data: data, encoding: .utf8) {
                XCTAssertTrue(jsonString.contains("version"), "Response should contain version info")
                XCTAssertTrue(jsonString.contains("0.13.2"), "Should match mock Frigate version")
            }
        }
        task.resume()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testMockURLProtocol_HomeAssistantAPI() {
        // Given: Mock URL protocol registered  
        mockNetworkInfra.configureForNormalOperation()
        
        let expectation = XCTestExpectation(description: "HA API request completes")
        
        // When: Making request to Home Assistant config API
        let url = URL(string: "http://192.168.0.200:8123/api/config")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { expectation.fulfill() }
            
            // Then: Should receive mock config response
            XCTAssertNil(error, "Should not have HTTP error")
            XCTAssertNotNil(data, "Should receive response data")
            
            if let data = data,
               let jsonString = String(data: data, encoding: .utf8) {
                XCTAssertTrue(jsonString.contains("cameras"), "Config should contain cameras")
                XCTAssertTrue(jsonString.contains("backyard"), "Should include backyard camera")
                XCTAssertTrue(jsonString.contains("cam1"), "Should include cam1 camera")
            }
        }
        task.resume()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testMockURLProtocol_UnknownEndpoint() {
        // Given: Mock URL protocol registered
        mockNetworkInfra.configureForNormalOperation()
        
        let expectation = XCTestExpectation(description: "Unknown endpoint request completes")
        
        // When: Making request to unknown endpoint
        let url = URL(string: "http://192.168.0.200:5000/api/unknown")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { expectation.fulfill() }
            
            // Then: Should receive appropriate error
            XCTAssertNotNil(error, "Should have error for unknown endpoint")
            if let urlError = error as? URLError {
                XCTAssertEqual(urlError.code, .resourceUnavailable, "Should return resource unavailable error")
            }
        }
        task.resume()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Integration Test Scenarios
    
    func testFullVPNBypassInvestigationScenario() {
        // Given: Complex VPN bypass scenario
        mockNetworkInfra.configureForVPNBypassTesting()
        
        // When: Running comprehensive investigation
        let networkBypassSim = mockNetworkInfra.simulateVPNBypassScenario()
        let sshInvestigation = mockSSHInfra.investigateSSHVPNBypass()
        
        // Network connectivity checks
        let frigateReach = mockNetworkInfra.simulateNetworkReachability(host: "192.168.0.200")
        let haReach = mockNetworkInfra.simulateNetworkReachability(host: "crookedservices.local")
        
        // Port connectivity checks  
        let frigatePort = mockNetworkInfra.simulatePortConnectivity(host: "192.168.0.200", port: 5000)
        let haPort = mockNetworkInfra.simulatePortConnectivity(host: "192.168.0.200", port: 8123)
        
        // Then: All checks should consistently detect VPN bypass vulnerability
        XCTAssertTrue(networkBypassSim.bypassDetected, "Network simulation should detect bypass")
        XCTAssertEqual(networkBypassSim.securityRisk, .high, "Should be high security risk")
        
        XCTAssertFalse(frigateReach.isReachable, "Frigate should not be reachable via VPN")
        XCTAssertFalse(haReach.isReachable, "Home Assistant should not be reachable via VPN")
        XCTAssertFalse(frigatePort.isOpen, "Frigate port should be blocked by VPN")
        XCTAssertFalse(haPort.isOpen, "Home Assistant port should be blocked by VPN")
        
        XCTAssertTrue(sshInvestigation.vpnReportedAsActive, "SSH investigation should see VPN as active")
        XCTAssertEqual(sshInvestigation.localHostsAccessible, 0, "SSH should properly block local access")
        XCTAssertFalse(sshInvestigation.bypassDetected, "SSH should be properly blocked (no bypass)")
        
        // Security recommendations should be consistent
        XCTAssertEqual(networkBypassSim.recommendedAction, .killSwitchActivation, "Should recommend kill switch")
        XCTAssertTrue(sshInvestigation.recommendation.contains("no bypass detected"), "SSH properly blocked")
    }
}