//
//  SecurityIntegrationTests.swift
//  CrookedSentryTests
//
//  Integration tests for security flow scenarios including VPN bypass detection,
//  emergency access, audit trail validation, and end-to-end security workflows
//

import Testing
import Foundation
import Network
@testable import CrookedSentry

@Suite("Security Integration Tests")
struct SecurityIntegrationTests {
    
    // MARK: - VPN Bypass Detection Integration Tests
    
    @Suite("VPN Bypass Detection")
    struct VPNBypassDetectionTests {
        
        @Test("End-to-end VPN bypass detection workflow")
        func endToEndVPNBypassDetection() async throws {
            let debugger = NetworkSecurityDebugger.shared
            let validator = NetworkSecurityValidator.shared
            let secureClient = SecureAPIClient.shared
            
            // Step 1: Clear all previous state
            await debugger.clearInvestigationResults()
            await debugger.clearAuditLog()
            secureClient.clearAuditLog()
            await validator.clearValidationCache()
            
            // Step 2: Enable security enforcement
            secureClient.enableSecurity()
            
            // Step 3: Simulate VPN disconnected state
            // (This would integrate with actual VPNManager when available)
            
            // Step 4: Attempt API request that should be blocked
            do {
                let _: MockResponse = try await secureClient.secureRequest(
                    url: "https://httpbin.org/get",
                    method: .GET,
                    bypassSecurity: false
                )
                #expect(Bool(false), "Request should have been blocked by security validation")
            } catch let error as SecureAPIError {
                // Expected - request should be blocked
                #expect(error.localizedDescription.contains("security") || 
                       error.localizedDescription.contains("validation"))
            }
            
            // Step 5: Trigger comprehensive security investigation
            await debugger.performSecurityInvestigation()
            
            // Step 6: Validate that bypass was detected and logged
            let auditLog = secureClient.getSecurityAuditLog()
            let investigationResults = await debugger.getInvestigationResults()
            
            // Should have security violation logged
            let hasSecurityViolation = auditLog.contains { log in
                log.contains("SECURITY VIOLATION") || log.contains("Blocked")
            }
            
            // Should have investigation results
            #expect(!investigationResults.isEmpty)
            #expect(hasSecurityViolation || auditLog.contains { $0.contains("security") })
            
            // Step 7: Validate security report contains bypass information
            let securityReport = secureClient.exportSecurityReport()
            #expect(securityReport.contains("SECURITY AUDIT REPORT"))
            #expect(securityReport.contains("Security Enabled"))
        }
        
        @Test("VPN bypass with multiple API clients")
        func vpnBypassWithMultipleAPIClients() async throws {
            let secureClient = SecureAPIClient.shared
            let debugger = NetworkSecurityDebugger.shared
            
            // Clear previous state
            secureClient.clearAuditLog()
            await debugger.clearAuditLog()
            
            // Enable security
            secureClient.enableSecurity()
            
            // Test multiple blocked requests
            let testURLs = [
                "https://httpbin.org/get",
                "https://httpbin.org/status/200",
                "https://httpbin.org/json"
            ]
            
            var blockedRequests = 0
            
            for url in testURLs {
                do {
                    let _: MockResponse = try await secureClient.secureRequest(url: url)
                } catch {
                    blockedRequests += 1
                }
            }
            
            // All requests should be blocked
            #expect(blockedRequests == testURLs.count)
            
            // Should have multiple security violations logged
            let auditLog = secureClient.getSecurityAuditLog()
            let violationCount = auditLog.filter { $0.contains("SECURITY VIOLATION") || $0.contains("Blocked") }.count
            #expect(violationCount >= testURLs.count || auditLog.filter { $0.contains("security") }.count >= testURLs.count)
        }
        
        @Test("VPN bypass detection with network path analysis")
        func vpnBypassWithNetworkPathAnalysis() async throws {
            let validator = NetworkSecurityValidator.shared
            let debugger = NetworkSecurityDebugger.shared
            
            // Clear previous state
            await validator.clearValidationCache()
            await debugger.clearInvestigationResults()
            
            // Perform comprehensive security validation
            let validationResult = await validator.validateSecureConnection()
            
            // Perform network path analysis
            let pathValidation = await validator.validateNetworkPath(to: "https://apple.com")
            
            // Perform security investigation
            await debugger.performSecurityInvestigation()
            
            // Results should be consistent across components
            #expect(validationResult.summary != nil)
            #expect(pathValidation.pathDetails != nil)
            
            let investigationResults = await debugger.getInvestigationResults()
            #expect(!investigationResults.isEmpty)
            
            // All components should provide coherent security assessment
            let securityAssessment = [
                validationResult.summary,
                pathValidation.pathDetails,
                investigationResults.joined(separator: " ")
            ].joined(separator: " ")
            
            #expect(securityAssessment.contains("security") || 
                   securityAssessment.contains("VPN") || 
                   securityAssessment.contains("network"))
        }
    }
    
    // MARK: - Emergency Access Integration Tests
    
    @Suite("Emergency Access")
    struct EmergencyAccessTests {
        
        @Test("Emergency access workflow with audit trail")
        func emergencyAccessWithAuditTrail() async throws {
            let secureClient = SecureAPIClient.shared
            let debugger = NetworkSecurityDebugger.shared
            
            // Clear previous state
            secureClient.clearAuditLog()
            await debugger.clearAuditLog()
            
            // Enable security (should block normal requests)
            secureClient.enableSecurity()
            
            // Emergency access should work even when security enabled
            do {
                let _: MockResponse = try await secureClient.emergencyRequest(
                    url: "https://httpbin.org/get",
                    reason: "Critical system failure - user safety at risk"
                )
            } catch {
                // Network errors acceptable, but security should not block emergency access
                #expect(!(error is SecureAPIError && (error as! SecureAPIError).localizedDescription.contains("security")))
            }
            
            // Should have emergency access logged
            let auditLog = secureClient.getSecurityAuditLog()
            let hasEmergencyLog = auditLog.contains { log in
                log.contains("EMERGENCY ACCESS") && log.contains("Critical system failure")
            }
            #expect(hasEmergencyLog)
            
            // Should have bypass counter incremented
            #expect(secureClient.securityBypassCount > 0)
            
            // Trigger security investigation after emergency access
            await debugger.performSecurityInvestigation()
            
            // Investigation should note the emergency access
            let investigationResults = await debugger.getInvestigationResults()
            let auditLogContent = await debugger.getAuditLog()
            
            // Should have comprehensive audit trail
            #expect(!investigationResults.isEmpty)
            #expect(!auditLogContent.isEmpty || !auditLog.isEmpty)
        }
        
        @Test("Multiple emergency access events tracking")
        func multipleEmergencyAccessTracking() async throws {
            let secureClient = SecureAPIClient.shared
            
            // Clear and reset counters
            secureClient.clearAuditLog()
            await secureClient.resetBypassCounter()
            
            let emergencyReasons = [
                "Medical emergency - patient monitoring system down",
                "Security breach - immediate investigation required",
                "Fire alarm system failure - safety critical"
            ]
            
            // Make multiple emergency requests
            for reason in emergencyReasons {
                do {
                    let _: MockResponse = try await secureClient.emergencyRequest(
                        url: "https://httpbin.org/get",
                        reason: reason
                    )
                } catch {
                    // Network errors acceptable
                }
            }
            
            // Should track all emergency access attempts
            #expect(secureClient.securityBypassCount == emergencyReasons.count)
            
            // Should have all reasons logged
            let auditLog = secureClient.getSecurityAuditLog()
            for reason in emergencyReasons {
                let hasReasonLogged = auditLog.contains { $0.contains(reason) }
                #expect(hasReasonLogged)
            }
            
            // Security report should include emergency access summary
            let securityReport = secureClient.exportSecurityReport()
            #expect(securityReport.contains("Total Bypass Attempts: \(emergencyReasons.count)"))
        }
    }
    
    // MARK: - Audit Trail Integration Tests
    
    @Suite("Audit Trail Validation")
    struct AuditTrailTests {
        
        @Test("Comprehensive audit trail across all components")
        func comprehensiveAuditTrail() async throws {
            let debugger = NetworkSecurityDebugger.shared
            let validator = NetworkSecurityValidator.shared
            let secureClient = SecureAPIClient.shared
            
            // Clear all audit logs
            await debugger.clearAuditLog()
            secureClient.clearAuditLog()
            
            // Generate activity across all components
            
            // 1. Security validation
            let _ = await validator.validateSecureConnection()
            
            // 2. API request attempt
            secureClient.enableSecurity()
            do {
                let _: MockResponse = try await secureClient.secureRequest(url: "https://httpbin.org/get")
            } catch {
                // Expected to fail
            }
            
            // 3. Emergency access
            do {
                let _: MockResponse = try await secureClient.emergencyRequest(
                    url: "https://httpbin.org/get",
                    reason: "Test emergency access"
                )
            } catch {
                // Network errors acceptable
            }
            
            // 4. Security investigation
            await debugger.performSecurityInvestigation()
            
            // 5. Log security event
            await debugger.logSecurityEvent("Manual security audit performed")
            
            // Collect all audit trails
            let secureClientLog = secureClient.getSecurityAuditLog()
            let debuggerLog = await debugger.getAuditLog()
            
            // Should have comprehensive audit trail
            #expect(!secureClientLog.isEmpty)
            #expect(!debuggerLog.isEmpty || !secureClientLog.isEmpty)
            
            // Should have different types of events logged
            let allLogs = secureClientLog + debuggerLog
            let hasConnectionAttempt = allLogs.contains { $0.contains("Connection attempt") }
            let hasSecurityEvent = allLogs.contains { $0.contains("security") || $0.contains("SECURITY") }
            let hasEmergencyAccess = allLogs.contains { $0.contains("EMERGENCY ACCESS") }
            
            #expect(hasConnectionAttempt || hasSecurityEvent || hasEmergencyAccess)
            
            // Generate comprehensive security report
            let securityReport = secureClient.exportSecurityReport()
            #expect(securityReport.contains("SECURITY AUDIT REPORT"))
            #expect(securityReport.contains("SECURITY LOG"))
        }
        
        @Test("Audit log size limiting and rotation")
        func auditLogSizeLimitingAndRotation() async throws {
            let debugger = NetworkSecurityDebugger.shared
            let secureClient = SecureAPIClient.shared
            
            // Clear logs
            await debugger.clearAuditLog()
            secureClient.clearAuditLog()
            
            // Generate many log entries
            for i in 1...150 {
                await debugger.logSecurityEvent("Test event \(i)")
                try await secureClient.testLogEntry("API event \(i)")
            }
            
            // Logs should be size-limited
            let debuggerLog = await debugger.getAuditLog()
            let secureClientLog = secureClient.getSecurityAuditLog()
            
            #expect(debuggerLog.count <= 100)
            #expect(secureClientLog.count <= 100)
            
            // Should retain most recent entries
            let hasRecentDebuggerEntry = debuggerLog.contains { $0.contains("Test event 150") }
            let hasRecentClientEntry = secureClientLog.contains { $0.contains("API event 150") }
            
            #expect(hasRecentDebuggerEntry)
            #expect(hasRecentClientEntry)
        }
        
        @Test("Cross-component event correlation")
        func crossComponentEventCorrelation() async throws {
            let debugger = NetworkSecurityDebugger.shared
            let secureClient = SecureAPIClient.shared
            
            // Clear logs
            await debugger.clearAuditLog()
            secureClient.clearAuditLog()
            
            let timestamp = Date()
            
            // Generate correlated events
            secureClient.enableSecurity()
            
            // This should trigger security validation and logging in multiple components
            do {
                let _: MockResponse = try await secureClient.secureRequest(url: "https://httpbin.org/get")
            } catch {
                // Expected to be blocked
            }
            
            // Trigger investigation (should log the security violation)
            await debugger.performSecurityInvestigation()
            
            // Check for correlated events
            let secureClientLog = secureClient.getSecurityAuditLog()
            let debuggerLog = await debugger.getAuditLog()
            
            // Events should be timestamped and correlatable
            let recentSecureClientEvents = secureClientLog.filter { log in
                // Simple time correlation - events should be recent
                log.contains("Connection attempt") || log.contains("SECURITY")
            }
            
            let recentDebuggerEvents = debuggerLog.filter { log in
                log.contains("security") || log.contains("investigation")
            }
            
            #expect(!recentSecureClientEvents.isEmpty || !recentDebuggerEvents.isEmpty)
        }
    }
    
    // MARK: - Security State Management Integration Tests
    
    @Suite("Security State Management")
    struct SecurityStateManagementTests {
        
        @Test("Security enable/disable state propagation")
        func securityStateEnableDisablePropagation() async throws {
            let secureClient = SecureAPIClient.shared
            let debugger = NetworkSecurityDebugger.shared
            
            // Clear state
            secureClient.clearAuditLog()
            await debugger.clearAuditLog()
            
            // Test security disable
            secureClient.disableSecurity(duration: 0.5) // 0.5 seconds
            #expect(!secureClient.isSecurityEnabled)
            
            // Request should succeed when security disabled
            do {
                let _: MockResponse = try await secureClient.secureRequest(url: "https://httpbin.org/get")
            } catch {
                // Network errors acceptable, but should not be security-related
                #expect(!(error is SecureAPIError && (error as! SecureAPIError).localizedDescription.contains("security")))
            }
            
            // Wait for auto re-enable
            try await Task.sleep(nanoseconds: 700_000_000) // 0.7 seconds
            
            // Should be re-enabled
            #expect(secureClient.isSecurityEnabled)
            
            // Request should now be blocked
            do {
                let _: MockResponse = try await secureClient.secureRequest(url: "https://httpbin.org/get")
            } catch let error as SecureAPIError {
                #expect(error.localizedDescription.contains("security") || 
                       error.localizedDescription.contains("validation"))
            } catch {
                // Other network errors acceptable
            }
            
            // State changes should be logged
            let auditLog = secureClient.getSecurityAuditLog()
            let hasStateChanges = auditLog.contains { log in
                log.contains("DISABLED") || log.contains("ENABLED")
            }
            #expect(hasStateChanges)
        }
        
        @Test("Cache invalidation across components")
        func cacheInvalidationAcrossComponents() async throws {
            let validator = NetworkSecurityValidator.shared
            let secureClient = SecureAPIClient.shared
            
            // Populate caches
            let _ = await validator.validateSecureConnection()
            
            secureClient.disableSecurity()
            do {
                let _: MockResponse = try await secureClient.secureRequest(url: "https://httpbin.org/get")
            } catch {
                // Errors acceptable
            }
            
            // Clear caches
            await validator.clearValidationCache()
            secureClient.clearValidationCache()
            
            // Re-enable security
            secureClient.enableSecurity()
            
            // Fresh validation should occur
            let newValidation = await validator.validateSecureConnection()
            #expect(newValidation.summary != nil)
            
            // New security enforcement should take effect
            do {
                let _: MockResponse = try await secureClient.secureRequest(url: "https://httpbin.org/get")
            } catch let error as SecureAPIError {
                #expect(error.localizedDescription.contains("security") || 
                       error.localizedDescription.contains("validation"))
            } catch {
                // Network errors acceptable
            }
        }
    }
    
    // MARK: - Performance Integration Tests
    
    @Suite("Performance Integration")
    struct PerformanceIntegrationTests {
        
        @Test("End-to-end security workflow performance")
        func endToEndSecurityWorkflowPerformance() async throws {
            let debugger = NetworkSecurityDebugger.shared
            let validator = NetworkSecurityValidator.shared
            let secureClient = SecureAPIClient.shared
            
            let startTime = Date()
            
            // Full security workflow
            await debugger.clearInvestigationResults()
            await validator.clearValidationCache()
            secureClient.clearValidationCache()
            
            // 1. Security validation
            let _ = await validator.validateSecureConnection()
            
            // 2. Multiple API requests
            for i in 1...5 {
                do {
                    let _: MockResponse = try await secureClient.secureRequest(
                        url: "https://httpbin.org/get?test=\(i)"
                    )
                } catch {
                    // Errors acceptable for performance test
                }
            }
            
            // 3. Security investigation
            await debugger.performSecurityInvestigation()
            
            // 4. Generate security report
            let _ = secureClient.exportSecurityReport()
            
            let endTime = Date()
            let totalDuration = endTime.timeIntervalSince(startTime)
            
            // Entire workflow should complete within reasonable time
            #expect(totalDuration < 30.0) // 30 seconds max for comprehensive workflow
        }
        
        @Test("Concurrent security operations")
        func concurrentSecurityOperations() async throws {
            let debugger = NetworkSecurityDebugger.shared
            let validator = NetworkSecurityValidator.shared
            let secureClient = SecureAPIClient.shared
            
            secureClient.disableSecurity() // For performance testing
            
            // Run multiple operations concurrently
            let tasks = [
                Task { await validator.validateSecureConnection() },
                Task { await debugger.performSecurityInvestigation() },
                Task { 
                    do {
                        let _: MockResponse = try await secureClient.secureRequest(url: "https://httpbin.org/get")
                        return "success"
                    } catch {
                        return "error: \(error.localizedDescription)"
                    }
                },
                Task { return secureClient.exportSecurityReport() },
                Task { return await debugger.getInvestigationResults().count }
            ]
            
            // All operations should complete
            let startTime = Date()
            let _ = await withTaskGroup(of: Any.self) { group in
                for task in tasks {
                    group.addTask { await task.value }
                }
                
                var results: [Any] = []
                for await result in group {
                    results.append(result)
                }
                return results
            }
            let duration = Date().timeIntervalSince(startTime)
            
            // Concurrent operations should complete efficiently
            #expect(duration < 15.0) // Should be faster than sequential execution
        }
    }
    
    // MARK: - Error Handling Integration Tests
    
    @Suite("Error Handling Integration")
    struct ErrorHandlingIntegrationTests {
        
        @Test("Cascading error handling across components")
        func cascadingErrorHandlingAcrossComponents() async throws {
            let debugger = NetworkSecurityDebugger.shared
            let validator = NetworkSecurityValidator.shared
            let secureClient = SecureAPIClient.shared
            
            // Clear logs to track error propagation
            await debugger.clearAuditLog()
            secureClient.clearAuditLog()
            
            // Enable security (will cause API requests to fail)
            secureClient.enableSecurity()
            
            // Attempt API request (should fail due to security validation)
            do {
                let _: MockResponse = try await secureClient.secureRequest(url: "https://httpbin.org/get")
                #expect(Bool(false), "Request should have failed")
            } catch let error as SecureAPIError {
                // Expected security error
                #expect(error.localizedDescription.contains("security") || 
                       error.localizedDescription.contains("validation"))
                
                // Error should trigger security investigation
                await debugger.performSecurityInvestigation()
                
                // Should be logged across components
                let secureClientLog = secureClient.getSecurityAuditLog()
                let debuggerLog = await debugger.getAuditLog()
                
                let hasErrorLogged = secureClientLog.contains { log in
                    log.contains("SECURITY VIOLATION") || log.contains("Blocked")
                } || debuggerLog.contains { log in
                    log.contains("security") || log.contains("investigation")
                }
                
                #expect(hasErrorLogged)
            }
        }
        
        @Test("Recovery mechanisms integration")
        func recoveryMechanismsIntegration() async throws {
            let secureClient = SecureAPIClient.shared
            let debugger = NetworkSecurityDebugger.shared
            
            // Simulate error condition
            secureClient.enableSecurity()
            
            // Multiple failed requests
            for i in 1...3 {
                do {
                    let _: MockResponse = try await secureClient.secureRequest(
                        url: "https://httpbin.org/get?attempt=\(i)"
                    )
                } catch {
                    // Expected failures
                }
            }
            
            // Emergency recovery using emergency access
            do {
                let _: MockResponse = try await secureClient.emergencyRequest(
                    url: "https://httpbin.org/get",
                    reason: "Recovery from repeated failures"
                )
            } catch {
                // Network errors acceptable
            }
            
            // Disable security for recovery
            secureClient.disableSecurity(duration: 2.0)
            
            // Should now work
            do {
                let _: MockResponse = try await secureClient.secureRequest(url: "https://httpbin.org/get")
            } catch {
                // Network errors acceptable, but not security errors
                #expect(!(error is SecureAPIError && (error as! SecureAPIError).localizedDescription.contains("security")))
            }
            
            // Recovery actions should be logged
            let auditLog = secureClient.getSecurityAuditLog()
            let hasRecovery = auditLog.contains { log in
                log.contains("EMERGENCY") || log.contains("DISABLED")
            }
            #expect(hasRecovery)
        }
    }
    
    // MARK: - Real-world Scenario Tests
    
    @Suite("Real-world Scenarios")
    struct RealWorldScenarioTests {
        
        @Test("Complete VPN bypass investigation scenario")
        func completeVPNBypassInvestigationScenario() async throws {
            let debugger = NetworkSecurityDebugger.shared
            let validator = NetworkSecurityValidator.shared
            let secureClient = SecureAPIClient.shared
            
            // Scenario: User reports app working without VPN
            
            // Step 1: Initial state - security enabled, VPN appears disconnected
            secureClient.enableSecurity()
            await debugger.clearInvestigationResults()
            await debugger.clearAuditLog()
            secureClient.clearAuditLog()
            
            // Step 2: User attempts to use app features (API requests)
            let apiEndpoints = [
                "https://httpbin.org/get?feature=camera_feed",
                "https://httpbin.org/get?feature=event_list",
                "https://httpbin.org/get?feature=live_view"
            ]
            
            var successfulRequests = 0
            var failedRequests = 0
            
            for endpoint in apiEndpoints {
                do {
                    let _: MockResponse = try await secureClient.secureRequest(url: endpoint)
                    successfulRequests += 1
                } catch {
                    failedRequests += 1
                }
            }
            
            // Step 3: Trigger comprehensive security investigation
            await debugger.performSecurityInvestigation()
            
            // Step 4: Analyze results
            let validationResult = await validator.validateSecureConnection()
            let investigationResults = await debugger.getInvestigationResults()
            let securityReport = secureClient.exportSecurityReport()
            
            // Step 5: Verify comprehensive analysis was performed
            #expect(!investigationResults.isEmpty)
            #expect(validationResult.summary != nil)
            #expect(securityReport.contains("SECURITY AUDIT REPORT"))
            
            // Should have proper audit trail of the investigation
            let auditLog = secureClient.getSecurityAuditLog()
            let debuggerAudit = await debugger.getAuditLog()
            
            #expect(!auditLog.isEmpty || !debuggerAudit.isEmpty)
            
            // If requests succeeded when they shouldn't have, should be flagged
            if successfulRequests > 0 {
                let hasBypassDetection = investigationResults.contains { result in
                    result.contains("bypass") || result.contains("security") || result.contains("violation")
                } || auditLog.contains { log in
                    log.contains("SECURITY") || log.contains("bypass")
                }
                
                // Should detect potential bypass if requests succeeded
                #expect(hasBypassDetection || failedRequests == apiEndpoints.count)
            }
        }
        
        @Test("Emergency access during security incident")
        func emergencyAccessDuringSecurityIncident() async throws {
            let secureClient = SecureAPIClient.shared
            let debugger = NetworkSecurityDebugger.shared
            
            // Scenario: Security incident detected, need emergency access
            
            // Step 1: Security incident detected
            secureClient.enableSecurity()
            await debugger.logSecurityEvent("SECURITY INCIDENT: Unauthorized access attempt detected")
            
            // Step 2: Normal operations blocked
            do {
                let _: MockResponse = try await secureClient.secureRequest(
                    url: "https://httpbin.org/get?action=normal_operation"
                )
                #expect(Bool(false), "Normal operations should be blocked during security incident")
            } catch {
                // Expected to be blocked
            }
            
            // Step 3: Emergency access needed for incident response
            do {
                let _: MockResponse = try await secureClient.emergencyRequest(
                    url: "https://httpbin.org/get?action=incident_response",
                    reason: "Security incident response - immediate access required for threat mitigation"
                )
            } catch {
                // Network errors acceptable, but emergency access should not be blocked
                #expect(!(error is SecureAPIError && (error as! SecureAPIError).localizedDescription.contains("security")))
            }
            
            // Step 4: Comprehensive investigation after incident
            await debugger.performSecurityInvestigation()
            
            // Step 5: Verify complete incident audit trail
            let auditLog = secureClient.getSecurityAuditLog()
            let debuggerAudit = await debugger.getAuditLog()
            
            // Should have incident logged
            let hasIncidentLogged = debuggerAudit.contains { log in
                log.contains("SECURITY INCIDENT")
            }
            
            // Should have emergency access logged
            let hasEmergencyLogged = auditLog.contains { log in
                log.contains("EMERGENCY ACCESS") && log.contains("incident response")
            }
            
            // Should have investigation logged
            let hasInvestigationLogged = !await debugger.getInvestigationResults().isEmpty
            
            #expect(hasIncidentLogged)
            #expect(hasEmergencyLogged)
            #expect(hasInvestigationLogged)
            
            // Generate incident report
            let incidentReport = secureClient.exportSecurityReport()
            #expect(incidentReport.contains("SECURITY AUDIT REPORT"))
            #expect(incidentReport.contains("Bypass Attempts"))
        }
    }
}

// MARK: - Mock Response Structure for Integration Tests

struct MockResponse: Codable {
    let url: String?
    let args: [String: String]?
    let headers: [String: String]?
    let origin: String?
    let data: String?
    
    init() {
        self.url = "https://httpbin.org/get"
        self.args = [:]
        self.headers = [:]
        self.origin = "127.0.0.1"
        self.data = nil
    }
}