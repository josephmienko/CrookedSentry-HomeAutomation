//
//  CrookedKeysConfig.swift
//  CrookedSentry
//
//  CrookedKeys VPN Service Configuration
//  Created by Assistant on 2025
//

import Foundation

struct CrookedKeysConfig {
    // MARK: - Environment Configuration
    
    /// Environment-specific configuration for CrookedKeys endpoints
    enum Environment: String, CaseIterable {
        case production = "production"
        case development = "development"
        
        var displayName: String {
            switch self {
            case .production:
                return "Production"
            case .development:
                return "Development"
            }
        }
    }
    
    // MARK: - Current Configuration
    
    static var currentEnvironment: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    // MARK: - Endpoint Configuration
    
    struct Endpoints {
        let baseURL: String
        let httpsBaseURL: String
        let vpnOnboardingPath: String
        let healthPath: String
        let apiPath: String
        
        var onboardingURL: String {
            return "\(httpsBaseURL)\(vpnOnboardingPath)"
        }
        
        var healthURL: String {
            return "\(baseURL)\(healthPath)"
        }
        
        var apiURL: String {
            return "\(baseURL)\(apiPath)"
        }
        
        var apiHealthURL: String {
            return "\(apiURL)/health"
        }
    }
    
    // MARK: - Environment-Specific Endpoints
    
    static var current: Endpoints {
        switch currentEnvironment {
        case .production:
            return Endpoints(
                baseURL: "http://73.35.176.251",
                httpsBaseURL: "https://cameras.crookedsentry.net",
                vpnOnboardingPath: "/vpn",
                healthPath: "/api/crooked-keys/health",
                apiPath: "/api/crooked-keys"
            )
        case .development:
            return Endpoints(
                baseURL: "http://73.35.176.251",  // Same for now
                httpsBaseURL: "https://cameras.crookedsentry.net",
                vpnOnboardingPath: "/vpn",
                healthPath: "/api/crooked-keys/health",
                apiPath: "/api/crooked-keys"
            )
        }
    }
    
    // MARK: - Configuration Override
    
    /// Override endpoints from app settings or configuration file
    static func configure(customBaseURL: String? = nil, customHTTPSURL: String? = nil) {
        // TODO: Implement custom endpoint override logic
        // This could read from UserDefaults, plist, or environment variables
        
        if let customBaseURL = customBaseURL {
            UserDefaults.standard.set(customBaseURL, forKey: "CrookedKeysCustomBaseURL")
        }
        
        if let customHTTPSURL = customHTTPSURL {
            UserDefaults.standard.set(customHTTPSURL, forKey: "CrookedKeysCustomHTTPSURL")
        }
    }
    
    /// Get custom endpoints if configured, otherwise return defaults
    static var configured: Endpoints {
        var endpoints = current
        
        // Override with custom URLs if set
        if let customBaseURL = UserDefaults.standard.string(forKey: "CrookedKeysCustomBaseURL") {
            endpoints = Endpoints(
                baseURL: customBaseURL,
                httpsBaseURL: endpoints.httpsBaseURL,
                vpnOnboardingPath: endpoints.vpnOnboardingPath,
                healthPath: endpoints.healthPath,
                apiPath: endpoints.apiPath
            )
        }
        
        if let customHTTPSURL = UserDefaults.standard.string(forKey: "CrookedKeysCustomHTTPSURL") {
            endpoints = Endpoints(
                baseURL: endpoints.baseURL,
                httpsBaseURL: customHTTPSURL,
                vpnOnboardingPath: endpoints.vpnOnboardingPath,
                healthPath: endpoints.healthPath,
                apiPath: endpoints.apiPath
            )
        }
        
        return endpoints
    }
}

// MARK: - Service Configuration

extension CrookedKeysConfig {
    /// Service-specific configuration
    struct ServiceConfig {
        static let rateLimitRetryDelay: TimeInterval = 60  // 1 minute
        static let healthCheckInterval: TimeInterval = 300  // 5 minutes
        static let requestTimeout: TimeInterval = 30  // 30 seconds
        static let maxRetryAttempts = 3
        
        /// Network security configuration
        static let allowInsecureConnections = false  // Always require HTTPS for production
        static let validateSSLCertificates = true
        
        /// Feature flags for CrookedKeys integration
        static let enableHealthMonitoring = true
        static let enableAutoOnboarding = true
        static let enableQRCodeSetup = true
        static let enableBackgroundRefresh = false  // Disabled for battery life
    }
}

// MARK: - Convenience Extensions

extension VPNManager {
    /// Updated endpoints using the new configuration system
    struct CrookedKeysEndpoints {
        static var baseURL: String {
            CrookedKeysConfig.configured.baseURL
        }
        
        static var httpsBaseURL: String {
            CrookedKeysConfig.configured.httpsBaseURL
        }
        
        static var onboardingURL: String {
            CrookedKeysConfig.configured.onboardingURL
        }
        
        static var healthURL: String {
            CrookedKeysConfig.configured.healthURL
        }
        
        static var apiURL: String {
            CrookedKeysConfig.configured.apiURL
        }
    }
}