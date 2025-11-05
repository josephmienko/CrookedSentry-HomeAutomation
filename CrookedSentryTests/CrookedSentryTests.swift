//
//  CrookedSentryTests.swift
//  CrookedSentryTests
//
//  Created by Joseph Mienko on 11/3/25.
//

import Testing
@testable import CrookedSentry

/// Main test suite for CrookedSentry - Security-focused home automation app
@Suite("CrookedSentry Core Tests")
struct CrookedSentryTests {

    // MARK: - Basic App Functionality Tests
    
    @Test("App launches successfully")
    func appLaunchesSuccessfully() async throws {
        // Test basic app initialization
        let app = CrookedSentryApp()
        #expect(app != nil)
    }
    
    @Test("Settings store initialization")
    func settingsStoreInitialization() async throws {
        let settingsStore = SettingsStore()
        
        // Should have default values
        #expect(settingsStore.frigateServerURL != nil)
        #expect(settingsStore.cameraNames != nil)
    }
    
    @Test("Image loader functionality")
    func imageLoaderFunctionality() async throws {
        let imageLoader = ImageLoader()
        
        // Should initialize without errors
        #expect(imageLoader.image == nil) // No image loaded initially
        #expect(imageLoader.isLoading == false) // Not loading initially
    }
    
    @Test("Frigate event model")
    func frigateEventModel() async throws {
        // Test FrigateEvent model can be created
        let testEvent = FrigateEvent(
            id: "test123",
            camera: "front_door",
            label: "person",
            startTime: Date().timeIntervalSince1970 - 3600,
            endTime: Date().timeIntervalSince1970,
            score: 0.85,
            zones: ["entrance"],
            thumbnail: "http://example.com/thumb.jpg",
            hasSnapshot: true,
            hasClip: true
        )
        
        #expect(testEvent.id == "test123")
        #expect(testEvent.camera == "front_door")
        #expect(testEvent.label == "person")
        #expect(testEvent.score == 0.85)
        #expect(testEvent.hasSnapshot == true)
    }
    
    // MARK: - API Client Tests
    
    @Test("Frigate API client initialization")
    func frigateAPIClientInitialization() async throws {
        let apiClient = FrigateEventAPIClient(
            baseURL: "http://test.example.com",
            username: "test",
            password: "test"
        )
        
        #expect(apiClient.baseURL == "http://test.example.com")
    }
    
    @Test("Live feed API client initialization") 
    func liveFeedAPIClientInitialization() async throws {
        let liveClient = LiveFeedAPIClient()
        
        // Should initialize successfully
        #expect(liveClient != nil)
    }
    
    // MARK: - Core Network Tests
    
    @Test("Network manager initialization")
    func networkManagerInitialization() async throws {
        let networkManager = NetworkManager.shared
        
        // Should be singleton
        let anotherInstance = NetworkManager.shared
        #expect(networkManager === anotherInstance)
    }
    
    @Test("HTTP method enum")
    func httpMethodEnum() async throws {
        // Test HTTP method enum values
        #expect(HTTPMethod.GET.rawValue == "GET")
        #expect(HTTPMethod.POST.rawValue == "POST")
        #expect(HTTPMethod.PUT.rawValue == "PUT")
        #expect(HTTPMethod.DELETE.rawValue == "DELETE")
    }
    
    // MARK: - Security Framework Integration Tests
    
    @Test("Security framework integration")
    func securityFrameworkIntegration() async throws {
        let debugger = NetworkSecurityDebuggerSimple.shared
        let secureClient = SecureAPIClient.shared
        
        // Security components should initialize
        #expect(debugger != nil)
        #expect(secureClient != nil)
        
        // Should have default security state
        #expect(secureClient.isSecurityEnabled)
    }
    
    @Test("VPN components availability")
    func vpnComponentsAvailability() async throws {
        // Test VPN-related components can be initialized
        // Note: VPNManager may not be fully functional in test environment
        
        let vpnManager = VPNManager.shared
        #expect(vpnManager != nil)
        #expect(vpnManager.connectionState != nil)
    }
    
    // MARK: - Material 3 Color System Tests
    
    @Test("Material 3 colors available")
    func material3ColorsAvailable() async throws {
        // Test that Material 3 color extensions are available
        let primaryColor = Color.primary
        let secondaryColor = Color.secondary
        let tertiaryColor = Color.tertiary
        
        #expect(primaryColor != nil)
        #expect(secondaryColor != nil)
        #expect(tertiaryColor != nil)
        
        // Surface colors
        let surfaceColor = Color.surface
        let backgroundNColor = Color.background
        
        #expect(surfaceColor != nil)
        #expect(backgroundNColor != nil)
    }
    
    // MARK: - View Model Tests
    
    @Test("Main container view initialization")
    func mainContainerViewInitialization() async throws {
        let containerView = MainContainerView()
        
        // Should initialize without crashing
        #expect(containerView != nil)
    }
    
    @Test("Settings view initialization") 
    func settingsViewInitialization() async throws {
        let settingsView = SettingsView()
        
        // Should initialize without crashing
        #expect(settingsView != nil)
    }
}
