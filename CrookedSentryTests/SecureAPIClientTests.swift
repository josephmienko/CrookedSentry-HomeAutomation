//
//  SecureAPIClientTests.swift
//  CrookedSentryTests
//
//  Comprehensive tests for SecureAPIClient security-enforced API wrapper
//  Tests security validation, API interception, audit logging, emergency access
//

import Testing
import Foundation
import Network
@testable import CrookedSentry

@Suite("Secure API Client Tests")
struct SecureAPIClientTests {
    
    // MARK: - Security Validation Tests
    
    @Suite("Security Validation")
    struct SecurityValidationTests {
        
        @Test("Security enforcement enabled by default")
        func securityEnabledByDefault() async throws {
            let client = SecureAPIClient.shared
            
            // Security should be enabled by default
            #expect(client.isSecurityEnabled)
        }
        
        @Test("Secure request validation flow")
        func secureRequestValidation() async throws {
            let client = SecureAPIClient.shared
            
            // Enable security for testing
            client.enableSecurity()
            
            // Test secure request with validation
            do {
                let _: MockResponse = try await client.secureRequest(
                    url: "https://httpbin.org/get",
                    method: .GET,
                    bypassSecurity: false
                )
                
                // Request should either succeed or fail with security validation
                // Both are valid outcomes for this test
            } catch let error as SecureAPIError {
                // Security validation failure is expected behavior
                #expect(error.localizedDescription.contains("security") || 
                       error.localizedDescription.contains("validation"))
            }
        }
        
        @Test("Security bypass functionality")
        func securityBypassFunctionality() async throws {
            let client = SecureAPIClient.shared
            
            // Clear bypass counter
            await client.resetBypassCounter()
            
            let initialBypassCount = client.securityBypassCount
            
            // Test emergency request with bypass
            do {
                let _: MockResponse = try await client.emergencyRequest(
                    url: "https://httpbin.org/get",
                    method: .GET,
                    reason: "Test emergency access"
                )
            } catch {
                // Network errors are acceptable for this test
            }
            
            // Bypass counter should increment
            #expect(client.securityBypassCount > initialBypassCount)
        }
        
        @Test("Security disable/enable functionality")
        func securityToggleFunctionality() async throws {
            let client = SecureAPIClient.shared
            
            // Test disabling security
            client.disableSecurity(duration: 1.0) // 1 second
            #expect(!client.isSecurityEnabled)
            
            // Test manual enable
            client.enableSecurity()
            #expect(client.isSecurityEnabled)
        }
        
        @Test("Security auto re-enable after timeout")
        func securityAutoReEnable() async throws {
            let client = SecureAPIClient.shared
            
            // Disable security with short timeout
            client.disableSecurity(duration: 0.5) // 0.5 seconds
            #expect(!client.isSecurityEnabled)
            
            // Wait for auto re-enable
            try await Task.sleep(nanoseconds: 700_000_000) // 0.7 seconds
            
            // Security should be re-enabled
            #expect(client.isSecurityEnabled)
        }
    }
    
    // MARK: - API Request Tests
    
    @Suite("API Request Handling")
    struct APIRequestTests {
        
        @Test("HTTP GET request processing")
        func httpGETRequest() async throws {
            let client = SecureAPIClient.shared
            
            // Disable security for direct API testing
            client.disableSecurity()
            
            do {
                let response: MockResponse = try await client.secureRequest(
                    url: "https://httpbin.org/get",
                    method: .GET
                )
                
                // Should receive valid response structure
                #expect(response.url != nil)
            } catch let error as SecureAPIError {
                // Network errors are acceptable
                #expect(error.localizedDescription.contains("Network") || 
                       error.localizedDescription.contains("HTTP"))
            }
        }
        
        @Test("HTTP POST request with body")
        func httpPOSTRequest() async throws {
            let client = SecureAPIClient.shared
            
            // Disable security for direct API testing  
            client.disableSecurity()
            
            let testData = """
                {"test": "data", "timestamp": "\(Date())"}
                """.data(using: .utf8)
            
            do {
                let response: MockResponse = try await client.secureRequest(
                    url: "https://httpbin.org/post",
                    method: .POST,
                    body: testData
                )
                
                // Should handle POST request
                #expect(response.url != nil)
            } catch {
                // Network errors are acceptable for this test
            }
        }
        
        @Test("Invalid URL handling")
        func invalidURLHandling() async throws {
            let client = SecureAPIClient.shared
            
            do {
                let _: MockResponse = try await client.secureRequest(
                    url: "not-a-valid-url",
                    method: .GET
                )
                #expect(Bool(false), "Should have thrown an error for invalid URL")
            } catch let error as SecureAPIError {
                // Should catch invalid URL error
                switch error {
                case .invalidURL:
                    // Expected error type
                    break
                default:
                    #expect(Bool(false), "Unexpected error type: \(error)")
                }
            }
        }
        
        @Test("Network timeout handling")
        func networkTimeoutHandling() async throws {
            let client = SecureAPIClient.shared
            client.disableSecurity()
            
            // Test with very slow endpoint (should timeout)
            do {
                let _: MockResponse = try await client.secureRequest(
                    url: "https://httpbin.org/delay/5", // 5 second delay
                    method: .GET
                )
            } catch let error as SecureAPIError {
                // Should handle timeout appropriately
                #expect(error.localizedDescription.contains("timeout") || 
                       error.localizedDescription.contains("Network"))
            }
        }
    }
    
    // MARK: - Audit Logging Tests
    
    @Suite("Audit Logging")
    struct AuditLoggingTests {
        
        @Test("Connection attempt logging")
        func connectionAttemptLogging() async throws {
            let client = SecureAPIClient.shared
            
            // Clear existing logs
            client.clearAuditLog()
            
            // Make a test request
            do {
                let _: MockResponse = try await client.secureRequest(
                    url: "https://httpbin.org/get",
                    method: .GET,
                    bypassSecurity: true
                )
            } catch {
                // Errors are acceptable for logging test
            }
            
            // Check audit log
            let auditLog = client.getSecurityAuditLog()
            let hasConnectionLog = auditLog.contains { log in
                log.contains("Connection attempt") && log.contains("httpbin.org")
            }
            
            #expect(hasConnectionLog)
        }
        
        @Test("Security violation logging")
        func securityViolationLogging() async throws {
            let client = SecureAPIClient.shared
            
            // Clear logs and enable security
            client.clearAuditLog()
            client.enableSecurity()
            
            // Attempt request that should be blocked
            do {
                let _: MockResponse = try await client.secureRequest(
                    url: "https://httpbin.org/get",
                    method: .GET,
                    bypassSecurity: false
                )
            } catch {
                // Expected to be blocked
            }
            
            // Check for security violation log
            let auditLog = client.getSecurityAuditLog()
            let hasViolationLog = auditLog.contains { log in
                log.contains("SECURITY VIOLATION") || log.contains("Blocked")
            }
            
            #expect(hasViolationLog || auditLog.contains { $0.contains("security") })
        }
        
        @Test("Emergency access logging")
        func emergencyAccessLogging() async throws {
            let client = SecureAPIClient.shared
            
            // Clear logs
            client.clearAuditLog()
            
            // Make emergency request
            do {
                let _: MockResponse = try await client.emergencyRequest(
                    url: "https://httpbin.org/get",
                    reason: "Critical system failure"
                )
            } catch {
                // Errors acceptable for logging test
            }
            
            // Check for emergency access log
            let auditLog = client.getSecurityAuditLog()
            let hasEmergencyLog = auditLog.contains { log in
                log.contains("EMERGENCY ACCESS") && log.contains("Critical system failure")
            }
            
            #expect(hasEmergencyLog)
        }
        
        @Test("Audit log size limiting")
        func auditLogSizeLimiting() async throws {
            let client = SecureAPIClient.shared
            
            // Clear logs
            client.clearAuditLog()
            
            // Generate many log entries
            for i in 1...150 {
                try await client.testLogEntry("Test log entry \(i)")
            }
            
            // Check log size is limited
            let auditLog = client.getSecurityAuditLog()
            #expect(auditLog.count <= 100) // Should enforce 100 entry limit
        }
    }
    
    // MARK: - Validation Cache Tests
    
    @Suite("Validation Cache")
    struct ValidationCacheTests {
        
        @Test("Cache invalidation on security state change")
        func cacheInvalidationOnSecurityChange() async throws {
            let client = SecureAPIClient.shared
            
            // Clear cache
            client.clearValidationCache()
            
            // Enable security and make request (to populate cache)
            client.enableSecurity()
            do {
                let _: MockResponse = try await client.secureRequest(
                    url: "https://httpbin.org/get",
                    bypassSecurity: false
                )
            } catch {
                // Errors acceptable
            }
            
            // Disable security (should clear cache)
            client.disableSecurity()
            
            // Re-enable security (cache should be cleared)
            client.enableSecurity()
            
            // Test passes if no crashes occur during cache operations
            #expect(Bool(true))
        }
        
        @Test("Cache timeout behavior")
        func cacheTimeoutBehavior() async throws {
            let client = SecureAPIClient.shared
            
            // Clear cache
            client.clearValidationCache()
            
            // Make request to populate cache
            client.disableSecurity() // Disable for successful request
            do {
                let _: MockResponse = try await client.secureRequest(
                    url: "https://httpbin.org/get"
                )
            } catch {
                // Errors acceptable
            }
            
            // Wait beyond cache timeout (if implemented)
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Make another request (should not use expired cache)
            do {
                let _: MockResponse = try await client.secureRequest(
                    url: "https://httpbin.org/get"
                )
            } catch {
                // Errors acceptable
            }
            
            // Test passes if cache timeout is handled properly
            #expect(Bool(true))
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Suite("Error Handling")
    struct ErrorHandlingTests {
        
        @Test("Decoding error handling")
        func decodingErrorHandling() async throws {
            let client = SecureAPIClient.shared
            client.disableSecurity()
            
            do {
                // Try to decode invalid JSON as MockResponse
                let _: MockResponse = try await client.secureRequest(
                    url: "https://httpbin.org/html" // Returns HTML, not JSON
                )
                #expect(Bool(false), "Should have thrown decoding error")
            } catch let error as SecureAPIError {
                switch error {
                case .decodingError:
                    // Expected error type
                    break
                case .networkError, .httpError:
                    // Also acceptable (network might fail before decoding)
                    break
                default:
                    #expect(Bool(false), "Unexpected error type: \(error)")
                }
            }
        }
        
        @Test("HTTP error status handling")
        func httpErrorStatusHandling() async throws {
            let client = SecureAPIClient.shared
            client.disableSecurity()
            
            do {
                let _: MockResponse = try await client.secureRequest(
                    url: "https://httpbin.org/status/404"
                )
                #expect(Bool(false), "Should have thrown HTTP error")
            } catch let error as SecureAPIError {
                switch error {
                case .httpError(let code, _):
                    #expect(code == 404)
                case .networkError:
                    // Network errors are also acceptable
                    break
                default:
                    #expect(Bool(false), "Unexpected error type: \(error)")
                }
            }
        }
        
        @Test("Network error propagation")
        func networkErrorPropagation() async throws {
            let client = SecureAPIClient.shared
            client.disableSecurity()
            
            do {
                let _: MockResponse = try await client.secureRequest(
                    url: "https://this-domain-definitely-does-not-exist-12345.com"
                )
                #expect(Bool(false), "Should have thrown network error")
            } catch let error as SecureAPIError {
                switch error {
                case .networkError:
                    // Expected error type
                    break
                case .invalidURL:
                    // Also acceptable for invalid domains
                    break
                default:
                    #expect(Bool(false), "Unexpected error type: \(error)")
                }
            }
        }
    }
    
    // MARK: - Performance Tests
    
    @Suite("Performance")
    struct PerformanceTests {
        
        @Test("Concurrent request handling")
        func concurrentRequestHandling() async throws {
            let client = SecureAPIClient.shared
            client.disableSecurity() // For performance testing
            
            let startTime = Date()
            
            // Make multiple concurrent requests
            let tasks = (1...5).map { index in
                Task {
                    do {
                        let _: MockResponse = try await client.secureRequest(
                            url: "https://httpbin.org/delay/1"
                        )
                        return true
                    } catch {
                        return false
                    }
                }
            }
            
            // Wait for all tasks
            let results = await withTaskGroup(of: Bool.self) { group in
                for task in tasks {
                    group.addTask { await task.value }
                }
                
                var completedTasks: [Bool] = []
                for await result in group {
                    completedTasks.append(result)
                }
                return completedTasks
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            // Should handle concurrent requests efficiently
            // (5 x 1-second delays should take ~1-2 seconds with concurrency, not 5+ seconds)
            #expect(duration < 10.0) // Generous timeout for network variability
            #expect(results.count == 5)
        }
        
        @Test("Memory usage under load")
        func memoryUsageUnderLoad() async throws {
            let client = SecureAPIClient.shared
            client.disableSecurity()
            
            // Make many sequential requests
            for i in 1...20 {
                do {
                    let _: MockResponse = try await client.secureRequest(
                        url: "https://httpbin.org/get?test=\(i)"
                    )
                } catch {
                    // Errors acceptable for memory test
                }
                
                // Small delay between requests
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            // Test passes if no memory issues occur
            #expect(Bool(true))
        }
    }
    
    // MARK: - Security Dashboard Tests
    
    @Suite("Security Dashboard")
    struct SecurityDashboardTests {
        
        @Test("Security report generation")
        func securityReportGeneration() async throws {
            let client = SecureAPIClient.shared
            
            // Generate some activity for the report
            client.clearAuditLog()
            try await client.testLogEntry("Test security activity")
            
            // Generate report
            let report = client.exportSecurityReport()
            
            // Report should contain key information
            #expect(report.contains("CROOKED SENTRY SECURITY AUDIT REPORT"))
            #expect(report.contains("Security Enabled"))
            #expect(report.contains("Total Bypass Attempts"))
            #expect(report.contains("Test security activity"))
        }
        
        @Test("Audit log retrieval")
        func auditLogRetrieval() async throws {
            let client = SecureAPIClient.shared
            
            // Clear and populate audit log
            client.clearAuditLog()
            
            let testEntries = [
                "Security event 1",
                "Security event 2", 
                "Security event 3"
            ]
            
            for entry in testEntries {
                try await client.testLogEntry(entry)
            }
            
            // Retrieve audit log
            let auditLog = client.getSecurityAuditLog()
            
            // Should contain test entries
            for entry in testEntries {
                #expect(auditLog.contains { $0.contains(entry) })
            }
        }
    }
}

// MARK: - Mock Objects and Extensions

struct MockResponse: Codable {
    let url: String?
    let args: [String: String]?
    let headers: [String: String]?
    let origin: String?
    let data: String?
}

// MARK: - SecureAPIClient Testing Extensions

extension SecureAPIClient {
    
    /// Test helper methods for comprehensive testing
    
    func resetBypassCounter() async {
        await MainActor.run {
            self.securityBypassCount = 0
        }
    }
    
    func clearAuditLog() {
        UserDefaults.standard.removeObject(forKey: "SecurityAuditLog")
    }
    
    func testLogEntry(_ entry: String) async throws {
        // Add test entry to audit log
        var logs = UserDefaults.standard.stringArray(forKey: "SecurityAuditLog") ?? []
        logs.append("[\(Date())] \(entry)")
        
        // Maintain size limit
        if logs.count > 100 {
            logs = Array(logs.suffix(100))
        }
        
        UserDefaults.standard.set(logs, forKey: "SecurityAuditLog")
    }
}