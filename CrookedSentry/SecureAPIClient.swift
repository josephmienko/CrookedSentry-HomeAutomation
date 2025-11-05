//
//  SecureAPIClient.swift
//  CrookedSentry
//
//  Security-Enforced API Client Wrapper
//  Created by Assistant on 2025
//

import Foundation
import Network
import SwiftUI
import Combine

/// Security-enforced wrapper for all API clients that validates network security before allowing connections
class SecureAPIClient: ObservableObject {
    static let shared = SecureAPIClient()
    
    @Published var isSecurityEnabled = true
    @Published var lastSecurityValidation: Date?
    @Published var securityBypassCount = 0
    
    private let validator = NetworkSecurityValidator.shared
    private let debugger = NetworkSecurityDebugger.shared
    
    // Cache for validated connections (short-lived)
    private var validationCache: [String: (isValid: Bool, timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 60 // 1 minute
    
    private init() {}
    
    // MARK: - Secure Connection Enforcement
    
    /// Primary method to validate and execute secure requests
    func secureRequest<T: Decodable>(
        url: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        decoder: JSONDecoder = JSONDecoder(),
        bypassSecurity: Bool = false
    ) async throws -> T {
        
        // Log all connection attempts for security audit
        logConnectionAttempt(url: url, method: method, bypassRequested: bypassSecurity)
        
        // Security validation (unless explicitly bypassed for emergency access)
        if isSecurityEnabled && !bypassSecurity {
            let isValid = try await validateSecureConnection(for: url)
            
            if !isValid {
                await recordSecurityViolation(url: url, method: method)
                throw SecureAPIError.securityValidationFailed("Network security validation failed for \(url)")
            }
        }
        
        // If bypassed, increment counter for monitoring
        if bypassSecurity {
            await incrementBypassCounter()
        }
        
        // Execute the actual request
        return try await performRequest(url: url, method: method, body: body, decoder: decoder)
    }
    
    /// Validates network security for a specific endpoint
    private func validateSecureConnection(for url: String) async throws -> Bool {
        let cacheKey = getCacheKey(for: url)
        
        // Check validation cache first
        if let cached = validationCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            print("🔐 Using cached validation for \(url): \(cached.isValid)")
            return cached.isValid
        }
        
        // Perform full security validation
        print("🔐 Validating secure connection for: \(url)")
        
        let result = await validator.validateSecureConnection()
        
        // Cache the result
        validationCache[cacheKey] = (result.isValid, Date())
        
        // Update last validation time
        await MainActor.run {
            lastSecurityValidation = Date()
        }
        
        // Log validation result
        await logValidationResult(url: url, result: result)
        
        return result.isValid
    }
    
    /// Performs the actual HTTP request
    private func performRequest<T: Decodable>(
        url: String,
        method: HTTPMethod,
        body: Data?,
        decoder: JSONDecoder
    ) async throws -> T {
        
        guard let requestURL = URL(string: url) else {
            throw SecureAPIError.invalidURL(url)
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        request.setValue("CrookedSentry-iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")
        
        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // Use a custom URLSession with security-focused configuration
        let session = createSecureURLSession()
        
        do {
            let startTime = Date()
            let (data, response) = try await session.data(for: request)
            let duration = Date().timeIntervalSince(startTime)
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SecureAPIError.invalidResponse("Non-HTTP response received")
            }
            
            // Log response details for security monitoring
            logResponseDetails(url: url, response: httpResponse, duration: duration, dataSize: data.count)
            
            // Check status code
            guard (200...299).contains(httpResponse.statusCode) else {
                throw SecureAPIError.httpError(httpResponse.statusCode, String(data: data, encoding: .utf8))
            }
            
            // Decode response
            return try decoder.decode(T.self, from: data)
            
        } catch let error as DecodingError {
            throw SecureAPIError.decodingError(error)
        } catch let error as SecureAPIError {
            throw error
        } catch {
            throw SecureAPIError.networkError(error)
        }
    }
    
    /// Creates a security-focused URLSession configuration
    private func createSecureURLSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral // No persistent caching
        
        // Security-focused configuration
        config.httpShouldUsePipelining = false
        config.httpMaximumConnectionsPerHost = 2
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil // Disable all caching
        
        // Network access controls
        config.allowsCellularAccess = false // Only allow when secure connection validated
        config.allowsExpensiveNetworkAccess = false
        config.allowsConstrainedNetworkAccess = false
        
        // Additional headers for security
        config.httpAdditionalHeaders = [
            "Cache-Control": "no-cache, no-store, must-revalidate",
            "Pragma": "no-cache",
            "X-Security-Level": "enforced"
        ]
        
        return URLSession(configuration: config)
    }
    
    // MARK: - Security Monitoring and Logging
    
    private func logConnectionAttempt(url: String, method: HTTPMethod, bypassRequested: Bool) {
        let timestamp = Date()
        let logEntry = "[\(timestamp)] 🔐 Connection attempt: \(method.rawValue) \(url) (bypass: \(bypassRequested))"
        
        print(logEntry)
        
        // Store in security audit log
        appendToSecurityLog(logEntry)
    }
    
    private func logValidationResult(url: String, result: ValidationResult) async {
        let status = result.isValid ? "✅ VALID" : "❌ INVALID"
        let logEntry = "[\(Date())] 🔐 Validation: \(url) -> \(status) - \(result.summary)"
        
        print(logEntry)
        appendToSecurityLog(logEntry)
        
        // If validation failed, log details
        if !result.isValid {
            for failure in result.criticalFailures {
                let failureLog = "[\(Date())] 🚨 Critical: \(failure.name) - \(failure.details)"
                print(failureLog)
                appendToSecurityLog(failureLog)
            }
        }
    }
    
    private func logResponseDetails(url: String, response: HTTPURLResponse, duration: TimeInterval, dataSize: Int) {
        let logEntry = "[\(Date())] 📡 Response: \(response.statusCode) from \(url) (\(String(format: "%.3f", duration))s, \(dataSize) bytes)"
        print(logEntry)
        appendToSecurityLog(logEntry)
        
        // Log suspicious response patterns
        if duration > 5.0 {
            let suspiciousLog = "[\(Date())] ⚠️ Slow response: \(url) took \(String(format: "%.3f", duration))s"
            print(suspiciousLog)
            appendToSecurityLog(suspiciousLog)
        }
        
        if dataSize > 10_000_000 { // > 10MB
            let suspiciousLog = "[\(Date())] ⚠️ Large response: \(url) returned \(dataSize) bytes"
            print(suspiciousLog)
            appendToSecurityLog(suspiciousLog)
        }
    }
    
    private func recordSecurityViolation(url: String, method: HTTPMethod) async {
        let violation = "[\(Date())] 🚨 SECURITY VIOLATION: Blocked \(method.rawValue) \(url)"
        print(violation)
        appendToSecurityLog(violation)
        
        // Trigger security investigation
        Task {
            await debugger.performSecurityInvestigation()
        }
    }
    
    private func incrementBypassCounter() async {
        await MainActor.run {
            securityBypassCount += 1
        }
        
        let bypassLog = "[\(Date())] ⚠️ Security bypass #\(securityBypassCount + 1)"
        print(bypassLog)
        appendToSecurityLog(bypassLog)
    }
    
    private func appendToSecurityLog(_ entry: String) {
        // In production, this would write to a secure log file
        // For now, we'll store in UserDefaults (limited storage)
        var existingLogs = UserDefaults.standard.stringArray(forKey: "SecurityAuditLog") ?? []
        existingLogs.append(entry)
        
        // Keep only last 100 entries to prevent storage issues
        if existingLogs.count > 100 {
            existingLogs = Array(existingLogs.suffix(100))
        }
        
        UserDefaults.standard.set(existingLogs, forKey: "SecurityAuditLog")
    }
    
    // MARK: - Cache Management
    
    private func getCacheKey(for url: String) -> String {
        // Create cache key based on URL host and VPN status
        guard let parsedURL = URL(string: url) else { return url }
        let host = parsedURL.host ?? "unknown"
        // TODO: Replace with actual VPN status when VPNManager is implemented
        let vpnStatus = false // Placeholder until VPNManager is available
        return "\(host)-vpn:\(vpnStatus)"
    }
    
    /// Clears validation cache (call when network state changes)
    func clearValidationCache() {
        validationCache.removeAll()
        print("🔐 Validation cache cleared")
    }
    
    // MARK: - Emergency Access
    
    /// Provides emergency access with security override (use sparingly)
    func emergencyRequest<T: Decodable>(
        url: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        decoder: JSONDecoder = JSONDecoder(),
        reason: String
    ) async throws -> T {
        
        let emergencyLog = "[\(Date())] 🚨 EMERGENCY ACCESS: \(url) - Reason: \(reason)"
        print(emergencyLog)
        appendToSecurityLog(emergencyLog)
        
        // Perform request with security bypass
        return try await secureRequest(
            url: url,
            method: method,
            body: body,
            decoder: decoder,
            bypassSecurity: true
        )
    }
    
    // MARK: - Security Configuration
    
    /// Temporarily disable security (for debugging only)
    func disableSecurity(duration: TimeInterval = 300) { // 5 minutes default
        isSecurityEnabled = false
        
        let disableLog = "[\(Date())] ⚠️ Security DISABLED for \(duration) seconds"
        print(disableLog)
        appendToSecurityLog(disableLog)
        
        // Re-enable after timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.enableSecurity()
        }
    }
    
    func enableSecurity() {
        isSecurityEnabled = true
        clearValidationCache() // Force revalidation
        
        let enableLog = "[\(Date())] ✅ Security ENABLED"
        print(enableLog)
        appendToSecurityLog(enableLog)
    }
    
    // MARK: - Security Report
    
    func getSecurityAuditLog() -> [String] {
        return UserDefaults.standard.stringArray(forKey: "SecurityAuditLog") ?? []
    }
    
    func exportSecurityReport() -> String {
        let logs = getSecurityAuditLog()
        let currentDate = Date().description
        let securityStatus = isSecurityEnabled ? "Enabled" : "Disabled"
        let bypassAttemptsText = String(securityBypassCount)
        let lastValidationText = lastSecurityValidation?.description ?? "Never"
        
        let header = [
            "=== CROOKED SENTRY SECURITY AUDIT REPORT ===",
            "Generated: \(currentDate)",
            "Security Enabled: \(securityStatus)",
            "Total Bypass Attempts: \(bypassAttemptsText)",
            "Last Validation: \(lastValidationText)",
            "",
            "=== SECURITY LOG ===",
        ]
        
        let report = header + logs
        return report.joined(separator: "\n")
    }
}

// MARK: - Error Types

enum SecureAPIError: LocalizedError {
    case securityValidationFailed(String)
    case invalidURL(String)
    case invalidResponse(String)
    case httpError(Int, String?)
    case networkError(Error)
    case decodingError(DecodingError)
    
    var errorDescription: String? {
        switch self {
        case .securityValidationFailed(let message):
            return "Security validation failed: \(message)"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .httpError(let code, let message):
            return "HTTP \(code): \(message ?? "Unknown error")"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

// Note: Using existing HTTPMethod from Core/Network/HTTPMethod.swift

// MARK: - Convenience Extensions for Existing API Clients

extension FrigateAPIClient {
    /// Secure version of fetchEvents that enforces security validation
    func fetchEventsSecure(
        camera: String? = nil,
        label: String? = nil,
        zone: String? = nil,
        limit: Int? = nil,
        inProgress: Bool = false,
        sortBy: String? = nil
    ) async throws -> [FrigateEvent] {
        
        var queryItems: [URLQueryItem] = []
        
        if let camera = camera {
            queryItems.append(URLQueryItem(name: "cameras", value: camera))
        }
        
        if let label = label {
            queryItems.append(URLQueryItem(name: "labels", value: label))
        }
        
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        
        queryItems.append(URLQueryItem(name: "in_progress", value: String(inProgress)))
        
        var components = URLComponents(string: "\(baseURL)/api/events")!
        components.queryItems = queryItems
        
        guard let url = components.url?.absoluteString else {
            throw SecureAPIError.invalidURL("Failed to construct events URL")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try await SecureAPIClient.shared.secureRequest(
            url: url,
            decoder: decoder
        )
    }
    
    /// Secure version of testConnectivity
    func testConnectivitySecure() async throws -> Bool {
        let url = "\(baseURL)/api/version"
        
        do {
            // Use a simple structure for version response
            struct VersionResponse: Decodable {
                let version: String?
            }
            
            let _: VersionResponse = try await SecureAPIClient.shared.secureRequest(url: url)
            return true
        } catch {
            return false
        }
    }
}

extension LiveFeedAPIClient {
    /// Secure version of stream URL testing
    func testStreamURLSecure(_ url: URL) async -> (accessible: Bool, contentType: String?, error: String?) {
        do {
            let _: Data = try await SecureAPIClient.shared.secureRequest(
                url: url.absoluteString,
                method: .GET
            )
            
            // Success case
            let accessible = true
            let contentType = "application/octet-stream"
            let error: String? = nil
            return (accessible, contentType, error)
            
        } catch let error as SecureAPIError {
            let accessible = false
            let contentType: String? = nil
            let errorMessage = error.localizedDescription
            return (accessible, contentType, errorMessage)
            
        } catch {
            let accessible = false
            let contentType: String? = nil
            let errorMessage = error.localizedDescription
            return (accessible, contentType, errorMessage)
        }
    }
}

// MARK: - Security Dashboard UI Component

struct SecurityDashboardView: View {
    @StateObject private var secureAPI = SecureAPIClient.shared
    @State private var showingAuditLog = false
    
    private var securityToggleBinding: Binding<Bool> {
        Binding(
            get: { secureAPI.isSecurityEnabled },
            set: { enabled in
                if enabled {
                    secureAPI.enableSecurity()
                } else {
                    secureAPI.disableSecurity()
                }
            }
        )
    }
    
    private var securityIconName: String {
        secureAPI.isSecurityEnabled ? "lock.shield.fill" : "lock.open.fill"
    }
    
    private var securityIconColor: Color {
        secureAPI.isSecurityEnabled ? .green : .red
    }
    
    private var securityStatusText: String {
        secureAPI.isSecurityEnabled ? "Enforced" : "Disabled"
    }
    
    private var bypassCountColor: Color {
        secureAPI.securityBypassCount > 0 ? .red : .green
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Security Status
            HStack {
                Image(systemName: securityIconName)
                    .foregroundColor(securityIconColor)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("API Security")
                        .font(.headline)
                    
                    Text(securityStatusText)
                        .font(.caption)
                        .foregroundColor(securityIconColor)
                }
                
                Spacer()
                
                Toggle("Enable", isOn: securityToggleBinding)
            }
            
            // Statistics
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Security Bypasses:")
                    Spacer()
                    Text("\(secureAPI.securityBypassCount)")
                        .foregroundColor(bypassCountColor)
                }
                
                HStack {
                    Text("Last Validation:")
                    Spacer()
                    if let lastValidation = secureAPI.lastSecurityValidation {
                        Text(lastValidation, style: .relative)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Never")
                            .foregroundColor(.red)
                    }
                }
            }
            .font(.subheadline)
            
            // Actions
            HStack {
                Button("View Audit Log") {
                    showingAuditLog = true
                }
                
                Spacer()
                
                Button("Clear Cache") {
                    secureAPI.clearValidationCache()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingAuditLog) {
            NavigationView {
                SecurityAuditLogView()
            }
        }
    }
}

struct SecurityAuditLogView: View {
    private let logs = SecureAPIClient.shared.getSecurityAuditLog()
    
    // Precompute reversed logs once
    private var reversedLogs: [String] {
        Array(logs.reversed())
    }
    
    var body: some View {
        List {
            ForEach(reversedLogs, id: \.self) { entry in
                Text(entry)
                    .font(.system(size: 12, design: .monospaced))
            }
        }
        .navigationTitle("Security Audit Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                shareButton
            }
        }
    }
    
    private var shareButton: some View {
        Button("Export") {
            exportSecurityReport()
        }
    }
    
    private func exportSecurityReport() {
        let report = SecureAPIClient.shared.exportSecurityReport()
        
        // Use iOS-compatible sharing
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [report],
            applicationActivities: nil
        )
        
        // Handle iPad presentation
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootViewController.present(activityVC, animated: true)
    }
}
