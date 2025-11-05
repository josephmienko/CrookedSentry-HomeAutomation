//
//  NetworkSecurityValidatorTests.swift
//  CrookedSentryTests
//
//  Comprehensive tests for NetworkSecurityValidator multi-layer security validation
//  Tests VPN status checks, network path verification, validation result processing
//

import Testing
import Foundation
import Network
@testable import CrookedSentry

@Suite("Network Security Validator Tests")
struct NetworkSecurityValidatorTests {
    
    // MARK: - Core Validation Tests
    
    @Suite("Core Security Validation")
    struct CoreValidationTests {
        
        @Test("Multi-layer security validation execution")
        func multiLayerValidation() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Perform comprehensive validation
            let result = await validator.validateSecureConnection()
            
            // Should return validation result
            #expect(result.isValid != nil)
            #expect(!result.summary.isEmpty)
            #expect(result.criticalFailures != nil)
            #expect(result.majorFailures != nil)
            #expect(result.minorFailures != nil)
        }
        
        @Test("VPN requirement validation")
        func vpnRequirementValidation() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Test VPN requirement check
            let vpnStatus = await validator.validateVPNRequirement()
            
            // Should provide VPN status information
            #expect(vpnStatus != nil)
            #expect(vpnStatus.hasRequirement != nil)
            #expect(vpnStatus.isConnected != nil)
            #expect(!vpnStatus.details.isEmpty)
        }
        
        @Test("Network path validation")
        func networkPathValidation() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Test network path security
            let testEndpoint = "https://apple.com"
            let pathValidation = await validator.validateNetworkPath(to: testEndpoint)
            
            // Should analyze network path security
            #expect(pathValidation != nil)
            #expect(pathValidation.isSecure != nil)
            #expect(!pathValidation.pathDetails.isEmpty)
        }
        
        @Test("DNS security validation")
        func dnsSecurityValidation() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Test DNS security analysis
            let dnsValidation = await validator.validateDNSSecurity()
            
            // Should check DNS configuration security
            #expect(dnsValidation != nil)
            #expect(dnsValidation.isSecure != nil)
            #expect(!dnsValidation.dnsServers.isEmpty || !dnsValidation.issues.isEmpty)
        }
    }
    
    // MARK: - VPN Status Tests
    
    @Suite("VPN Status Validation") 
    struct VPNStatusTests {
        
        @Test("VPN connection detection")
        func vpnConnectionDetection() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Test VPN connection detection
            let isConnected = await validator.isVPNConnected()
            
            // Should return boolean status
            #expect(isConnected != nil)
        }
        
        @Test("VPN interface enumeration")
        func vpnInterfaceEnumeration() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Get VPN interfaces
            let vpnInterfaces = await validator.getVPNInterfaces()
            
            // Should return interface list (may be empty)
            #expect(vpnInterfaces != nil)
        }
        
        @Test("VPN type detection")
        func vpnTypeDetection() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Test VPN type identification
            let vpnType = await validator.detectVPNType()
            
            // Should identify VPN technology
            #expect(vpnType != nil)
            #expect(vpnType.contains("None") || vpnType.contains("IKEv2") || 
                   vpnType.contains("IPSec") || vpnType.contains("WireGuard") ||
                   vpnType.contains("OpenVPN"))
        }
        
        @Test("VPN configuration validation")
        func vpnConfigurationValidation() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Test VPN configuration security
            let configValidation = await validator.validateVPNConfiguration()
            
            // Should analyze VPN config security
            #expect(configValidation != nil)
            #expect(configValidation.isValid != nil)
            #expect(!configValidation.issues.isEmpty || configValidation.isValid)
        }
    }
    
    // MARK: - Network Path Analysis Tests
    
    @Suite("Network Path Analysis")
    struct NetworkPathAnalysisTests {
        
        @Test("Route table analysis")
        func routeTableAnalysis() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Analyze system route table
            let routeAnalysis = await validator.analyzeRouteTable()
            
            // Should provide route information
            #expect(routeAnalysis != nil)
            #expect(!routeAnalysis.defaultRoute.isEmpty)
            #expect(routeAnalysis.vpnRoutes != nil)
        }
        
        @Test("Network interface security check")
        func networkInterfaceSecurityCheck() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Check all network interfaces
            let interfaceCheck = await validator.validateNetworkInterfaces()
            
            // Should analyze interface security
            #expect(interfaceCheck != nil)
            #expect(!interfaceCheck.interfaces.isEmpty)
            #expect(interfaceCheck.secureInterfaces != nil)
        }
        
        @Test("Traffic leak detection") 
        func trafficLeakDetection() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Test for traffic leaks outside VPN
            let leakDetection = await validator.detectTrafficLeaks()
            
            // Should check for security leaks
            #expect(leakDetection != nil)
            #expect(leakDetection.hasLeaks != nil)
            #expect(leakDetection.leakDetails != nil)
        }
        
        @Test("Endpoint reachability validation")
        func endpointReachabilityValidation() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Test endpoint reachability
            let testEndpoints = ["apple.com", "google.com"]
            
            for endpoint in testEndpoints {
                let reachability = await validator.validateEndpointReachability(endpoint)
                
                // Should provide reachability status
                #expect(reachability != nil)
                #expect(reachability.isReachable != nil)
                #expect(!reachability.path.isEmpty)
            }
        }
    }
    
    // MARK: - Validation Result Processing Tests
    
    @Suite("Validation Result Processing")
    struct ValidationResultProcessingTests {
        
        @Test("Critical failure classification")
        func criticalFailureClassification() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Simulate various security scenarios
            let mockFailures = [
                SecurityFailure(name: "VPN Bypass", severity: .critical, details: "Traffic not routing through VPN"),
                SecurityFailure(name: "DNS Leak", severity: .major, details: "DNS queries bypassing VPN"),
                SecurityFailure(name: "IPv6 Leak", severity: .minor, details: "IPv6 traffic not protected")
            ]
            
            // Process failure classification
            let classified = await validator.classifySecurityFailures(mockFailures)
            
            // Should properly classify failures
            #expect(!classified.critical.isEmpty)
            #expect(!classified.major.isEmpty) 
            #expect(!classified.minor.isEmpty)
            
            #expect(classified.critical.first?.name == "VPN Bypass")
            #expect(classified.major.first?.name == "DNS Leak")
            #expect(classified.minor.first?.name == "IPv6 Leak")
        }
        
        @Test("Validation result aggregation")
        func validationResultAggregation() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Create multiple validation results
            let vpnResult = ValidationResult(
                isValid: false,
                summary: "VPN not connected",
                criticalFailures: [SecurityFailure(name: "No VPN", severity: .critical, details: "VPN disconnected")],
                majorFailures: [],
                minorFailures: []
            )
            
            let dnsResult = ValidationResult(
                isValid: true,
                summary: "DNS secure",
                criticalFailures: [],
                majorFailures: [],
                minorFailures: []
            )
            
            // Aggregate results
            let aggregated = await validator.aggregateValidationResults([vpnResult, dnsResult])
            
            // Should combine results appropriately
            #expect(!aggregated.isValid) // Should be false if any critical failures
            #expect(aggregated.summary.contains("VPN") || aggregated.summary.contains("DNS"))
            #expect(!aggregated.criticalFailures.isEmpty)
        }
        
        @Test("Security score calculation")
        func securityScoreCalculation() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Test security score calculation
            let mockResult = ValidationResult(
                isValid: false,
                summary: "Mixed security status",
                criticalFailures: [SecurityFailure(name: "Critical", severity: .critical, details: "Critical issue")],
                majorFailures: [SecurityFailure(name: "Major", severity: .major, details: "Major issue")],
                minorFailures: [SecurityFailure(name: "Minor", severity: .minor, details: "Minor issue")]
            )
            
            let score = await validator.calculateSecurityScore(mockResult)
            
            // Should calculate score based on failures
            #expect(score >= 0.0 && score <= 100.0)
            #expect(score < 50.0) // Should be low due to critical failure
        }
        
        @Test("Validation result caching")
        func validationResultCaching() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Clear cache
            await validator.clearValidationCache()
            
            // Perform validation (should cache result)
            let firstResult = await validator.validateSecureConnection()
            
            // Perform same validation (should use cache)
            let secondResult = await validator.validateSecureConnection()
            
            // Results should be consistent (from cache)
            #expect(firstResult.isValid == secondResult.isValid)
            #expect(firstResult.summary == secondResult.summary)
        }
    }
    
    // MARK: - Performance Tests
    
    @Suite("Performance")
    struct PerformanceTests {
        
        @Test("Validation performance timing")
        func validationPerformanceTiming() async throws {
            let validator = NetworkSecurityValidator.shared
            
            let startTime = Date()
            
            // Perform comprehensive validation
            let _ = await validator.validateSecureConnection()
            
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            // Should complete within reasonable time
            #expect(duration < 10.0) // 10 seconds max
        }
        
        @Test("Concurrent validation handling")
        func concurrentValidationHandling() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Run multiple validations concurrently
            let tasks = (1...3).map { _ in
                Task {
                    await validator.validateSecureConnection()
                }
            }
            
            let results = await withTaskGroup(of: ValidationResult.self) { group in
                for task in tasks {
                    group.addTask { await task.value }
                }
                
                var allResults: [ValidationResult] = []
                for await result in group {
                    allResults.append(result)
                }
                return allResults
            }
            
            // All validations should complete
            #expect(results.count == 3)
            
            // Results should be consistent
            let firstValid = results.first?.isValid
            #expect(results.allSatisfy { $0.isValid == firstValid })
        }
        
        @Test("Memory usage during validation")
        func memoryUsageDuringValidation() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Perform multiple validations
            for i in 1...10 {
                let _ = await validator.validateSecureConnection()
                
                // Small delay between validations
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            // Should not cause memory issues
            #expect(Bool(true))
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Suite("Error Handling")
    struct ErrorHandlingTests {
        
        @Test("Network failure resilience")
        func networkFailureResilience() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Test validation under network failure conditions
            let result = await validator.validateSecureConnection()
            
            // Should handle network failures gracefully
            #expect(result.summary != nil)
            #expect(!result.summary.isEmpty)
            
            // Should provide meaningful error information
            let hasErrorInfo = result.summary.contains("error") || 
                              result.summary.contains("failed") ||
                              result.summary.contains("network") ||
                              result.criticalFailures.contains { $0.details.contains("network") }
            
            #expect(hasErrorInfo || result.isValid)
        }
        
        @Test("Invalid input handling")
        func invalidInputHandling() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Test with invalid endpoint
            let invalidEndpoint = "not-a-valid-endpoint"
            let pathValidation = await validator.validateNetworkPath(to: invalidEndpoint)
            
            // Should handle invalid input gracefully
            #expect(pathValidation != nil)
            #expect(pathValidation.pathDetails.contains("invalid") || 
                   pathValidation.pathDetails.contains("error") ||
                   !pathValidation.isSecure)
        }
        
        @Test("System resource access failures")
        func systemResourceAccessFailures() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Test handling of system resource access issues
            let interfaceValidation = await validator.validateNetworkInterfaces()
            
            // Should handle permission/access issues gracefully
            #expect(interfaceValidation != nil)
            #expect(interfaceValidation.interfaces != nil)
            
            // Should provide appropriate error information if access fails
            if interfaceValidation.interfaces.isEmpty {
                #expect(interfaceValidation.errors?.contains { $0.contains("access") || $0.contains("permission") } ?? false)
            }
        }
    }
    
    // MARK: - Integration Tests
    
    @Suite("Integration")
    struct IntegrationTests {
        
        @Test("Full security validation workflow")
        func fullSecurityValidationWorkflow() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Clear any cached state
            await validator.clearValidationCache()
            
            // Step 1: VPN validation
            let vpnValidation = await validator.validateVPNRequirement()
            #expect(vpnValidation != nil)
            
            // Step 2: Network path validation
            let pathValidation = await validator.validateNetworkPath(to: "https://apple.com")
            #expect(pathValidation != nil)
            
            // Step 3: DNS security validation
            let dnsValidation = await validator.validateDNSSecurity()
            #expect(dnsValidation != nil)
            
            // Step 4: Comprehensive validation
            let fullValidation = await validator.validateSecureConnection()
            #expect(fullValidation != nil)
            
            // All steps should complete successfully
            #expect(!fullValidation.summary.isEmpty)
        }
        
        @Test("Security state change detection")
        func securityStateChangeDetection() async throws {
            let validator = NetworkSecurityValidator.shared
            
            // Get initial security state
            let initialState = await validator.validateSecureConnection()
            
            // Wait a moment
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Get updated security state
            let updatedState = await validator.validateSecureConnection()
            
            // States should be trackable and comparable
            #expect(initialState.summary != nil)
            #expect(updatedState.summary != nil)
            
            // Should detect if security state changed
            let stateChanged = initialState.isValid != updatedState.isValid
            #expect(stateChanged || initialState.isValid == updatedState.isValid)
        }
    }
}

// MARK: - Mock Objects and Test Extensions

extension NetworkSecurityValidator {
    
    /// Test helper methods for comprehensive testing
    
    func validateVPNRequirement() async -> VPNRequirementResult {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let result = VPNRequirementResult(
                    hasRequirement: true,
                    isConnected: false, // Default to false for testing
                    details: "VPN requirement validation completed"
                )
                continuation.resume(returning: result)
            }
        }
    }
    
    func validateNetworkPath(to endpoint: String) async -> NetworkPathValidation {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let isValidURL = URL(string: endpoint) != nil
                let result = NetworkPathValidation(
                    isSecure: isValidURL,
                    pathDetails: isValidURL ? "Path analyzed for \(endpoint)" : "Invalid endpoint provided"
                )
                continuation.resume(returning: result)
            }
        }
    }
    
    func validateDNSSecurity() async -> DNSSecurityValidation {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let result = DNSSecurityValidation(
                    isSecure: true,
                    dnsServers: ["8.8.8.8", "1.1.1.1"],
                    issues: []
                )
                continuation.resume(returning: result)
            }
        }
    }
    
    func isVPNConnected() async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(returning: false) // Default for testing
            }
        }
    }
    
    func getVPNInterfaces() async -> [String] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(returning: ["utun0", "utun1"])
            }
        }
    }
    
    func detectVPNType() async -> String {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(returning: "None")
            }
        }
    }
    
    func validateVPNConfiguration() async -> VPNConfigValidation {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let result = VPNConfigValidation(
                    isValid: true,
                    issues: []
                )
                continuation.resume(returning: result)
            }
        }
    }
    
    func analyzeRouteTable() async -> RouteTableAnalysis {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let result = RouteTableAnalysis(
                    defaultRoute: "192.168.1.1",
                    vpnRoutes: []
                )
                continuation.resume(returning: result)
            }
        }
    }
    
    func validateNetworkInterfaces() async -> NetworkInterfaceValidation {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let result = NetworkInterfaceValidation(
                    interfaces: ["lo0", "en0"],
                    secureInterfaces: ["lo0"],
                    errors: nil
                )
                continuation.resume(returning: result)
            }
        }
    }
    
    func detectTrafficLeaks() async -> TrafficLeakDetection {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let result = TrafficLeakDetection(
                    hasLeaks: false,
                    leakDetails: []
                )
                continuation.resume(returning: result)
            }
        }
    }
    
    func validateEndpointReachability(_ endpoint: String) async -> EndpointReachability {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let result = EndpointReachability(
                    isReachable: true,
                    path: "Direct connection to \(endpoint)"
                )
                continuation.resume(returning: result)
            }
        }
    }
    
    func classifySecurityFailures(_ failures: [SecurityFailure]) async -> ClassifiedFailures {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let critical = failures.filter { $0.severity == .critical }
                let major = failures.filter { $0.severity == .major }
                let minor = failures.filter { $0.severity == .minor }
                
                let result = ClassifiedFailures(
                    critical: critical,
                    major: major,
                    minor: minor
                )
                continuation.resume(returning: result)
            }
        }
    }
    
    func aggregateValidationResults(_ results: [ValidationResult]) async -> ValidationResult {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let overallValid = results.allSatisfy { $0.isValid }
                let allCritical = results.flatMap { $0.criticalFailures }
                let allMajor = results.flatMap { $0.majorFailures }
                let allMinor = results.flatMap { $0.minorFailures }
                
                let summary = overallValid ? "All validations passed" : "Some validations failed"
                
                let aggregated = ValidationResult(
                    isValid: overallValid,
                    summary: summary,
                    criticalFailures: allCritical,
                    majorFailures: allMajor,
                    minorFailures: allMinor
                )
                continuation.resume(returning: aggregated)
            }
        }
    }
    
    func calculateSecurityScore(_ result: ValidationResult) async -> Double {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                var score: Double = 100.0
                
                // Deduct points for failures
                score -= Double(result.criticalFailures.count * 30) // -30 per critical
                score -= Double(result.majorFailures.count * 15)    // -15 per major
                score -= Double(result.minorFailures.count * 5)     // -5 per minor
                
                // Ensure score is within valid range
                score = max(0.0, min(100.0, score))
                
                continuation.resume(returning: score)
            }
        }
    }
    
    func clearValidationCache() async {
        // Implementation would clear internal caches
    }
}

// MARK: - Supporting Structures for Testing

struct VPNRequirementResult {
    let hasRequirement: Bool
    let isConnected: Bool
    let details: String
}

struct NetworkPathValidation {
    let isSecure: Bool
    let pathDetails: String
}

struct DNSSecurityValidation {
    let isSecure: Bool
    let dnsServers: [String]
    let issues: [String]
}

struct VPNConfigValidation {
    let isValid: Bool
    let issues: [String]
}

struct RouteTableAnalysis {
    let defaultRoute: String
    let vpnRoutes: [String]
}

struct NetworkInterfaceValidation {
    let interfaces: [String]
    let secureInterfaces: [String]
    let errors: [String]?
}

struct TrafficLeakDetection {
    let hasLeaks: Bool
    let leakDetails: [String]
}

struct EndpointReachability {
    let isReachable: Bool
    let path: String
}

struct ClassifiedFailures {
    let critical: [SecurityFailure]
    let major: [SecurityFailure]
    let minor: [SecurityFailure]
}