//
//  CameraFeedLoadingTests.swift
//  CrookedSentryTests
//
//  Created by Assistant on 2025
//

import Foundation
import Testing
import SwiftUI
import AVFoundation
import Combine
@testable import CrookedSentry

@Suite("Camera Feed Loading Tests")
struct CameraFeedLoadingTests {
    
    // MARK: - Test Configuration
    
    let testBaseURL = "http://192.168.1.100:5000"
    let testCamera = "test_camera"
    
    func createMockLiveFeedAPIClient() -> LiveFeedAPIClient {
        return LiveFeedAPIClient(baseURL: testBaseURL)
    }
    
    func createMockSettingsStore() -> SettingsStore {
        let store = SettingsStore()
        store.cameraUsername = "testuser"
        store.cameraPassword = "testpass"
        store.defaultStreamQuality = "sub"
        store.autoExpandFeeds = false
        return store
    }
    
    // MARK: - LiveFeedAPIClient Tests
    
    @Suite("LiveFeedAPIClient Functionality")
    struct LiveFeedAPIClientTests {
        
        @Test("Initialize with base URL")
        func testInitialization() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            #expect(client.baseURL == testBaseURL)
            #expect(client.cameraUsername == "admin") // Default value
            #expect(client.cameraPassword == "DavidAlan") // Default value
        }
        
        @Test("Update credentials")
        func testUpdateCredentials() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            let newUsername = "newuser"
            let newPassword = "newpass"
            
            client.updateCredentials(username: newUsername, password: newPassword)
            
            #expect(client.cameraUsername == newUsername)
            #expect(client.cameraPassword == newPassword)
        }
        
        @Test("Get live stream URL for main quality")
        func testGetLiveStreamURLMain() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            
            let url = client.getLiveStreamURL(for: testCamera, quality: .main)
            
            #expect(url != nil)
            #expect(url?.absoluteString.contains("stream.m3u8") == true)
            #expect(url?.absoluteString.contains(testCamera) == true)
        }
        
        @Test("Get live stream URL for sub quality")
        func testGetLiveStreamURLSub() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            
            let url = client.getLiveStreamURL(for: testCamera, quality: .sub)
            
            #expect(url != nil)
            #expect(url?.absoluteString.contains("stream.m3u8") == true)
            #expect(url?.absoluteString.contains("\(testCamera)_sub") == true)
        }
        
        @Test("Get live stream URL for WebRTC quality")
        func testGetLiveStreamURLWebRTC() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            
            let url = client.getLiveStreamURL(for: testCamera, quality: .webrtc)
            
            #expect(url != nil)
            #expect(url?.absoluteString.contains("mode=mjpeg") == true)
            #expect(url?.absoluteString.contains(testCamera) == true)
        }
        
        @Test("Get live stream URL for MJPEG quality")
        func testGetLiveStreamURLMJPEG() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            
            let url = client.getLiveStreamURL(for: testCamera, quality: .mjpeg)
            
            #expect(url != nil)
            #expect(url?.absoluteString.contains("mode=mjpeg") == true)
            #expect(url?.absoluteString.contains(testCamera) == true)
        }
        
        @Test("Get alternative stream URLs")
        func testGetAlternativeStreamURLs() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            
            let urls = client.getAlternativeStreamURLs(for: testCamera)
            
            #expect(!urls.isEmpty)
            #expect(urls.count >= 3) // Should have multiple alternatives
            
            // Check that each URL contains the camera name
            for url in urls {
                #expect(url.absoluteString.contains(testCamera))
            }
        }
        
        @Test("Get snapshot URL")
        func testGetSnapshotURL() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            
            let url = client.getSnapshotURL(for: testCamera)
            
            #expect(url != nil)
            #expect(url?.absoluteString.contains("latest.jpg") == true)
            #expect(url?.absoluteString.contains(testCamera) == true)
            #expect(url?.absoluteString.contains("t=") == true) // Timestamp parameter
        }
        
        @Test("Get alternative snapshot URLs")
        func testGetAlternativeSnapshotURLs() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            
            let urls = client.getAlternativeSnapshotURLs(for: testCamera)
            
            #expect(!urls.isEmpty)
            #expect(urls.count >= 2) // Should have multiple alternatives
            
            // Check that each URL contains latest.jpg and camera name
            for url in urls {
                #expect(url.absoluteString.contains("latest.jpg"))
                #expect(url.absoluteString.contains(testCamera) || url.absoluteString.contains("snapshot"))
            }
        }
        
        @Test("Test stream URL accessibility - valid URL")
        func testStreamURLAccessibilityValid() async throws {
            let client = LiveFeedAPIClient(baseURL: "http://httpbin.org")
            let testURL = URL(string: "http://httpbin.org/status/200")!
            
            let result = await client.testStreamURL(testURL)
            
            #expect(result.accessible == true)
            #expect(result.error == nil)
        }
        
        @Test("Test stream URL accessibility - invalid URL")
        func testStreamURLAccessibilityInvalid() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            let testURL = URL(string: "http://192.168.255.255:5000/invalid")!
            
            let result = await client.testStreamURL(testURL)
            
            #expect(result.accessible == false)
            #expect(result.error != nil)
        }
        
        @Test("Test stream URL accessibility - HTTP error")
        func testStreamURLAccessibilityHTTPError() async throws {
            let client = LiveFeedAPIClient(baseURL: "http://httpbin.org")
            let testURL = URL(string: "http://httpbin.org/status/404")!
            
            let result = await client.testStreamURL(testURL)
            
            #expect(result.accessible == false)
            #expect(result.contentType != nil) // Should still get response headers
        }
        
        @Test("Diagnose streaming endpoints")
        func testDiagnoseStreamingEndpoints() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            
            let results = await client.diagnoseStreamingEndpoints(for: testCamera)
            
            #expect(!results.isEmpty)
            #expect(results.count >= 5) // Should test multiple endpoints
            
            // Each result should have URL and status
            for result in results {
                #expect(!result.url.isEmpty)
                #expect(result.url.contains(testCamera) || result.url.contains("latest.jpg"))
            }
        }
        
        @Test("Fetch available cameras - network error")
        func testFetchAvailableCamerasNetworkError() async throws {
            let client = LiveFeedAPIClient(baseURL: "http://192.168.255.255:5000")
            
            do {
                _ = try await client.fetchAvailableCameras()
                throw TestError.unexpectedSuccess
            } catch {
                // Expected network error
                print("Expected network error: \(error)")
            }
        }
        
        @Test("Fetch available cameras - invalid response")
        func testFetchAvailableCamerasInvalidResponse() async throws {
            let client = LiveFeedAPIClient(baseURL: "http://httpbin.org")
            
            do {
                let cameras = try await client.fetchAvailableCameras()
                // httpbin.org won't return Frigate config format
                print("Received cameras (likely empty): \(cameras)")
            } catch {
                // Expected decoding/parsing error
                print("Expected parsing error: \(error)")
            }
        }
    }
    
    // MARK: - StreamQuality Tests
    
    @Suite("StreamQuality Enum")
    struct StreamQualityTests {
        
        @Test("All stream quality cases exist")
        func testStreamQualityCases() async throws {
            let allCases = StreamQuality.allCases
            
            #expect(allCases.contains(.main))
            #expect(allCases.contains(.sub))
            #expect(allCases.contains(.webrtc))
            #expect(allCases.contains(.mjpeg))
            #expect(allCases.count == 4)
        }
        
        @Test("Stream quality display names")
        func testStreamQualityDisplayNames() async throws {
            #expect(StreamQuality.main.displayName == "High Quality")
            #expect(StreamQuality.sub.displayName == "Low Quality")
            #expect(StreamQuality.webrtc.displayName == "WebRTC")
            #expect(StreamQuality.mjpeg.displayName == "MJPEG")
        }
        
        @Test("Stream quality descriptions")
        func testStreamQualityDescriptions() async throws {
            #expect(!StreamQuality.main.description.isEmpty)
            #expect(!StreamQuality.sub.description.isEmpty)
            #expect(!StreamQuality.webrtc.description.isEmpty)
            #expect(!StreamQuality.mjpeg.description.isEmpty)
        }
        
        @Test("Stream quality raw values")
        func testStreamQualityRawValues() async throws {
            #expect(StreamQuality.main.rawValue == "main")
            #expect(StreamQuality.sub.rawValue == "sub")
            #expect(StreamQuality.webrtc.rawValue == "webrtc")
            #expect(StreamQuality.mjpeg.rawValue == "mjpeg")
        }
        
        @Test("Stream quality initialization from raw value")
        func testStreamQualityInitFromRawValue() async throws {
            #expect(StreamQuality(rawValue: "main") == .main)
            #expect(StreamQuality(rawValue: "sub") == .sub)
            #expect(StreamQuality(rawValue: "webrtc") == .webrtc)
            #expect(StreamQuality(rawValue: "mjpeg") == .mjpeg)
            #expect(StreamQuality(rawValue: "invalid") == nil)
        }
    }
    
    // MARK: - RemoteImage Tests
    
    @Suite("RemoteImage Component")
    struct RemoteImageTests {
        
        @Test("RemoteImage initialization")
        func testRemoteImageInitialization() async throws {
            let testURL = URL(string: "http://httpbin.org/image/png")!
            
            let remoteImage = RemoteImage(url: testURL) {
                Text("Loading...")
            } content: { image in
                image.resizable()
            }
            
            // Basic initialization test - structure should be valid
            #expect(remoteImage.url == testURL)
        }
        
        @Test("RemoteImage with invalid URL structure")
        func testRemoteImageInvalidURL() async throws {
            // Create a URL that will fail to load
            let invalidURL = URL(string: "http://192.168.255.255:5000/nonexistent.jpg")!
            
            let remoteImage = RemoteImage(url: invalidURL) {
                Text("Failed to load")
            } content: { image in
                image.resizable()
            }
            
            #expect(remoteImage.url == invalidURL)
        }
    }
    
    // MARK: - CameraFeedCard Integration Tests
    
    @Suite("CameraFeedCard Integration")
    struct CameraFeedCardIntegrationTests {
        
        @Test("CameraFeedCard initialization")
        func testCameraFeedCardInitialization() async throws {
            let camera = "test_camera"
            let baseURL = "http://192.168.1.100:5000"
            
            // Test that CameraFeedCard can be created
            let cameraFeed = CameraFeedCard(camera: camera, baseURL: baseURL)
            
            // Basic structural validation
            #expect(cameraFeed.camera == camera)
            #expect(cameraFeed.baseURL == baseURL)
        }
        
        @Test("CameraFeedCard with settings store")
        func testCameraFeedCardWithSettings() async throws {
            let settingsStore = createMockSettingsStore()
            let camera = "backyard"
            let baseURL = "http://192.168.1.100:5000"
            
            let cameraFeed = CameraFeedCard(camera: camera, baseURL: baseURL)
                .environmentObject(settingsStore)
            
            // Verify the structure is intact
            #expect(cameraFeed.camera == camera)
            #expect(cameraFeed.baseURL == baseURL)
        }
    }
    
    // MARK: - Stream Setup Tests
    
    @Suite("Stream Setup Logic")
    struct StreamSetupTests {
        
        @Test("Stream URL generation consistency")
        func testStreamURLGenerationConsistency() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            let camera = "consistent_test"
            
            // Generate URLs multiple times and ensure consistency
            let url1 = client.getLiveStreamURL(for: camera, quality: .main)
            let url2 = client.getLiveStreamURL(for: camera, quality: .main)
            
            #expect(url1 == url2)
            
            // Different qualities should generate different URLs
            let mainURL = client.getLiveStreamURL(for: camera, quality: .main)
            let subURL = client.getLiveStreamURL(for: camera, quality: .sub)
            
            #expect(mainURL != subURL)
        }
        
        @Test("Stream fallback logic")
        func testStreamFallbackLogic() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            
            // Primary stream URL
            let primaryURL = client.getLiveStreamURL(for: testCamera, quality: .main)
            
            // Alternative URLs
            let alternativeURLs = client.getAlternativeStreamURLs(for: testCamera)
            
            #expect(primaryURL != nil)
            #expect(!alternativeURLs.isEmpty)
            
            // Primary URL should not be in alternatives (different formats)
            // But they should all contain the camera name
            if let primary = primaryURL {
                #expect(primary.absoluteString.contains(testCamera))
            }
            
            for alternative in alternativeURLs {
                #expect(alternative.absoluteString.contains(testCamera))
            }
        }
        
        @Test("Snapshot fallback URLs")
        func testSnapshotFallbackLogic() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            
            let primarySnapshot = client.getSnapshotURL(for: testCamera)
            let alternativeSnapshots = client.getAlternativeSnapshotURLs(for: testCamera)
            
            #expect(primarySnapshot != nil)
            #expect(!alternativeSnapshots.isEmpty)
            
            // All snapshot URLs should contain proper image extension
            if let primary = primarySnapshot {
                #expect(primary.absoluteString.contains("latest.jpg"))
            }
            
            for alternative in alternativeSnapshots {
                #expect(alternative.absoluteString.contains("latest.jpg"))
            }
        }
        
        @Test("Camera credential handling")
        func testCameraCredentialHandling() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            
            // Test default credentials
            #expect(client.cameraUsername == "admin")
            #expect(client.cameraPassword == "DavidAlan")
            
            // Update credentials
            let newUsername = "security_user"
            let newPassword = "complex_password_123"
            
            client.updateCredentials(username: newUsername, password: newPassword)
            
            #expect(client.cameraUsername == newUsername)
            #expect(client.cameraPassword == newPassword)
            
            // Test empty credentials
            client.updateCredentials(username: "", password: "")
            
            #expect(client.cameraUsername.isEmpty)
            #expect(client.cameraPassword.isEmpty)
        }
    }
    
    // MARK: - URL Construction Tests
    
    @Suite("URL Construction")
    struct URLConstructionTests {
        
        @Test("Go2RTC URL patterns")
        func testGo2RTCURLPatterns() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            
            let mainURL = client.getLiveStreamURL(for: testCamera, quality: .main)
            let subURL = client.getLiveStreamURL(for: testCamera, quality: .sub)
            let webrtcURL = client.getLiveStreamURL(for: testCamera, quality: .webrtc)
            let mjpegURL = client.getLiveStreamURL(for: testCamera, quality: .mjpeg)
            
            // All URLs should contain Go2RTC API path
            #expect(mainURL?.absoluteString.contains("go2rtc") == true)
            #expect(subURL?.absoluteString.contains("go2rtc") == true)
            #expect(webrtcURL?.absoluteString.contains("go2rtc") == true)
            #expect(mjpegURL?.absoluteString.contains("go2rtc") == true)
            
            // Main and sub should use HLS (.m3u8)
            #expect(mainURL?.absoluteString.contains("stream.m3u8") == true)
            #expect(subURL?.absoluteString.contains("stream.m3u8") == true)
            
            // WebRTC and MJPEG should use mode parameter
            #expect(webrtcURL?.absoluteString.contains("mode=mjpeg") == true)
            #expect(mjpegURL?.absoluteString.contains("mode=mjpeg") == true)
        }
        
        @Test("Camera name encoding in URLs")
        func testCameraNameEncodingInURLs() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            let specialCamera = "front_door-main"
            
            let url = client.getLiveStreamURL(for: specialCamera, quality: .main)
            
            #expect(url != nil)
            #expect(url?.absoluteString.contains("front_door-main") == true)
        }
        
        @Test("Base URL handling")
        func testBaseURLHandling() async throws {
            let baseURLsToTest = [
                "http://192.168.1.100:5000",
                "https://frigate.example.com",
                "http://10.0.0.100:8971",
                "https://secure-frigate.local:8443"
            ]
            
            for baseURL in baseURLsToTest {
                let client = LiveFeedAPIClient(baseURL: baseURL)
                let url = client.getLiveStreamURL(for: testCamera, quality: .main)
                
                #expect(url != nil)
                #expect(url?.absoluteString.hasPrefix(baseURL) == true)
            }
        }
        
        @Test("Malformed base URL handling")
        func testMalformedBaseURLHandling() async throws {
            let malformedURLs = [
                "",
                "not-a-url",
                "ftp://invalid-protocol.com",
                "http://[invalid-bracket"
            ]
            
            for baseURL in malformedURLs {
                let client = LiveFeedAPIClient(baseURL: baseURL)
                
                // Should not crash, but URLs may be invalid
                let url = client.getLiveStreamURL(for: testCamera, quality: .main)
                
                if url == nil && baseURL.isEmpty {
                    // Empty base URL should result in nil URL
                    continue
                } else if baseURL == "not-a-url" || baseURL == "ftp://invalid-protocol.com" {
                    // These might still create URLs but they won't work
                    print("Malformed URL created: \(url?.absoluteString ?? "nil")")
                }
            }
        }
    }
    
    // MARK: - Performance Tests
    
    @Suite("Performance Testing")
    struct PerformanceTests {
        
        @Test("URL generation performance")
        func testURLGenerationPerformance() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            let startTime = Date()
            
            // Generate many URLs
            for i in 0..<1000 {
                _ = client.getLiveStreamURL(for: "camera\(i)", quality: .main)
                _ = client.getSnapshotURL(for: "camera\(i)")
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            print("URL generation (2000 URLs): \(duration)s")
            #expect(duration < 1.0) // Should be very fast
        }
        
        @Test("Alternative URL generation performance")
        func testAlternativeURLGenerationPerformance() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            let startTime = Date()
            
            // Generate alternative URLs
            for i in 0..<100 {
                _ = client.getAlternativeStreamURLs(for: "camera\(i)")
                _ = client.getAlternativeSnapshotURLs(for: "camera\(i)")
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            print("Alternative URL generation (200 sets): \(duration)s")
            #expect(duration < 1.0)
        }
        
        @Test("Stream testing performance")
        func testStreamTestingPerformance() async throws {
            let client = LiveFeedAPIClient(baseURL: "http://httpbin.org")
            let testURLs = [
                URL(string: "http://httpbin.org/status/200")!,
                URL(string: "http://httpbin.org/status/404")!,
                URL(string: "http://httpbin.org/delay/1")!
            ]
            
            let startTime = Date()
            
            for url in testURLs {
                _ = await client.testStreamURL(url)
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            print("Stream testing (3 URLs): \(duration)s")
            #expect(duration < 15.0) // Should complete within reasonable time
        }
        
        @Test("Concurrent stream testing")
        func testConcurrentStreamTesting() async throws {
            let client = LiveFeedAPIClient(baseURL: "http://httpbin.org")
            let testURLs = [
                URL(string: "http://httpbin.org/status/200")!,
                URL(string: "http://httpbin.org/status/201")!,
                URL(string: "http://httpbin.org/status/404")!
            ]
            
            let startTime = Date()
            
            await withTaskGroup(of: Void.self) { group in
                for url in testURLs {
                    group.addTask {
                        _ = await client.testStreamURL(url)
                    }
                }
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            print("Concurrent stream testing (3 URLs): \(duration)s")
            #expect(duration < 10.0) // Concurrent should be faster
        }
        
        @Test("Diagnosis performance")
        func testDiagnosisPerformance() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            let startTime = Date()
            
            _ = await client.diagnoseStreamingEndpoints(for: testCamera)
            
            let duration = Date().timeIntervalSince(startTime)
            
            print("Stream diagnosis: \(duration)s")
            #expect(duration < 30.0) // Should complete within 30 seconds
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Suite("Error Handling")
    struct ErrorHandlingTests {
        
        @Test("Handle network timeouts gracefully")
        func testNetworkTimeoutHandling() async throws {
            let client = LiveFeedAPIClient(baseURL: "http://192.168.255.255:5000")
            
            let result = await client.testStreamURL(URL(string: "http://192.168.255.255:5000/stream")!)
            
            #expect(result.accessible == false)
            #expect(result.error != nil)
            #expect(result.contentType == nil)
        }
        
        @Test("Handle malformed URLs")
        func testMalformedURLHandling() async throws {
            let client = LiveFeedAPIClient(baseURL: "")
            
            let url = client.getLiveStreamURL(for: testCamera, quality: .main)
            
            // Should handle gracefully, might return nil or invalid URL
            if let url = url {
                print("Generated URL from empty base: \(url.absoluteString)")
            } else {
                print("Correctly returned nil for empty base URL")
            }
        }
        
        @Test("Handle camera fetch errors")
        func testCameraFetchErrorHandling() async throws {
            let client = LiveFeedAPIClient(baseURL: "http://192.168.255.255:5000")
            
            do {
                _ = try await client.fetchAvailableCameras()
                throw TestError.unexpectedSuccess
            } catch {
                print("Correctly caught camera fetch error: \(error)")
            }
        }
        
        @Test("Handle empty camera names")
        func testEmptyCameraNameHandling() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            
            let url = client.getLiveStreamURL(for: "", quality: .main)
            let snapshotURL = client.getSnapshotURL(for: "")
            
            // Should handle empty camera names gracefully
            #expect(url != nil) // URL structure should still be valid
            #expect(snapshotURL != nil)
        }
        
        @Test("Handle special characters in camera names")
        func testSpecialCharactersInCameraNames() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            let specialCameras = [
                "camera with spaces",
                "camera-with-dashes",
                "camera_with_underscores",
                "camera.with.dots",
                "camera123",
                "摄像头"  // Unicode characters
            ]
            
            for camera in specialCameras {
                let url = client.getLiveStreamURL(for: camera, quality: .main)
                let snapshotURL = client.getSnapshotURL(for: camera)
                
                #expect(url != nil)
                #expect(snapshotURL != nil)
                print("Generated URLs for '\(camera)': stream=\(url?.absoluteString ?? "nil"), snapshot=\(snapshotURL?.absoluteString ?? "nil")")
            }
        }
    }
}

// MARK: - Test Helper Types and Extensions

enum TestError: Error {
    case unexpectedSuccess
}

func createMockSettingsStore() -> SettingsStore {
    let store = SettingsStore()
    store.cameraUsername = "testuser"
    store.cameraPassword = "testpass"
    store.defaultStreamQuality = "sub"
    store.autoExpandFeeds = false
    return store
}