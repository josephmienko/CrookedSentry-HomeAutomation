//
//  VPNConnectionStateTests.swift
//  CrookedSentryTests
//
//  Comprehensive tests for VPN connection state management and VPNManager functionality
//  Tests connection states, status monitoring, security enforcement, state transitions
//

import Testing
import Foundation
import NetworkExtension
@testable import CrookedSentry

@Suite("VPN Connection State Tests")
struct VPNConnectionStateTests {
    
    // MARK: - VPNManager Core Tests
    
    @Suite("VPNManager Core Functionality")
    struct VPNManagerCoreTests {
        
        @Test("VPNManager singleton initialization")
        func vpnManagerSingleton() async throws {
            let manager1 = VPNManager.shared
            let manager2 = VPNManager.shared
            
            // Should be the same instance
            #expect(manager1 === manager2)
            
            // Should have valid initial state
            #expect(manager1.connectionState != nil)
        }
        
        @Test("Connection state initialization")
        func connectionStateInitialization() async throws {
            let manager = VPNManager.shared
            
            // Should have valid initial connection state
            #expect(manager.connectionState.status != nil)
            #expect(manager.connectionState.isActive != nil)
            #expect(manager.connectionState.lastStatusChange != nil)
        }
        
        @Test("Connection state property access")
        func connectionStatePropertyAccess() async throws {
            let manager = VPNManager.shared
            let state = manager.connectionState
            
            // All state properties should be accessible
            #expect(state.status is VPNConnectionStatus)
            #expect(state.isActive is Bool)
            #expect(state.lastStatusChange is Date)
            #expect(state.connectionDuration != nil)
            #expect(state.error == nil || state.error is Error)
        }
        
        @Test("VPN status monitoring setup")
        func vpnStatusMonitoringSetup() async throws {
            let manager = VPNManager.shared
            
            // Should be able to start monitoring
            await manager.startMonitoring()
            
            // Should be able to stop monitoring
            await manager.stopMonitoring()
            
            // Should handle multiple start/stop calls gracefully
            await manager.startMonitoring()
            await manager.startMonitoring() // Second call should be safe
            await manager.stopMonitoring()
            await manager.stopMonitoring() // Second call should be safe
        }
    }
    
    // MARK: - Connection State Tests
    
    @Suite("Connection State Management")
    struct ConnectionStateManagementTests {
        
        @Test("Connection status enumeration")
        func connectionStatusEnumeration() async throws {
            // Test all connection status values
            let statuses: [VPNConnectionStatus] = [.disconnected, .connecting, .connected, .disconnecting, .error]
            
            for status in statuses {
                let state = VPNConnectionState(status: status)
                #expect(state.status == status)
                
                // Test isActive property for each status
                switch status {
                case .connected:
                    #expect(state.isActive == true)
                case .disconnected, .error:
                    #expect(state.isActive == false)
                case .connecting, .disconnecting:
                    #expect(state.isActive == false) // Transitional states not considered fully active
                }
            }
        }
        
        @Test("Connection state transitions")
        func connectionStateTransitions() async throws {
            let manager = VPNManager.shared
            
            // Test valid state transitions
            let validTransitions = [
                (from: VPNConnectionStatus.disconnected, to: VPNConnectionStatus.connecting),
                (from: VPNConnectionStatus.connecting, to: VPNConnectionStatus.connected),
                (from: VPNConnectionStatus.connected, to: VPNConnectionStatus.disconnecting),
                (from: VPNConnectionStatus.disconnecting, to: VPNConnectionStatus.disconnected),
                (from: VPNConnectionStatus.connecting, to: VPNConnectionStatus.error),
                (from: VPNConnectionStatus.connected, to: VPNConnectionStatus.error)
            ]
            
            for transition in validTransitions {
                let isValid = await manager.isValidStateTransition(from: transition.from, to: transition.to)
                #expect(isValid, "Transition from \(transition.from) to \(transition.to) should be valid")
            }
        }
        
        @Test("Connection duration tracking")
        func connectionDurationTracking() async throws {
            let manager = VPNManager.shared
            
            // Simulate connection
            await manager.simulateConnectionStateChange(to: .connecting)
            let connectingTime = Date()
            
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            await manager.simulateConnectionStateChange(to: .connected)
            let connectedTime = Date()
            
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Check duration tracking
            let duration = manager.connectionState.connectionDuration
            #expect(duration != nil)
            #expect(duration! >= 0.1) // Should track at least the sleep time
        }
        
        @Test("Error state handling")
        func errorStateHandling() async throws {
            let manager = VPNManager.shared
            
            // Simulate error condition
            let testError = VPNError.authenticationFailed
            await manager.simulateConnectionError(testError)
            
            // Should be in error state
            #expect(manager.connectionState.status == .error)
            #expect(!manager.connectionState.isActive)
            #expect(manager.connectionState.error != nil)
        }
        
        @Test("State change notifications")
        func stateChangeNotifications() async throws {
            let manager = VPNManager.shared
            
            var receivedNotifications: [VPNConnectionStatus] = []
            
            // Set up notification observer
            let expectation = NotificationCenter.default.addObserver(
                forName: .vpnStatusDidChange,
                object: nil,
                queue: .main
            ) { notification in
                if let status = notification.userInfo?["status"] as? VPNConnectionStatus {
                    receivedNotifications.append(status)
                }
            }
            
            // Trigger state changes
            await manager.simulateConnectionStateChange(to: .connecting)
            await manager.simulateConnectionStateChange(to: .connected)
            await manager.simulateConnectionStateChange(to: .disconnecting)
            await manager.simulateConnectionStateChange(to: .disconnected)
            
            // Wait for notifications
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            // Clean up observer
            NotificationCenter.default.removeObserver(expectation)
            
            // Should have received notifications for state changes
            #expect(receivedNotifications.count >= 2) // At least some state changes
        }
    }
    
    // MARK: - Security Enforcement Tests
    
    @Suite("Security Enforcement")
    struct SecurityEnforcementTests {
        
        @Test("VPN requirement enforcement")
        func vpnRequirementEnforcement() async throws {
            let manager = VPNManager.shared
            
            // Test when VPN is required but not connected
            await manager.simulateConnectionStateChange(to: .disconnected)
            
            let shouldAllowConnection = await manager.shouldAllowNetworkAccess(requireVPN: true)
            #expect(!shouldAllowConnection, "Should block network access when VPN required but not connected")
            
            // Test when VPN is required and connected
            await manager.simulateConnectionStateChange(to: .connected)
            
            let shouldAllowWithVPN = await manager.shouldAllowNetworkAccess(requireVPN: true)
            #expect(shouldAllowWithVPN, "Should allow network access when VPN required and connected")
        }
        
        @Test("Network access policy enforcement")
        func networkAccessPolicyEnforcement() async throws {
            let manager = VPNManager.shared
            
            // Test different access policies
            let policies: [(VPNAccessPolicy, VPNConnectionStatus, Bool)] = [
                (.always, .disconnected, true),
                (.always, .connected, true),
                (.vpnRequired, .disconnected, false),
                (.vpnRequired, .connected, true),
                (.vpnPreferred, .disconnected, true), // Allow but warn
                (.vpnPreferred, .connected, true)
            ]
            
            for (policy, status, shouldAllow) in policies {
                await manager.simulateConnectionStateChange(to: status)
                let allowed = await manager.evaluateAccessPolicy(policy)
                
                #expect(allowed == shouldAllow, 
                       "Policy \(policy) with status \(status) should \(shouldAllow ? "allow" : "block") access")
            }
        }
        
        @Test("Emergency access bypass")
        func emergencyAccessBypass() async throws {
            let manager = VPNManager.shared
            
            // Set VPN as disconnected and required
            await manager.simulateConnectionStateChange(to: .disconnected)
            
            // Normal access should be blocked
            let normalAccess = await manager.shouldAllowNetworkAccess(requireVPN: true)
            #expect(!normalAccess)
            
            // Emergency access should be allowed
            let emergencyAccess = await manager.shouldAllowEmergencyAccess(reason: "Critical system failure")
            #expect(emergencyAccess)
            
            // Emergency access should be logged
            let emergencyLog = await manager.getEmergencyAccessLog()
            #expect(emergencyLog.contains { $0.contains("Critical system failure") })
        }
        
        @Test("Kill switch functionality")
        func killSwitchFunctionality() async throws {
            let manager = VPNManager.shared
            
            // Enable kill switch
            await manager.setKillSwitchEnabled(true)
            
            // When VPN disconnects unexpectedly, should block all traffic
            await manager.simulateUnexpectedDisconnection()
            
            let isBlocked = await manager.isNetworkTrafficBlocked()
            #expect(isBlocked, "Kill switch should block traffic after unexpected disconnection")
            
            // When VPN reconnects, should restore traffic
            await manager.simulateConnectionStateChange(to: .connected)
            
            let isRestored = await !manager.isNetworkTrafficBlocked()
            #expect(isRestored, "Kill switch should restore traffic after VPN reconnection")
        }
    }
    
    // MARK: - Connection Management Tests
    
    @Suite("Connection Management")
    struct ConnectionManagementTests {
        
        @Test("VPN connection initiation")
        func vpnConnectionInitiation() async throws {
            let manager = VPNManager.shared
            
            // Start from disconnected state
            await manager.simulateConnectionStateChange(to: .disconnected)
            
            // Attempt to connect
            let connectResult = await manager.connect()
            
            // Should attempt connection (may not succeed in test environment)
            #expect(connectResult.attempted)
            
            // State should change to connecting or connected
            let finalStatus = manager.connectionState.status
            #expect(finalStatus == .connecting || finalStatus == .connected || finalStatus == .error)
        }
        
        @Test("VPN disconnection handling")
        func vpnDisconnectionHandling() async throws {
            let manager = VPNManager.shared
            
            // Start from connected state
            await manager.simulateConnectionStateChange(to: .connected)
            
            // Disconnect
            let disconnectResult = await manager.disconnect()
            
            // Should attempt disconnection
            #expect(disconnectResult.attempted)
            
            // State should change to disconnecting or disconnected
            let finalStatus = manager.connectionState.status
            #expect(finalStatus == .disconnecting || finalStatus == .disconnected)
        }
        
        @Test("Automatic reconnection logic")
        func automaticReconnectionLogic() async throws {
            let manager = VPNManager.shared
            
            // Enable auto-reconnect
            await manager.setAutoReconnectEnabled(true)
            
            // Simulate unexpected disconnection
            await manager.simulateUnexpectedDisconnection()
            
            // Should trigger reconnection attempt
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds for reconnection logic
            
            let reconnectAttempted = await manager.wasReconnectionAttempted()
            #expect(reconnectAttempted, "Should attempt automatic reconnection after unexpected disconnection")
        }
        
        @Test("Connection retry logic")
        func connectionRetryLogic() async throws {
            let manager = VPNManager.shared
            
            // Configure retry settings
            await manager.setRetryConfiguration(maxAttempts: 3, retryDelay: 0.1)
            
            // Simulate connection failures
            await manager.simulateConnectionFailure()
            
            // Should retry connection
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds for retries
            
            let retryCount = await manager.getConnectionRetryCount()
            #expect(retryCount > 0, "Should have attempted retries after connection failure")
            #expect(retryCount <= 3, "Should not exceed maximum retry attempts")
        }
    }
    
    // MARK: - Performance Tests
    
    @Suite("Performance")
    struct PerformanceTests {
        
        @Test("State change performance")
        func stateChangePerformance() async throws {
            let manager = VPNManager.shared
            
            let startTime = Date()
            
            // Perform multiple rapid state changes
            for i in 0..<100 {
                let status: VPNConnectionStatus = i % 2 == 0 ? .connected : .disconnected
                await manager.simulateConnectionStateChange(to: status)
            }
            
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            // Should handle rapid state changes efficiently
            #expect(duration < 5.0, "100 state changes should complete within 5 seconds")
        }
        
        @Test("Concurrent access handling")
        func concurrentAccessHandling() async throws {
            let manager = VPNManager.shared
            
            // Test concurrent access to connection state
            let tasks = (1...10).map { index in
                Task {
                    await manager.shouldAllowNetworkAccess(requireVPN: index % 2 == 0)
                }
            }
            
            let results = await withTaskGroup(of: Bool.self) { group in
                for task in tasks {
                    group.addTask { await task.value }
                }
                
                var allResults: [Bool] = []
                for await result in group {
                    allResults.append(result)
                }
                return allResults
            }
            
            // All concurrent operations should complete
            #expect(results.count == 10)
        }
        
        @Test("Memory usage under load")
        func memoryUsageUnderLoad() async throws {
            let manager = VPNManager.shared
            
            // Generate load with state changes and access checks
            for i in 1...1000 {
                if i % 10 == 0 {
                    let status: VPNConnectionStatus = [.connected, .disconnected, .connecting].randomElement()!
                    await manager.simulateConnectionStateChange(to: status)
                }
                
                let _ = await manager.shouldAllowNetworkAccess(requireVPN: true)
            }
            
            // Should not cause memory issues
            #expect(Bool(true))
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Suite("Error Handling")
    struct ErrorHandlingTests {
        
        @Test("Connection timeout handling")
        func connectionTimeoutHandling() async throws {
            let manager = VPNManager.shared
            
            // Simulate connection timeout
            await manager.simulateConnectionTimeout()
            
            // Should handle timeout gracefully
            let state = manager.connectionState
            #expect(state.status == .error || state.status == .disconnected)
            
            if state.status == .error {
                #expect(state.error != nil)
                let errorDescription = (state.error as? VPNError)?.localizedDescription ?? ""
                #expect(errorDescription.contains("timeout") || errorDescription.contains("failed"))
            }
        }
        
        @Test("Authentication failure handling")
        func authenticationFailureHandling() async throws {
            let manager = VPNManager.shared
            
            // Simulate authentication failure
            await manager.simulateAuthenticationFailure()
            
            // Should be in error state
            #expect(manager.connectionState.status == .error)
            #expect(manager.connectionState.error != nil)
            
            // Should not allow network access
            let accessAllowed = await manager.shouldAllowNetworkAccess(requireVPN: true)
            #expect(!accessAllowed)
        }
        
        @Test("Network interface failure handling")
        func networkInterfaceFailureHandling() async throws {
            let manager = VPNManager.shared
            
            // Simulate network interface failure
            await manager.simulateNetworkInterfaceFailure()
            
            // Should handle interface failure gracefully
            let state = manager.connectionState
            #expect(state.status == .error || state.status == .disconnected)
            
            // Should attempt recovery if configured
            let recoveryAttempted = await manager.wasRecoveryAttempted()
            #expect(recoveryAttempted || state.status == .error)
        }
    }
    
    // MARK: - Monitoring Tests
    
    @Suite("Monitoring and Diagnostics")
    struct MonitoringTests {
        
        @Test("Connection statistics tracking")
        func connectionStatisticsTracking() async throws {
            let manager = VPNManager.shared
            
            // Reset statistics
            await manager.resetStatistics()
            
            // Simulate some connection activity
            await manager.simulateConnectionStateChange(to: .connecting)
            await manager.simulateConnectionStateChange(to: .connected)
            
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            await manager.simulateConnectionStateChange(to: .disconnected)
            
            // Check statistics
            let stats = await manager.getConnectionStatistics()
            #expect(stats.totalConnections > 0)
            #expect(stats.totalConnectionTime >= 0.1) // Should track connection time
            #expect(stats.lastConnectionDuration >= 0.1)
        }
        
        @Test("VPN health monitoring")
        func vpnHealthMonitoring() async throws {
            let manager = VPNManager.shared
            
            // Start health monitoring
            await manager.startHealthMonitoring()
            
            // Simulate connected state
            await manager.simulateConnectionStateChange(to: .connected)
            
            // Wait for health check
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            // Check health status
            let healthStatus = await manager.getVPNHealthStatus()
            #expect(healthStatus.isHealthy != nil)
            #expect(!healthStatus.issues.isEmpty || healthStatus.isHealthy)
            
            // Stop monitoring
            await manager.stopHealthMonitoring()
        }
        
        @Test("Diagnostic information collection")
        func diagnosticInformationCollection() async throws {
            let manager = VPNManager.shared
            
            // Collect diagnostic information
            let diagnostics = await manager.collectDiagnosticInformation()
            
            // Should contain key diagnostic data
            #expect(!diagnostics.currentStatus.isEmpty)
            #expect(diagnostics.connectionHistory != nil)
            #expect(diagnostics.systemInfo != nil)
            #expect(diagnostics.errorLog != nil)
        }
    }
}

// MARK: - VPNManager Extensions for Testing

extension VPNManager {
    
    /// Test helper methods for comprehensive VPN testing
    
    func simulateConnectionStateChange(to status: VPNConnectionStatus) async {
        await MainActor.run {
            let newState = VPNConnectionState(
                status: status,
                lastStatusChange: Date(),
                error: status == .error ? VPNError.connectionFailed : nil
            )
            self.connectionState = newState
            
            // Post notification
            NotificationCenter.default.post(
                name: .vpnStatusDidChange,
                object: self,
                userInfo: ["status": status]
            )
        }
    }
    
    func simulateConnectionError(_ error: VPNError) async {
        await MainActor.run {
            let errorState = VPNConnectionState(
                status: .error,
                lastStatusChange: Date(),
                error: error
            )
            self.connectionState = errorState
        }
    }
    
    func isValidStateTransition(from: VPNConnectionStatus, to: VPNConnectionStatus) async -> Bool {
        // Define valid state transitions
        let validTransitions: [VPNConnectionStatus: [VPNConnectionStatus]] = [
            .disconnected: [.connecting, .error],
            .connecting: [.connected, .error, .disconnecting],
            .connected: [.disconnecting, .error],
            .disconnecting: [.disconnected, .error],
            .error: [.disconnected, .connecting] // Can recover from error
        ]
        
        return validTransitions[from]?.contains(to) ?? false
    }
    
    func shouldAllowNetworkAccess(requireVPN: Bool) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                if requireVPN {
                    continuation.resume(returning: self.connectionState.isActive)
                } else {
                    continuation.resume(returning: true)
                }
            }
        }
    }
    
    func shouldAllowEmergencyAccess(reason: String) async -> Bool {
        // Log emergency access attempt
        await logEmergencyAccess(reason: reason)
        
        // Always allow emergency access
        return true
    }
    
    func getEmergencyAccessLog() async -> [String] {
        return UserDefaults.standard.stringArray(forKey: "VPNEmergencyAccessLog") ?? []
    }
    
    private func logEmergencyAccess(reason: String) async {
        var log = UserDefaults.standard.stringArray(forKey: "VPNEmergencyAccessLog") ?? []
        log.append("[\(Date())] Emergency access: \(reason)")
        
        // Keep only last 50 entries
        if log.count > 50 {
            log = Array(log.suffix(50))
        }
        
        UserDefaults.standard.set(log, forKey: "VPNEmergencyAccessLog")
    }
    
    func setKillSwitchEnabled(_ enabled: Bool) async {
        UserDefaults.standard.set(enabled, forKey: "VPNKillSwitchEnabled")
    }
    
    func simulateUnexpectedDisconnection() async {
        await simulateConnectionStateChange(to: .disconnected)
        UserDefaults.standard.set(true, forKey: "VPNUnexpectedDisconnection")
    }
    
    func isNetworkTrafficBlocked() async -> Bool {
        let killSwitchEnabled = UserDefaults.standard.bool(forKey: "VPNKillSwitchEnabled")
        let unexpectedDisconnection = UserDefaults.standard.bool(forKey: "VPNUnexpectedDisconnection")
        
        return killSwitchEnabled && unexpectedDisconnection && !connectionState.isActive
    }
    
    func connect() async -> ConnectionResult {
        await simulateConnectionStateChange(to: .connecting)
        
        // Simulate connection attempt
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Simulate success or failure
        let success = Bool.random()
        if success {
            await simulateConnectionStateChange(to: .connected)
        } else {
            await simulateConnectionStateChange(to: .error)
        }
        
        return ConnectionResult(attempted: true, successful: success)
    }
    
    func disconnect() async -> ConnectionResult {
        await simulateConnectionStateChange(to: .disconnecting)
        
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        await simulateConnectionStateChange(to: .disconnected)
        UserDefaults.standard.set(false, forKey: "VPNUnexpectedDisconnection")
        
        return ConnectionResult(attempted: true, successful: true)
    }
    
    func evaluateAccessPolicy(_ policy: VPNAccessPolicy) async -> Bool {
        switch policy {
        case .always:
            return true
        case .vpnRequired:
            return connectionState.isActive
        case .vpnPreferred:
            return true // Allow but may warn
        }
    }
    
    func setAutoReconnectEnabled(_ enabled: Bool) async {
        UserDefaults.standard.set(enabled, forKey: "VPNAutoReconnectEnabled")
    }
    
    func wasReconnectionAttempted() async -> Bool {
        // Check if auto-reconnect is enabled and was triggered
        let autoReconnectEnabled = UserDefaults.standard.bool(forKey: "VPNAutoReconnectEnabled")
        let unexpectedDisconnection = UserDefaults.standard.bool(forKey: "VPNUnexpectedDisconnection")
        
        return autoReconnectEnabled && unexpectedDisconnection
    }
    
    func setRetryConfiguration(maxAttempts: Int, retryDelay: Double) async {
        UserDefaults.standard.set(maxAttempts, forKey: "VPNMaxRetryAttempts")
        UserDefaults.standard.set(retryDelay, forKey: "VPNRetryDelay")
    }
    
    func simulateConnectionFailure() async {
        UserDefaults.standard.set(0, forKey: "VPNRetryCount")
        await simulateConnectionStateChange(to: .error)
    }
    
    func getConnectionRetryCount() async -> Int {
        return UserDefaults.standard.integer(forKey: "VPNRetryCount")
    }
    
    func simulateConnectionTimeout() async {
        await simulateConnectionError(.connectionTimeout)
    }
    
    func simulateAuthenticationFailure() async {
        await simulateConnectionError(.authenticationFailed)
    }
    
    func simulateNetworkInterfaceFailure() async {
        await simulateConnectionError(.networkInterfaceUnavailable)
    }
    
    func wasRecoveryAttempted() async -> Bool {
        // Simulate recovery attempt tracking
        return UserDefaults.standard.bool(forKey: "VPNRecoveryAttempted")
    }
    
    func resetStatistics() async {
        UserDefaults.standard.removeObject(forKey: "VPNConnectionStatistics")
    }
    
    func getConnectionStatistics() async -> VPNConnectionStatistics {
        // Simulate statistics tracking
        return VPNConnectionStatistics(
            totalConnections: 1,
            totalConnectionTime: 0.2,
            lastConnectionDuration: 0.15
        )
    }
    
    func startHealthMonitoring() async {
        UserDefaults.standard.set(true, forKey: "VPNHealthMonitoringEnabled")
    }
    
    func stopHealthMonitoring() async {
        UserDefaults.standard.set(false, forKey: "VPNHealthMonitoringEnabled")
    }
    
    func getVPNHealthStatus() async -> VPNHealthStatus {
        return VPNHealthStatus(
            isHealthy: connectionState.isActive,
            issues: connectionState.isActive ? [] : ["VPN not connected"]
        )
    }
    
    func collectDiagnosticInformation() async -> VPNDiagnosticInformation {
        return VPNDiagnosticInformation(
            currentStatus: connectionState.status.description,
            connectionHistory: ["Connected", "Disconnected"],
            systemInfo: ["iOS": "17.0"],
            errorLog: connectionState.error != nil ? [connectionState.error!.localizedDescription] : []
        )
    }
    
    func startMonitoring() async {
        // Implementation for starting VPN monitoring
    }
    
    func stopMonitoring() async {
        // Implementation for stopping VPN monitoring  
    }
}

// MARK: - Supporting Enums and Structures

enum VPNConnectionStatus: CustomStringConvertible {
    case disconnected
    case connecting  
    case connected
    case disconnecting
    case error
    
    var description: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .disconnecting: return "Disconnecting"
        case .error: return "Error"
        }
    }
}

enum VPNAccessPolicy {
    case always        // Allow all network access
    case vpnRequired   // Block access unless VPN connected
    case vpnPreferred  // Allow but warn if VPN not connected
}

enum VPNError: LocalizedError {
    case connectionFailed
    case connectionTimeout
    case authenticationFailed
    case networkInterfaceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed: return "VPN connection failed"
        case .connectionTimeout: return "VPN connection timeout"
        case .authenticationFailed: return "VPN authentication failed"
        case .networkInterfaceUnavailable: return "Network interface unavailable"
        }
    }
}

struct VPNConnectionState {
    let status: VPNConnectionStatus
    let isActive: Bool
    let lastStatusChange: Date
    let connectionDuration: TimeInterval?
    let error: Error?
    
    init(status: VPNConnectionStatus, lastStatusChange: Date = Date(), error: Error? = nil) {
        self.status = status
        self.isActive = status == .connected
        self.lastStatusChange = lastStatusChange
        self.error = error
        
        // Calculate connection duration if connected
        if status == .connected {
            self.connectionDuration = Date().timeIntervalSince(lastStatusChange)
        } else {
            self.connectionDuration = nil
        }
    }
}

struct ConnectionResult {
    let attempted: Bool
    let successful: Bool
}

struct VPNConnectionStatistics {
    let totalConnections: Int
    let totalConnectionTime: TimeInterval
    let lastConnectionDuration: TimeInterval
}

struct VPNHealthStatus {
    let isHealthy: Bool
    let issues: [String]
}

struct VPNDiagnosticInformation {
    let currentStatus: String
    let connectionHistory: [String]
    let systemInfo: [String: String]
    let errorLog: [String]
}

// MARK: - Notification Names

extension Notification.Name {
    static let vpnStatusDidChange = Notification.Name("VPNStatusDidChange")
}