//
//  MockSSHInfrastructure.swift
//  CrookedSentryTests
//
//  Created by Assistant on 2025
//

import Foundation
import Network
@testable import CrookedSentry

/// Mock SSH infrastructure matching the operational mock-ssh.py for Pi connections
/// Simulates SSH connectivity to home automation services for VPN bypass testing
class MockSSHInfrastructure {
    
    static let shared = MockSSHInfrastructure()
    
    // MARK: - Mock SSH Hosts Configuration
    
    /// SSH hosts matching operational infrastructure
    let mockSSHHosts: [String: MockSSHHost] = [
        "192.168.0.200": MockSSHHost(
            hostname: "crookedservices.local",
            ip: "192.168.0.200",
            port: 22,
            users: ["pi", "homeassistant", "root"],
            services: [
                "frigate.service": .active,
                "homeassistant.service": .active,
                "nginx.service": .active,
                "wireguard.service": .active
            ],
            systemInfo: MockSystemInfo(
                os: "Raspberry Pi OS",
                kernel: "6.1.21-v8+",
                arch: "aarch64",
                uptime: "7 days, 14:32:15",
                load: "0.45, 0.52, 0.48"
            )
        ),
        "pi-backup": MockSSHHost(
            hostname: "pi-backup.local",
            ip: "192.168.0.201", 
            port: 22,
            users: ["pi"],
            services: [
                "backup.service": .active,
                "rsync.service": .active
            ],
            systemInfo: MockSystemInfo(
                os: "Raspberry Pi OS Lite",
                kernel: "6.1.21-v7l+",
                arch: "armv7l",
                uptime: "12 days, 8:15:42",
                load: "0.12, 0.08, 0.05"
            )
        )
    ]
    
    // MARK: - SSH Connection Simulation
    
    var simulatedConnectionState: SSHConnectionState = .disconnected
    
    /// Simulate SSH connection attempt matching mock-ssh.py behavior
    func simulateSSHConnection(host: String, port: Int = 22, user: String = "pi") -> SSHConnectionResult {
        guard let mockHost = mockSSHHosts[host] else {
            return SSHConnectionResult(
                success: false,
                error: "ssh: Could not resolve hostname \(host): nodename nor servname provided, or not known",
                connectionTime: nil,
                hostKey: nil
            )
        }
        
        // Apply VPN state logic - SSH should fail when VPN is active
        let mockInfra = MockNetworkInfrastructure.shared
        if mockInfra.simulatedVPNState == .connected && (host.contains("192.168.0") || host.contains(".local")) {
            return SSHConnectionResult(
                success: false,
                error: "ssh: connect to host \(host) port \(port): Operation timed out",
                connectionTime: nil,
                hostKey: nil
            )
        }
        
        // Validate user exists on mock host
        guard mockHost.users.contains(user) else {
            return SSHConnectionResult(
                success: false,
                error: "Permission denied (publickey,password).",
                connectionTime: nil,
                hostKey: nil
            )
        }
        
        // Successful connection
        simulatedConnectionState = .connected(host: host, user: user)
        return SSHConnectionResult(
            success: true,
            error: nil,
            connectionTime: Double.random(in: 0.1...0.5),
            hostKey: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI\(String.randomString(length: 40))"
        )
    }
    
    /// Execute SSH command on mock host
    func executeSSHCommand(host: String, user: String, command: String) -> SSHCommandResult {
        guard let mockHost = mockSSHHosts[host] else {
            return SSHCommandResult(
                exitCode: 255,
                stdout: "",
                stderr: "ssh: Could not resolve hostname \(host)",
                executionTime: 0.0
            )
        }
        
        // VPN bypass vulnerability test - commands should fail when VPN is active
        let mockInfra = MockNetworkInfrastructure.shared
        if mockInfra.simulatedVPNState == .connected && (host.contains("192.168.0") || host.contains(".local")) {
            return SSHCommandResult(
                exitCode: 255,
                stdout: "",
                stderr: "ssh: connect to host \(host) port 22: Operation timed out",
                executionTime: 30.0 // Timeout after 30 seconds
            )
        }
        
        // Mock command execution based on operational mock-ssh.py patterns
        return executeMockSSHCommand(command: command, on: mockHost)
    }
    
    // MARK: - Mock Command Execution
    
    private func executeMockSSHCommand(command: String, on host: MockSSHHost) -> SSHCommandResult {
        let cmd = command.trimmingCharacters(in: .whitespaces)
        
        switch cmd {
        case "whoami":
            return SSHCommandResult(exitCode: 0, stdout: "pi\n", stderr: "", executionTime: 0.1)
            
        case "hostname":
            return SSHCommandResult(exitCode: 0, stdout: "\(host.hostname)\n", stderr: "", executionTime: 0.1)
            
        case "uptime":
            return SSHCommandResult(
                exitCode: 0,
                stdout: " \(host.systemInfo.uptime)  up  1 user,  load average: \(host.systemInfo.load)\n",
                stderr: "",
                executionTime: 0.1
            )
            
        case "uname -a":
            return SSHCommandResult(
                exitCode: 0,
                stdout: "Linux \(host.hostname.replacingOccurrences(of: ".local", with: "")) \(host.systemInfo.kernel) #1 SMP \(host.systemInfo.arch) GNU/Linux\n",
                stderr: "",
                executionTime: 0.2
            )
            
        case let cmd where cmd.starts(with: "systemctl status"):
            let serviceName = String(cmd.dropFirst("systemctl status ".count))
            if let status = host.services[serviceName] {
                let statusOutput = generateSystemctlOutput(service: serviceName, status: status)
                return SSHCommandResult(exitCode: 0, stdout: statusOutput, stderr: "", executionTime: 0.3)
            } else {
                return SSHCommandResult(
                    exitCode: 4,
                    stdout: "",
                    stderr: "Unit \(serviceName) could not be found.\n",
                    executionTime: 0.2
                )
            }
            
        case "docker ps":
            return SSHCommandResult(
                exitCode: 0,
                stdout: """
                CONTAINER ID   IMAGE              COMMAND                  CREATED       STATUS       PORTS                    NAMES
                abc123def456   frigate:latest     "/init"                  2 weeks ago   Up 7 days    0.0.0.0:5000->5000/tcp   frigate
                def456ghi789   homeassistant/home "/init"                  2 weeks ago   Up 7 days    0.0.0.0:8123->8123/tcp   homeassistant
                
                """,
                stderr: "",
                executionTime: 0.5
            )
            
        case let cmd where cmd.starts(with: "curl"):
            return handleMockCurlCommand(cmd)
            
        case "ps aux | grep -E '(frigate|homeassistant|nginx)'":
            return SSHCommandResult(
                exitCode: 0,
                stdout: """
                root      1234  0.1  2.3  123456  45678 ?        Ssl  Jan01   1:23 /usr/bin/python3 -m frigate
                haass     5678  0.2  1.8  987654  32109 ?        Ssl  Jan01   2:45 /usr/bin/python3 /usr/src/homeassistant/homeassistant
                nginx     9012  0.0  0.5  654321  12345 ?        S    Jan01   0:12 nginx: worker process
                
                """,
                stderr: "",
                executionTime: 0.4
            )
            
        default:
            // Unknown command
            return SSHCommandResult(
                exitCode: 127,
                stdout: "",
                stderr: "bash: \(cmd): command not found\n",
                executionTime: 0.1
            )
        }
    }
    
    private func handleMockCurlCommand(_ command: String) -> SSHCommandResult {
        // Extract URL from curl command
        let components = command.components(separatedBy: " ")
        guard let urlIndex = components.firstIndex(where: { $0.contains("http") }),
              let url = URL(string: components[urlIndex]) else {
            return SSHCommandResult(
                exitCode: 6,
                stdout: "",
                stderr: "curl: (6) Could not resolve host\n",
                executionTime: 0.3
            )
        }
        
        let path = url.path.isEmpty ? "/" : url.path
        let mockInfra = MockNetworkInfrastructure.shared
        
        if let mockResponse = mockInfra.mockAPIResponses[path] {
            let responseBody = String(data: mockResponse.data, encoding: .utf8) ?? ""
            return SSHCommandResult(
                exitCode: 0,
                stdout: responseBody,
                stderr: "",
                executionTime: Double.random(in: 0.1...0.5)
            )
        } else {
            return SSHCommandResult(
                exitCode: 22,
                stdout: "",
                stderr: "curl: (22) The requested URL returned error: 404 Not Found\n",
                executionTime: 0.3
            )
        }
    }
    
    private func generateSystemctlOutput(service: String, status: ServiceStatus) -> String {
        let statusText = status == .active ? "active (running)" : "inactive (dead)"
        let color = status == .active ? "32m" : "31m" // Green for active, red for inactive
        
        return """
        ● \(service) - \(service.capitalized) Service
             Loaded: loaded (/etc/systemd/system/\(service); enabled; vendor preset: enabled)
             Active: \u{001B}[\(color)\(statusText)\u{001B}[0m since Mon 2024-01-01 10:00:00 UTC; 7 days ago
               Docs: https://docs.\(service.replacingOccurrences(of: ".service", with: "")).com/
           Main PID: \(Int.random(in: 1000...9999)) (\(service.replacingOccurrences(of: ".service", with: "")))
              Tasks: \(Int.random(in: 5...50))
             Memory: \(Int.random(in: 50...500))M
             CGroup: /system.slice/\(service)

        Jan 01 10:00:00 \(service.replacingOccurrences(of: ".service", with: "")) systemd[1]: Started \(service.capitalized) Service.
        
        """
    }
}

// MARK: - SSH Data Structures

enum SSHConnectionState {
    case disconnected
    case connecting
    case connected(host: String, user: String)
    case error(String)
}

enum ServiceStatus {
    case active
    case inactive
    case failed
}

struct MockSSHHost {
    let hostname: String
    let ip: String
    let port: Int
    let users: [String]
    let services: [String: ServiceStatus]
    let systemInfo: MockSystemInfo
}

struct MockSystemInfo {
    let os: String
    let kernel: String
    let arch: String
    let uptime: String
    let load: String
}

struct SSHConnectionResult {
    let success: Bool
    let error: String?
    let connectionTime: Double? // seconds
    let hostKey: String?
}

struct SSHCommandResult {
    let exitCode: Int
    let stdout: String
    let stderr: String
    let executionTime: Double // seconds
}

// MARK: - Utility Extensions

extension String {
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
}

// MARK: - VPN Bypass Investigation

extension MockSSHInfrastructure {
    
    /// Test SSH connectivity for VPN bypass vulnerability
    func investigateSSHVPNBypass() -> SSHVPNBypassInvestigation {
        var results: [String: SSHConnectionResult] = [:]
        
        // Test all known SSH hosts
        for (host, mockHost) in mockSSHHosts {
            results[host] = simulateSSHConnection(host: host, user: "pi")
        }
        
        let mockInfra = MockNetworkInfrastructure.shared
        let vpnActive = mockInfra.simulatedVPNState == .connected
        
        // Analyze results for bypass detection
        // Only count local hosts (192.168.x.x or .local names) as relevant for VPN-bypass assessment
        let localHostsAccessible = results
            .filter { (host, result) in
                result.success && (host.contains("192.168.") || host.contains(".local"))
            }
            .count
        let bypassDetected = vpnActive && localHostsAccessible > 0
        
        return SSHVPNBypassInvestigation(
            vpnReportedAsActive: vpnActive,
            sshConnectionResults: results,
            localHostsAccessible: localHostsAccessible,
            bypassDetected: bypassDetected,
            securityRisk: bypassDetected ? .high : .low,
            recommendation: bypassDetected ? 
                "SECURITY ALERT: SSH access to local network while VPN active - potential bypass vulnerability" :
                "SSH connectivity consistent with VPN state - no bypass detected"
        )
    }
}

struct SSHVPNBypassInvestigation {
    let vpnReportedAsActive: Bool
    let sshConnectionResults: [String: SSHConnectionResult]
    let localHostsAccessible: Int
    let bypassDetected: Bool
    let securityRisk: SecurityRiskLevel
    let recommendation: String
}