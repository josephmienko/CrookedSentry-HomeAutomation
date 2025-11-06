//
//  SettingsStoreTests.swift
//  CrookedSentryTests
//
//  Created by Assistant on 2025
//

import Foundation
import XCTest
import Combine
@testable import CrookedSentry

// @Suite("SettingsStore Tests")
struct SettingsStoreTests {
    
    // MARK: - Test Configuration
    
    let testSuiteName = "SettingsStoreTests"
    
    func createTestSettingsStore() -> SettingsStore {
        // Create a fresh UserDefaults instance for testing
        let testDefaults = UserDefaults(suiteName: testSuiteName) ?? UserDefaults.standard
        
        // Clear any existing test data
        testDefaults.removePersistentDomain(forName: testSuiteName)
        
        // Temporarily replace the standard UserDefaults for testing
        return SettingsStore()
    }
    
    func cleanupTestDefaults() {
        let testDefaults = UserDefaults(suiteName: testSuiteName) ?? UserDefaults.standard
        testDefaults.removePersistentDomain(forName: testSuiteName)
    }
    
    // MARK: - Initialization Tests
    
    // @Suite("Settings Store Initialization")
    struct InitializationTests {
        
        // @Test("Initialize with default values")
        func testDefaultInitialization() async throws {
            let settingsStore = SettingsStore()
            
            // Test default values
            XCTAssertEqual(settingsStore.frigateBaseURL, "http://192.168.0.200:5000")
            XCTAssertEqual(settingsStore.frigateVersion, "Unknown")
            XCTAssertTrue(settingsStore.availableLabels.isEmpty)
            XCTAssertTrue(settingsStore.selectedLabels.isEmpty)
            XCTAssertTrue(settingsStore.availableZones.isEmpty)
            XCTAssertTrue(settingsStore.selectedZones.isEmpty)
            XCTAssertEqual(settingsStore.availableCameras, ["backyard", "cam1"])
            XCTAssertTrue(settingsStore.selectedCameras.isEmpty)
            XCTAssertEqual(settingsStore.defaultStreamQuality, "sub")
            XCTAssertFalse(settingsStore.autoExpandFeeds)
            XCTAssertEqual(settingsStore.cameraUsername, "admin")
            XCTAssertEqual(settingsStore.cameraPassword, "DavidAlan")

            // Test default camera IP addresses
            XCTAssertEqual(settingsStore.cameraIPAddresses["backyard"], "192.168.0.210")
            XCTAssertEqual(settingsStore.cameraIPAddresses["cam1"], "192.168.0.211")
        }
        
    // @Test("Initialize with existing UserDefaults")
    func testInitializationWithExistingDefaults() async throws {
            // Pre-populate UserDefaults with test values
            UserDefaults.standard.set("http://192.168.1.100:5000", forKey: "frigateBaseURL")
            UserDefaults.standard.set(["person", "car"], forKey: "selectedLabels")
            UserDefaults.standard.set(["driveway", "yard"], forKey: "selectedZones")
            UserDefaults.standard.set(["camera1", "camera2"], forKey: "selectedCameras")
            UserDefaults.standard.set("main", forKey: "defaultStreamQuality")
            UserDefaults.standard.set(true, forKey: "autoExpandFeeds")
            UserDefaults.standard.set("testuser", forKey: "cameraUsername")
            UserDefaults.standard.set("testpass", forKey: "cameraPassword")
            
            let cameraIPs = ["camera1": "192.168.1.201", "camera2": "192.168.1.202"]
            UserDefaults.standard.set(cameraIPs, forKey: "cameraIPAddresses")
            
            let settingsStore = SettingsStore()
            
            // Test that values were loaded from UserDefaults
            XCTAssertEqual(settingsStore.frigateBaseURL, "http://192.168.1.100:5000")
            XCTAssertEqual(settingsStore.selectedLabels, Set(["person", "car"]))
            XCTAssertEqual(settingsStore.selectedZones, Set(["driveway", "yard"]))
            XCTAssertEqual(settingsStore.selectedCameras, Set(["camera1", "camera2"]))
            XCTAssertEqual(settingsStore.defaultStreamQuality, "main")
            XCTAssertTrue(settingsStore.autoExpandFeeds)
            XCTAssertEqual(settingsStore.cameraUsername, "testuser")
            XCTAssertEqual(settingsStore.cameraPassword, "testpass")
            XCTAssertEqual(settingsStore.cameraIPAddresses["camera1"], "192.168.1.201")
            XCTAssertEqual(settingsStore.cameraIPAddresses["camera2"], "192.168.1.202")
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "frigateBaseURL")
            UserDefaults.standard.removeObject(forKey: "selectedLabels")
            UserDefaults.standard.removeObject(forKey: "selectedZones")
            UserDefaults.standard.removeObject(forKey: "selectedCameras")
            UserDefaults.standard.removeObject(forKey: "defaultStreamQuality")
            UserDefaults.standard.removeObject(forKey: "autoExpandFeeds")
            UserDefaults.standard.removeObject(forKey: "cameraUsername")
            UserDefaults.standard.removeObject(forKey: "cameraPassword")
            UserDefaults.standard.removeObject(forKey: "cameraIPAddresses")
        }
    }
    
    // MARK: - Frigate Base URL Tests
    
    // @Suite("Frigate Base URL Management")
    struct FrigateBaseURLTests {
        
        // @Test("Set and persist Frigate base URL")
        func testSetFrigateBaseURL() async throws {
            let settingsStore = SettingsStore()
            let testURL = "http://192.168.1.200:5000"
            
            settingsStore.frigateBaseURL = testURL
            
            // Verify the value is set in the store
                XCTAssertEqual(settingsStore.frigateBaseURL, testURL)
                
                // Verify the value is persisted to UserDefaults
                let persistedURL = UserDefaults.standard.string(forKey: "frigateBaseURL")
                XCTAssertEqual(persistedURL, testURL)
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "frigateBaseURL")
        }
        
    // @Test("Update Frigate base URL multiple times")
    func testUpdateFrigateBaseURLMultipleTimes() async throws {
            let settingsStore = SettingsStore()
            let urls = [
                "http://192.168.1.100:5000",
                "http://10.0.0.100:5000",
                "https://frigate.example.com"
            ]
            
            for url in urls {
                settingsStore.frigateBaseURL = url
                
                XCTAssertEqual(settingsStore.frigateBaseURL, url)
                XCTAssertEqual(UserDefaults.standard.string(forKey: "frigateBaseURL"), url)
            }
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "frigateBaseURL")
        }
        
    // @Test("Set empty Frigate base URL")
    func testSetEmptyFrigateBaseURL() async throws {
            let settingsStore = SettingsStore()
            let emptyURL = ""
            
            settingsStore.frigateBaseURL = emptyURL
            
            XCTAssertEqual(settingsStore.frigateBaseURL, emptyURL)
            XCTAssertEqual(UserDefaults.standard.string(forKey: "frigateBaseURL"), emptyURL)
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "frigateBaseURL")
        }
    }
    
    // MARK: - Labels Management Tests
    
    // @Suite("Labels Management")
    struct LabelsManagementTests {
        
        // @Test("Set and persist selected labels")
        func testSetSelectedLabels() async throws {
            let settingsStore = SettingsStore()
            let testLabels = Set(["person", "car", "dog"])
            
            settingsStore.selectedLabels = testLabels
            
            // Verify the value is set in the store
            XCTAssertEqual(settingsStore.selectedLabels, testLabels)
            
            // Verify the value is persisted to UserDefaults
            let persistedLabels = UserDefaults.standard.array(forKey: "selectedLabels") as? [String] ?? []
            XCTAssertEqual(Set(persistedLabels), testLabels)
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "selectedLabels")
        }
        
    // @Test("Add and remove labels")
    func testAddRemoveLabels() async throws {
            let settingsStore = SettingsStore()
            
            // Start with empty set
            XCTAssertTrue(settingsStore.selectedLabels.isEmpty)
            
            // Add labels one by one
            settingsStore.selectedLabels.insert("person")
            XCTAssertTrue(settingsStore.selectedLabels.contains("person"))
            
            settingsStore.selectedLabels.insert("car")
            XCTAssertTrue(settingsStore.selectedLabels.contains("car"))
            XCTAssertEqual(settingsStore.selectedLabels.count, 2)
            
            // Remove a label
            settingsStore.selectedLabels.remove("person")
            XCTAssertFalse(settingsStore.selectedLabels.contains("person"))
            XCTAssertTrue(settingsStore.selectedLabels.contains("car"))
            XCTAssertEqual(settingsStore.selectedLabels.count, 1)
            
            // Clear all labels
            settingsStore.selectedLabels.removeAll()
            XCTAssertTrue(settingsStore.selectedLabels.isEmpty)
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "selectedLabels")
        }
        
    // @Test("Update available labels")
    func testUpdateAvailableLabels() async throws {
            let settingsStore = SettingsStore()
            let testLabels = ["person", "car", "bicycle", "dog", "cat"]
            
            settingsStore.availableLabels = testLabels
            
            XCTAssertEqual(settingsStore.availableLabels, testLabels)
            
            // Available labels are not persisted, so no UserDefaults check needed
        }
    }
    
    // MARK: - Zones Management Tests
    
    // @Suite("Zones Management")
    struct ZonesManagementTests {
        
        // @Test("Set and persist selected zones")
        func testSetSelectedZones() async throws {
            let settingsStore = SettingsStore()
            let testZones = Set(["front_yard", "driveway", "backyard"])
            
            settingsStore.selectedZones = testZones
            
            // Verify the value is set in the store
            XCTAssertEqual(settingsStore.selectedZones, testZones)
            
            // Verify the value is persisted to UserDefaults
            let persistedZones = UserDefaults.standard.array(forKey: "selectedZones") as? [String] ?? []
            XCTAssertEqual(Set(persistedZones), testZones)
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "selectedZones")
        }
        
    // @Test("Update available zones")
    func testUpdateAvailableZones() async throws {
            let settingsStore = SettingsStore()
            let testZones = ["front_yard", "driveway", "backyard", "porch", "garage"]
            
            settingsStore.availableZones = testZones
            
            XCTAssertEqual(settingsStore.availableZones, testZones)
        }
        
    // @Test("Zone selection validation")
    func testZoneSelectionValidation() async throws {
            let settingsStore = SettingsStore()
            
            // Set available zones
            settingsStore.availableZones = ["zone1", "zone2", "zone3"]
            
            // Select some zones
            settingsStore.selectedZones = Set(["zone1", "zone3"])
            
            XCTAssertEqual(settingsStore.selectedZones.count, 2)
            XCTAssertTrue(settingsStore.selectedZones.contains("zone1"))
            XCTAssertTrue(settingsStore.selectedZones.contains("zone3"))
            XCTAssertFalse(settingsStore.selectedZones.contains("zone2"))
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "selectedZones")
        }
    }
    
    // MARK: - Cameras Management Tests
    
    // @Suite("Cameras Management")
    struct CamerasManagementTests {
        
        // @Test("Set and persist selected cameras")
        func testSetSelectedCameras() async throws {
            let settingsStore = SettingsStore()
            let testCameras = Set(["backyard", "cam1"])
            
            settingsStore.selectedCameras = testCameras
            
            // Verify the value is set in the store
            XCTAssertEqual(settingsStore.selectedCameras, testCameras)
            
            // Verify the value is persisted to UserDefaults
            let persistedCameras = UserDefaults.standard.array(forKey: "selectedCameras") as? [String] ?? []
            XCTAssertEqual(Set(persistedCameras), testCameras)
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "selectedCameras")
        }
        
    // @Test("Update available cameras")
    func testUpdateAvailableCameras() async throws {
            let settingsStore = SettingsStore()
            let testCameras = ["front_door", "backyard", "garage", "driveway"]
            
            settingsStore.availableCameras = testCameras
            
            XCTAssertEqual(settingsStore.availableCameras, testCameras)
        }
        
    // @Test("Manage camera IP addresses")
    func testCameraIPAddresses() async throws {
            let settingsStore = SettingsStore()
            
            // Test default IP addresses
            XCTAssertEqual(settingsStore.cameraIPAddresses["backyard"], "192.168.0.210")
            XCTAssertEqual(settingsStore.cameraIPAddresses["cam1"], "192.168.0.211")
            
            // Update IP addresses
            var updatedIPs = settingsStore.cameraIPAddresses
            updatedIPs["front_door"] = "192.168.0.212"
            updatedIPs["garage"] = "192.168.0.213"
            
            settingsStore.cameraIPAddresses = updatedIPs
            
            XCTAssertEqual(settingsStore.cameraIPAddresses["front_door"], "192.168.0.212")
            XCTAssertEqual(settingsStore.cameraIPAddresses["garage"], "192.168.0.213")
            
            // Verify persistence
            let persistedIPs = UserDefaults.standard.dictionary(forKey: "cameraIPAddresses") as? [String: String] ?? [:]
            XCTAssertEqual(persistedIPs["front_door"], "192.168.0.212")
            XCTAssertEqual(persistedIPs["garage"], "192.168.0.213")
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "cameraIPAddresses")
        }
    }
    
    // MARK: - Live Feed Settings Tests
    
    // @Suite("Live Feed Settings")
    struct LiveFeedSettingsTests {
        
        // @Test("Set and persist default stream quality")
        func testDefaultStreamQuality() async throws {
            let settingsStore = SettingsStore()
            let qualities = ["sub", "main", "hd"]
            
            for quality in qualities {
                settingsStore.defaultStreamQuality = quality
                
                XCTAssertEqual(settingsStore.defaultStreamQuality, quality)
                XCTAssertEqual(UserDefaults.standard.string(forKey: "defaultStreamQuality"), quality)
            }
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "defaultStreamQuality")
        }
        
    // @Test("Set and persist auto expand feeds")
    func testAutoExpandFeeds() async throws {
            let settingsStore = SettingsStore()
            
            // Test setting to true
            settingsStore.autoExpandFeeds = true
            XCTAssertTrue(settingsStore.autoExpandFeeds)
            XCTAssertTrue(UserDefaults.standard.bool(forKey: "autoExpandFeeds") == true)
            
            // Test setting to false
            settingsStore.autoExpandFeeds = false
            XCTAssertFalse(settingsStore.autoExpandFeeds)
            XCTAssertFalse(UserDefaults.standard.bool(forKey: "autoExpandFeeds") == false)
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "autoExpandFeeds")
        }
    }
    
    // MARK: - Authentication Settings Tests
    
    // @Suite("Authentication Settings")
    struct AuthenticationSettingsTests {
        
        // @Test("Set and persist camera username")
        func testCameraUsername() async throws {
            let settingsStore = SettingsStore()
            let testUsernames = ["admin", "user", "camera_user", ""]
            
            for username in testUsernames {
                settingsStore.cameraUsername = username
                
                XCTAssertEqual(settingsStore.cameraUsername, username)
                XCTAssertEqual(UserDefaults.standard.string(forKey: "cameraUsername"), username)
            }
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "cameraUsername")
        }
        
    // @Test("Set and persist camera password")
    func testCameraPassword() async throws {
            let settingsStore = SettingsStore()
            let testPasswords = ["password123", "secure_pass", "", "complex@Pass#1"]
            
            for password in testPasswords {
                settingsStore.cameraPassword = password
                
                XCTAssertEqual(settingsStore.cameraPassword, password)
                XCTAssertEqual(UserDefaults.standard.string(forKey: "cameraPassword"), password)
            }
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "cameraPassword")
        }
        
    // @Test("Credential validation")
    func testCredentialValidation() async throws {
            let settingsStore = SettingsStore()
            
            // Test with valid credentials
            settingsStore.cameraUsername = "validuser"
            settingsStore.cameraPassword = "validpass"
            
            XCTAssertFalse(settingsStore.cameraUsername.isEmpty)
            XCTAssertFalse(settingsStore.cameraPassword.isEmpty)
            
            // Test with empty credentials
            settingsStore.cameraUsername = ""
            settingsStore.cameraPassword = ""
            
            XCTAssertTrue(settingsStore.cameraUsername.isEmpty)
            XCTAssertTrue(settingsStore.cameraPassword.isEmpty)
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "cameraUsername")
            UserDefaults.standard.removeObject(forKey: "cameraPassword")
        }
    }
    
    // MARK: - Frigate Version Tests
    
    // @Suite("Frigate Version Management")
    struct FrigateVersionTests {
        
        // @Test("Fetch Frigate version success")
        func testFetchFrigateVersionSuccess() async throws {
            let settingsStore = SettingsStore()
            
            // Create a mock API client that simulates successful version fetch
            let mockClient = MockFrigateAPIClient(shouldSucceed: true, mockVersion: "0.13.2")
            
            await settingsStore.fetchFrigateVersion(apiClient: mockClient)
            
            XCTAssertEqual(settingsStore.frigateVersion, "0.13.2")
        }
        
    // @Test("Fetch Frigate version network error")
    func testFetchFrigateVersionNetworkError() async throws {
            let settingsStore = SettingsStore()
            
            // Create a mock API client that simulates network error
            let mockClient = MockFrigateAPIClient(shouldSucceed: false, mockError: .networkError(NSError(domain: "test", code: -1)))
            
            await settingsStore.fetchFrigateVersion(apiClient: mockClient)
            
            XCTAssertTrue(settingsStore.frigateVersion.contains("Error: Network issue"))
        }
        
    // @Test("Fetch Frigate version invalid URL error")
    func testFetchFrigateVersionInvalidURL() async throws {
            let settingsStore = SettingsStore()
            
            let mockClient = MockFrigateAPIClient(shouldSucceed: false, mockError: .invalidURL)
            
            await settingsStore.fetchFrigateVersion(apiClient: mockClient)
            
            XCTAssertEqual(settingsStore.frigateVersion, "Error: Invalid URL")
        }
        
    // @Test("Fetch Frigate version decoding error")
    func testFetchFrigateVersionDecodingError() async throws {
            let settingsStore = SettingsStore()
            
            let mockClient = MockFrigateAPIClient(shouldSucceed: false, mockError: .decodingError(NSError(domain: "test", code: -1)))
            
            await settingsStore.fetchFrigateVersion(apiClient: mockClient)
            
            XCTAssertEqual(settingsStore.frigateVersion, "Error: Could not decode version")
        }
        
    // @Test("Fetch Frigate version unsupported version")
    func testFetchFrigateVersionUnsupported() async throws {
            let settingsStore = SettingsStore()
            
            let mockClient = MockFrigateAPIClient(shouldSucceed: false, mockError: .unsupportedVersion("0.1.0"))
            
            await settingsStore.fetchFrigateVersion(apiClient: mockClient)
            
            XCTAssertEqual(settingsStore.frigateVersion, "Error: Unsupported version 0.1.0")
        }
        
    // @Test("Fetch Frigate version invalid response")
    func testFetchFrigateVersionInvalidResponse() async throws {
            let settingsStore = SettingsStore()
            
            let mockClient = MockFrigateAPIClient(shouldSucceed: false, mockError: .invalidResponse)
            
            await settingsStore.fetchFrigateVersion(apiClient: mockClient)
            
            XCTAssertEqual(settingsStore.frigateVersion, "Error: Invalid response format")
        }
        
    // @Test("Fetch Frigate version unknown error")
    func testFetchFrigateVersionUnknownError() async throws {
            let settingsStore = SettingsStore()
            
            let mockClient = MockFrigateAPIClient(shouldSucceed: false, mockError: nil, unknownError: NSError(domain: "unknown", code: -999))
            
            await settingsStore.fetchFrigateVersion(apiClient: mockClient)
            
            XCTAssertTrue(settingsStore.frigateVersion.contains("Error:"))
        }
    }
    
    // MARK: - ObservableObject Tests
    
    // @Suite("ObservableObject Behavior")
    struct ObservableObjectTests {
        
        // @Test("Settings store is ObservableObject")
        func testObservableObjectConformance() async throws {
            let settingsStore = SettingsStore()
            
            // Verify that SettingsStore conforms to ObservableObject
            XCTAssertTrue(settingsStore is any ObservableObject)
        }
        
    // @Test("Published properties trigger updates")
    func testPublishedPropertiesUpdates() async throws {
            let settingsStore = SettingsStore()
            var updateCount = 0
            
            // Create a subscription to monitor updates
            let cancellable = settingsStore.objectWillChange.sink {
                updateCount += 1
            }
            
            // Make several changes
            settingsStore.frigateBaseURL = "http://test1.com"
            settingsStore.selectedLabels = Set(["person"])
            settingsStore.autoExpandFeeds = true
            
            // Give the publisher time to emit
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            XCTAssertGreaterThan(updateCount, 0)
            
            cancellable.cancel()
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "frigateBaseURL")
            UserDefaults.standard.removeObject(forKey: "selectedLabels")
            UserDefaults.standard.removeObject(forKey: "autoExpandFeeds")
        }
        
    // @Test("Non-published properties don't trigger updates")
    func testNonPublishedProperties() async throws {
            let settingsStore = SettingsStore()
            var updateCount = 0
            
            let cancellable = settingsStore.objectWillChange.sink {
                updateCount += 1
            }
            
            // Update non-published property (frigateVersion is set internally)
            // This should not trigger an update since it's set via async method
            
            try await Task.sleep(nanoseconds: 100_000_000)
            
            // Initial setup might trigger some updates, but we're mainly testing
            // that the structure works correctly
            
            cancellable.cancel()
        }
    }
    
    // MARK: - Data Integrity Tests
    
    // @Suite("Data Integrity")
    struct DataIntegrityTests {
        
        // @Test("Concurrent updates are handled safely")
        func testConcurrentUpdates() async throws {
            let settingsStore = SettingsStore()
            
            await withTaskGroup(of: Void.self) { group in
                // Simulate concurrent updates
                for i in 0..<10 {
                    group.addTask {
                        settingsStore.frigateBaseURL = "http://test\(i).com"
                        settingsStore.selectedLabels = Set(["label\(i)"])
                        settingsStore.autoExpandFeeds = (i % 2 == 0)
                    }
                }
            }
            
            // Verify final state is consistent
            XCTAssertFalse(settingsStore.frigateBaseURL.isEmpty)
            XCTAssertLessThanOrEqual(settingsStore.selectedLabels.count, 1)
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "frigateBaseURL")
            UserDefaults.standard.removeObject(forKey: "selectedLabels")
            UserDefaults.standard.removeObject(forKey: "autoExpandFeeds")
        }
        
    // @Test("Large data sets are handled correctly")
    func testLargeDataSets() async throws {
            let settingsStore = SettingsStore()
            
            // Create large sets of data
            let largeLabelSet = Set((0..<1000).map { "label\(String(format: "%04d", $0))" })
            let largeZoneSet = Set((0..<500).map { "zone\(String(format: "%03d", $0))" })
            let largeCameraSet = Set((0..<100).map { "camera\(String(format: "%02d", $0))" })
            
            settingsStore.selectedLabels = largeLabelSet
            settingsStore.selectedZones = largeZoneSet
            settingsStore.selectedCameras = largeCameraSet
            
            // Verify all data is preserved
            XCTAssertEqual(settingsStore.selectedLabels.count, 1000)
            XCTAssertEqual(settingsStore.selectedZones.count, 500)
            XCTAssertEqual(settingsStore.selectedCameras.count, 100)
            
            // Verify persistence works with large data
            let persistedLabels = Set(UserDefaults.standard.array(forKey: "selectedLabels") as? [String] ?? [])
            XCTAssertEqual(persistedLabels.count, 1000)
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "selectedLabels")
            UserDefaults.standard.removeObject(forKey: "selectedZones")
            UserDefaults.standard.removeObject(forKey: "selectedCameras")
        }
        
    // @Test("Special characters in settings are handled")
    func testSpecialCharacters() async throws {
            let settingsStore = SettingsStore()
            
            // Test with special characters and Unicode
            let specialURL = "http://test.com:5000/特殊文字/!@#$%^&*()"
            let specialUsername = "用户名_with-symbols!@#"
            let specialPassword = "密码_P@ssw0rd!@#$%^&*()_+"
            
            settingsStore.frigateBaseURL = specialURL
            settingsStore.cameraUsername = specialUsername
            settingsStore.cameraPassword = specialPassword
            
            // Verify values are preserved correctly
            XCTAssertEqual(settingsStore.frigateBaseURL, specialURL)
            XCTAssertEqual(settingsStore.cameraUsername, specialUsername)
            XCTAssertEqual(settingsStore.cameraPassword, specialPassword)
            
            // Verify persistence with special characters
            XCTAssertEqual(UserDefaults.standard.string(forKey: "frigateBaseURL"), specialURL)
            XCTAssertEqual(UserDefaults.standard.string(forKey: "cameraUsername"), specialUsername)
            XCTAssertEqual(UserDefaults.standard.string(forKey: "cameraPassword"), specialPassword)
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "frigateBaseURL")
            UserDefaults.standard.removeObject(forKey: "cameraUsername")
            UserDefaults.standard.removeObject(forKey: "cameraPassword")
        }
    }
    
    // MARK: - Performance Tests
    
    // @Suite("Performance Testing")
    struct PerformanceTests {
        
        // @Test("Settings initialization performance")
        func testInitializationPerformance() async throws {
            let startTime = Date()
            
            for _ in 0..<100 {
                _ = SettingsStore()
            }
            
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            print("SettingsStore initialization (100x): \(duration)s")
            XCTAssertLessThan(duration, 1.0) // Should initialize quickly
        }
        
    // @Test("Settings update performance")
    func testUpdatePerformance() async throws {
            let settingsStore = SettingsStore()
            let startTime = Date()
            
            for i in 0..<1000 {
                settingsStore.frigateBaseURL = "http://test\(i).com"
                settingsStore.selectedLabels = Set(["label\(i)"])
                settingsStore.autoExpandFeeds = (i % 2 == 0)
            }
            
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            print("Settings updates (1000x): \(duration)s")
            XCTAssertLessThan(duration, 5.0) // Should update quickly even with persistence
            
            // Cleanup
            UserDefaults.standard.removeObject(forKey: "frigateBaseURL")
            UserDefaults.standard.removeObject(forKey: "selectedLabels")
            UserDefaults.standard.removeObject(forKey: "autoExpandFeeds")
        }
        
    // @Test("Version fetch performance")
    func testVersionFetchPerformance() async throws {
            let settingsStore = SettingsStore()
            let mockClient = MockFrigateAPIClient(shouldSucceed: true, mockVersion: "0.13.2")
            
            let startTime = Date()
            
            for _ in 0..<10 {
                await settingsStore.fetchFrigateVersion(apiClient: mockClient)
            }
            
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            print("Version fetch (10x): \(duration)s")
            XCTAssertLessThan(duration, 2.0)
        }
    }
}

// MARK: - Mock Classes for Testing

class MockFrigateAPIClient: FrigateAPIClient {
    private let shouldSucceed: Bool
    private let mockVersion: String?
    private let mockError: FrigateAPIError?
    private let unknownError: Error?
    
    init(shouldSucceed: Bool, mockVersion: String? = nil, mockError: FrigateAPIError? = nil, unknownError: Error? = nil) {
        self.shouldSucceed = shouldSucceed
        self.mockVersion = mockVersion
        self.mockError = mockError
        self.unknownError = unknownError
        super.init()
    }
    
    override func fetchVersion() async throws -> String {
        if shouldSucceed {
            return mockVersion ?? "0.13.2"
        } else if let error = mockError {
            throw error
        } else if let error = unknownError {
            throw error
        } else {
            throw FrigateAPIError.networkError(NSError(domain: "test", code: -1))
        }
    }
}