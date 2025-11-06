//
//  CameraFeedLoadingTests.swift
//  CrookedSentryTests
//
//  Created by Assistant on 2025
//

import Foundation
import XCTest
import SwiftUI
import AVFoundation
import Combine
@testable import CrookedSentry

// @Suite("Camera Feed Loading Tests")
struct CameraFeedLoadingTests {
    
    // MARK: - Test Configuration
    
    static let testBaseURL = "http://192.168.1.100:5000"
    static let testCamera = "test_camera"
    
    func createMockLiveFeedAPIClient() -> LiveFeedAPIClient {
        return LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
    }
    
    // MARK: - LiveFeedAPIClient Tests
    
    // @Suite("LiveFeedAPIClient Functionality")
    struct LiveFeedAPIClientTests {
        
        // @Test("Initialize with base URL")
        func testInitialization() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            XCTAssertTrue(client.baseURL == CameraFeedLoadingTests.testBaseURL)
            XCTAssertEqual(client.cameraUsername, "admin") // Default value
            XCTAssertEqual(client.cameraPassword, "DavidAlan") // Default value
        }
        
    // @Test("Update credentials")
    func testUpdateCredentials() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            let newUsername = "newuser"
            let newPassword = "newpass"
            
            client.updateCredentials(username: newUsername, password: newPassword)
            
            XCTAssertEqual(client.cameraUsername, newUsername)
            XCTAssertEqual(client.cameraPassword, newPassword)
        }
        
    // @Test("Get live stream URL for main quality")
    func testGetLiveStreamURLMain() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            
            let url = client.getLiveStreamURL(for: CameraFeedLoadingTests.testCamera, quality: StreamQuality.main)
            
            XCTAssertNotNil(url)
            XCTAssertTrue(url?.absoluteString.contains("stream.m3u8") ?? false)
            XCTAssertTrue(url?.absoluteString.contains(CameraFeedLoadingTests.testCamera) ?? false)
        }
        
    // @Test("Get live stream URL for sub quality")
    func testGetLiveStreamURLSub() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            
            let url = client.getLiveStreamURL(for: CameraFeedLoadingTests.testCamera, quality: StreamQuality.sub)
            
            XCTAssertNotNil(url)
            XCTAssertTrue(url?.absoluteString.contains("stream.m3u8") ?? false)
            XCTAssertTrue(url?.absoluteString.contains("\(CameraFeedLoadingTests.testCamera)_sub") ?? false)
        }
        
    // @Test("Get live stream URL for WebRTC quality")
    func testGetLiveStreamURLWebRTC() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            
            let url = client.getLiveStreamURL(for: CameraFeedLoadingTests.testCamera, quality: StreamQuality.webrtc)
            
            XCTAssertNotNil(url)
            XCTAssertTrue(url?.absoluteString.contains("mode=mjpeg") ?? false)
            XCTAssertTrue(url?.absoluteString.contains(CameraFeedLoadingTests.testCamera) ?? false)
        }
        
    // @Test("Get live stream URL for MJPEG quality")
    func testGetLiveStreamURLMJPEG() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            
            let url = client.getLiveStreamURL(for: CameraFeedLoadingTests.testCamera, quality: StreamQuality.mjpeg)
            
            XCTAssertNotNil(url)
            XCTAssertTrue(url?.absoluteString.contains("mode=mjpeg") ?? false)
            XCTAssertTrue(url?.absoluteString.contains(CameraFeedLoadingTests.testCamera) ?? false)
        }
        
    // @Test("Get alternative stream URLs")
    func testGetAlternativeStreamURLs() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            
            let urls = client.getAlternativeStreamURLs(for: CameraFeedLoadingTests.testCamera)
            
            XCTAssertFalse(urls.isEmpty)
            XCTAssertGreaterThanOrEqual(urls.count, 3) // Should have multiple alternatives
            
            // Check that each URL contains the camera name
            for url in urls {
                XCTAssertTrue(url.absoluteString.contains(CameraFeedLoadingTests.testCamera))
            }
        }
        
    // @Test("Get snapshot URL")
    func testGetSnapshotURL() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            
            let url = client.getSnapshotURL(for: CameraFeedLoadingTests.testCamera)
            
            XCTAssertNotNil(url)
            XCTAssertTrue(url?.absoluteString.contains("latest.jpg") ?? false)
            XCTAssertTrue(url?.absoluteString.contains(CameraFeedLoadingTests.testCamera) ?? false)
            XCTAssertTrue(url?.absoluteString.contains("t=") ?? false) // Timestamp parameter
        }
        
    // @Test("Get alternative snapshot URLs")
    func testGetAlternativeSnapshotURLs() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            
            let urls = client.getAlternativeSnapshotURLs(for: CameraFeedLoadingTests.testCamera)
            
            XCTAssertFalse(urls.isEmpty)
            XCTAssertGreaterThanOrEqual(urls.count, 2) // Should have multiple alternatives
            
            // Check that each URL contains latest.jpg and camera name
            for url in urls {
                XCTAssertTrue(url.absoluteString.contains("latest.jpg"))
                XCTAssertTrue(url.absoluteString.contains(CameraFeedLoadingTests.testCamera) || url.absoluteString.contains("snapshot"))
            }
        }
        
    // @Test("Test stream URL accessibility - valid URL")
    func testStreamURLAccessibilityValid() async throws {
            let client = LiveFeedAPIClient(baseURL: "http://httpbin.org")
            let testURL = URL(string: "http://httpbin.org/status/200")!
            
            let result = await client.testStreamURL(testURL)
            
            XCTAssertTrue(result.accessible)
            XCTAssertNil(result.error)
        }
        
    // @Test("Test stream URL accessibility - invalid URL")
    func testStreamURLAccessibilityInvalid() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            let testURL = URL(string: "http://192.168.255.255:5000/invalid")!
            
            let result = await client.testStreamURL(testURL)
            
            XCTAssertFalse(result.accessible)
            XCTAssertNotNil(result.error)
        }
        
    // @Test("Test stream URL accessibility - HTTP error")
    func testStreamURLAccessibilityHTTPError() async throws {
            let client = LiveFeedAPIClient(baseURL: "http://httpbin.org")
            let testURL = URL(string: "http://httpbin.org/status/404")!
            
            let result = await client.testStreamURL(testURL)
            
            XCTAssertFalse(result.accessible)
            XCTAssertNotNil(result.contentType) // Should still get response headers
        }
        
    // @Test("Diagnose streaming endpoints")
    func testDiagnoseStreamingEndpoints() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            
            let results = await client.diagnoseStreamingEndpoints(for: CameraFeedLoadingTests.testCamera)
            
            XCTAssertFalse(results.isEmpty)
            XCTAssertGreaterThanOrEqual(results.count, 5) // Should test multiple endpoints
            
            // Each result should have URL and status
            for result in results {
                XCTAssertFalse(result.url.isEmpty)
                XCTAssertTrue(result.url.contains(CameraFeedLoadingTests.testCamera) || result.url.contains("latest.jpg"))
            }
        }
        
    // @Test("Fetch available cameras - network error")
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
        
    // @Test("Fetch available cameras - invalid response")
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
    
    // @Suite("StreamQuality Enum")
    struct StreamQualityTests {
        
        // @Test("All stream quality cases exist")
        func testStreamQualityCases() async throws {
            let allCases = StreamQuality.allCases
            
            XCTAssertTrue(allCases.contains(.main))
            XCTAssertTrue(allCases.contains(.sub))
            XCTAssertTrue(allCases.contains(.webrtc))
            XCTAssertTrue(allCases.contains(.mjpeg))
            XCTAssertEqual(allCases.count, 4)
        }
        
    // @Test("Stream quality display names")
    func testStreamQualityDisplayNames() async throws {
            XCTAssertEqual(StreamQuality.main.displayName, "High Quality")
            XCTAssertEqual(StreamQuality.sub.displayName, "Low Quality")
            XCTAssertEqual(StreamQuality.webrtc.displayName, "WebRTC")
            XCTAssertEqual(StreamQuality.mjpeg.displayName, "MJPEG")
        }
        
    // @Test("Stream quality descriptions")
    func testStreamQualityDescriptions() async throws {
            XCTAssertFalse(StreamQuality.main.description.isEmpty)
            XCTAssertFalse(StreamQuality.sub.description.isEmpty)
            XCTAssertFalse(StreamQuality.webrtc.description.isEmpty)
            XCTAssertFalse(StreamQuality.mjpeg.description.isEmpty)
        }
        
    // @Test("Stream quality raw values")
    func testStreamQualityRawValues() async throws {
            XCTAssertEqual(StreamQuality.main.rawValue, "main")
            XCTAssertEqual(StreamQuality.sub.rawValue, "sub")
            XCTAssertEqual(StreamQuality.webrtc.rawValue, "webrtc")
            XCTAssertEqual(StreamQuality.mjpeg.rawValue, "mjpeg")
        }
        
    // @Test("Stream quality initialization from raw value")
    func testStreamQualityInitFromRawValue() async throws {
            XCTAssertEqual(StreamQuality(rawValue: "main"), .main)
            XCTAssertEqual(StreamQuality(rawValue: "sub"), .sub)
            XCTAssertEqual(StreamQuality(rawValue: "webrtc"), .webrtc)
            XCTAssertEqual(StreamQuality(rawValue: "mjpeg"), .mjpeg)
            XCTAssertNil(StreamQuality(rawValue: "invalid"))
        }
    }
    
    // MARK: - RemoteImage Tests
    
    // @Suite("RemoteImage Component")
    struct RemoteImageTests {
        
        // @Test("RemoteImage initialization")
        func testRemoteImageInitialization() async throws {
            let testURL = URL(string: "http://httpbin.org/image/png")!
            
            let remoteImage = RemoteImage(url: testURL) {
                Text("Loading...")
            } content: { image in
                image.resizable()
            }
            
            // Basic initialization test - structure should be valid
            XCTAssertEqual(remoteImage.url, testURL)
        }
        
    // @Test("RemoteImage with invalid URL structure")
    func testRemoteImageInvalidURL() async throws {
            // Create a URL that will fail to load
            let invalidURL = URL(string: "http://192.168.255.255:5000/nonexistent.jpg")!
            
            let remoteImage = RemoteImage(url: invalidURL) {
                Text("Failed to load")
            } content: { image in
                image.resizable()
            }
            
            XCTAssertEqual(remoteImage.url, invalidURL)
        }
    }
    
    // MARK: - CameraFeedCard Integration Tests
    
    // @Suite("CameraFeedCard Integration")
    struct CameraFeedCardIntegrationTests {
        
        // @Test("CameraFeedCard initialization")
        func testCameraFeedCardInitialization() async throws {
            let camera = "test_camera"
            let baseURL = "http://192.168.1.100:5000"
            
            // Test that CameraFeedCard can be created
            let cameraFeed = CameraFeedCard(camera: camera, baseURL: baseURL)
            
            // Basic structural validation
            XCTAssertEqual(cameraFeed.camera, camera)
            XCTAssertEqual(cameraFeed.baseURL, baseURL)
        }
        
    // @Test("CameraFeedCard with settings store")
    func testCameraFeedCardWithSettings() async throws {
            let settingsStore = createMockSettingsStore()
            let camera = "backyard"
            let baseURL = "http://192.168.1.100:5000"
            
            let cameraFeed = CameraFeedCard(camera: camera, baseURL: baseURL)
            let _ = cameraFeed.environmentObject(settingsStore)
            
            // Verify the structure is intact on the underlying view
            XCTAssertEqual(cameraFeed.camera, camera)
            XCTAssertEqual(cameraFeed.baseURL, baseURL)
        }
    }
    
    // MARK: - Stream Setup Tests
    
    // @Suite("Stream Setup Logic")
    struct StreamSetupTests {
        
        // @Test("Stream URL generation consistency")
        func testStreamURLGenerationConsistency() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            let camera = "consistent_test"
            
            // Generate URLs multiple times and ensure consistency
            let url1 = client.getLiveStreamURL(for: camera, quality: StreamQuality.main)
            let url2 = client.getLiveStreamURL(for: camera, quality: StreamQuality.main)
            
            XCTAssertEqual(url1, url2)
            
            // Different qualities should generate different URLs
            let mainURL = client.getLiveStreamURL(for: camera, quality: StreamQuality.main)
            let subURL = client.getLiveStreamURL(for: camera, quality: StreamQuality.sub)
            
            XCTAssertNotEqual(mainURL, subURL)
        }
        
    // @Test("Stream fallback logic")
    func testStreamFallbackLogic() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            
            // Primary stream URL
            let primaryURL = client.getLiveStreamURL(for: CameraFeedLoadingTests.testCamera, quality: StreamQuality.main)
            
            // Alternative URLs
            let alternativeURLs = client.getAlternativeStreamURLs(for: CameraFeedLoadingTests.testCamera)
            
            XCTAssertNotNil(primaryURL)
            XCTAssertFalse(alternativeURLs.isEmpty)
            
            // Primary URL should not be in alternatives (different formats)
            // But they should all contain the camera name
            if let primary = primaryURL {
                XCTAssertTrue(primary.absoluteString.contains(CameraFeedLoadingTests.testCamera))
            }
            
            for alternative in alternativeURLs {
                XCTAssertTrue(alternative.absoluteString.contains(CameraFeedLoadingTests.testCamera))
            }
        }
        
    // @Test("Snapshot fallback URLs")
    func testSnapshotFallbackLogic() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            
            let primarySnapshot = client.getSnapshotURL(for: CameraFeedLoadingTests.testCamera)
            let alternativeSnapshots = client.getAlternativeSnapshotURLs(for: CameraFeedLoadingTests.testCamera)
            
            XCTAssertNotNil(primarySnapshot)
            XCTAssertFalse(alternativeSnapshots.isEmpty)
            
            // All snapshot URLs should contain proper image extension
            if let primary = primarySnapshot {
                XCTAssertTrue(primary.absoluteString.contains("latest.jpg"))
            }
            
            for alternative in alternativeSnapshots {
                XCTAssertTrue(alternative.absoluteString.contains("latest.jpg"))
            }
        }
        
    // @Test("Camera credential handling")
    func testCameraCredentialHandling() async throws {
            let client = LiveFeedAPIClient(baseURL: testBaseURL)
            
            // Test default credentials
            XCTAssertEqual(client.cameraUsername, "admin")
            XCTAssertEqual(client.cameraPassword, "DavidAlan")
            
            // Update credentials
            let newUsername = "security_user"
            let newPassword = "complex_password_123"
            
            client.updateCredentials(username: newUsername, password: newPassword)
            
            XCTAssertEqual(client.cameraUsername, newUsername)
            XCTAssertEqual(client.cameraPassword, newPassword)
            
            // Test empty credentials
            client.updateCredentials(username: "", password: "")
            
            XCTAssertTrue(client.cameraUsername.isEmpty)
            XCTAssertTrue(client.cameraPassword.isEmpty)
        }
    }
    
    // MARK: - URL Construction Tests
    
    // @Suite("URL Construction")
    struct URLConstructionTests {
        
        // @Test("Go2RTC URL patterns")
        func testGo2RTCURLPatterns() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            
            let mainURL = client.getLiveStreamURL(for: CameraFeedLoadingTests.testCamera, quality: StreamQuality.main)
            let subURL = client.getLiveStreamURL(for: CameraFeedLoadingTests.testCamera, quality: StreamQuality.sub)
            let webrtcURL = client.getLiveStreamURL(for: CameraFeedLoadingTests.testCamera, quality: StreamQuality.webrtc)
            let mjpegURL = client.getLiveStreamURL(for: CameraFeedLoadingTests.testCamera, quality: StreamQuality.mjpeg)
            
            // All URLs should contain Go2RTC API path
            XCTAssertTrue(mainURL?.absoluteString.contains("go2rtc") ?? false)
            XCTAssertTrue(subURL?.absoluteString.contains("go2rtc") ?? false)
            XCTAssertTrue(webrtcURL?.absoluteString.contains("go2rtc") ?? false)
            XCTAssertTrue(mjpegURL?.absoluteString.contains("go2rtc") ?? false)
            
            // Main and sub should use HLS (.m3u8)
            XCTAssertTrue(mainURL?.absoluteString.contains("stream.m3u8") ?? false)
            XCTAssertTrue(subURL?.absoluteString.contains("stream.m3u8") ?? false)
            
            // WebRTC and MJPEG should use mode parameter
            XCTAssertTrue(webrtcURL?.absoluteString.contains("mode=mjpeg") ?? false)
            XCTAssertTrue(mjpegURL?.absoluteString.contains("mode=mjpeg") ?? false)
        }
        
    // @Test("Camera name encoding in URLs")
    func testCameraNameEncodingInURLs() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            let specialCamera = "front_door-main"
            
            let url = client.getLiveStreamURL(for: specialCamera, quality: StreamQuality.main)
            
            XCTAssertNotNil(url)
            XCTAssertTrue(url?.absoluteString.contains("front_door-main") ?? false)
        }
        
    // @Test("Base URL handling")
    func testBaseURLHandling() async throws {
            let baseURLsToTest = [
                "http://192.168.1.100:5000",
                "https://frigate.example.com",
                "http://10.0.0.100:8971",
                "https://secure-frigate.local:8443"
            ]
            
            for baseURL in baseURLsToTest {
                let client = LiveFeedAPIClient(baseURL: baseURL)
                let url = client.getLiveStreamURL(for: CameraFeedLoadingTests.testCamera, quality: StreamQuality.main)
                
                XCTAssertNotNil(url)
                XCTAssertTrue(url?.absoluteString.hasPrefix(baseURL) ?? false)
            }
        }
        
    // @Test("Malformed base URL handling")
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
                let url = client.getLiveStreamURL(for: CameraFeedLoadingTests.testCamera, quality: StreamQuality.main)
                
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
    
    // @Suite("Performance Testing")
    struct PerformanceTests {
        
        // @Test("URL generation performance")
        func testURLGenerationPerformance() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            let startTime = Date()
            
            // Generate many URLs
            for i in 0..<1000 {
                _ = client.getLiveStreamURL(for: "camera\(i)", quality: StreamQuality.main)
                _ = client.getSnapshotURL(for: "camera\(i)")
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            print("URL generation (2000 URLs): \(duration)s")
            XCTAssertLessThan(duration, 1.0) // Should be very fast
        }
        
    // @Test("Alternative URL generation performance")
    func testAlternativeURLGenerationPerformance() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            let startTime = Date()
            
            // Generate alternative URLs
            for i in 0..<100 {
                _ = client.getAlternativeStreamURLs(for: "camera\(i)")
                _ = client.getAlternativeSnapshotURLs(for: "camera\(i)")
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            print("Alternative URL generation (200 sets): \(duration)s")
            XCTAssertLessThan(duration, 1.0)
        }
        
    // @Test("Stream testing performance")
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
            XCTAssertLessThan(duration, 15.0) // Should complete within reasonable time
        }
        
    // @Test("Concurrent stream testing")
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
            XCTAssertLessThan(duration, 10.0) // Concurrent should be faster
        }
        
    // @Test("Diagnosis performance")
    func testDiagnosisPerformance() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            let startTime = Date()
            
            _ = await client.diagnoseStreamingEndpoints(for: CameraFeedLoadingTests.testCamera)
            
            let duration = Date().timeIntervalSince(startTime)
            
            print("Stream diagnosis: \(duration)s")
            XCTAssertLessThan(duration, 30.0) // Should complete within 30 seconds
        }
    }
    
    // MARK: - Error Handling Tests
    
    // @Suite("Error Handling")
    struct ErrorHandlingTests {
        
        // @Test("Handle network timeouts gracefully")
        func testNetworkTimeoutHandling() async throws {
            let client = LiveFeedAPIClient(baseURL: "http://192.168.255.255:5000")
            
            let result = await client.testStreamURL(URL(string: "http://192.168.255.255:5000/stream")!)
            
            XCTAssertFalse(result.accessible)
            XCTAssertNotNil(result.error)
            XCTAssertNil(result.contentType)
        }
        
    // @Test("Handle malformed URLs")
    func testMalformedURLHandling() async throws {
            let client = LiveFeedAPIClient(baseURL: "")
            
            let url = client.getLiveStreamURL(for: CameraFeedLoadingTests.testCamera, quality: StreamQuality.main)
            
            // Should handle gracefully, might return nil or invalid URL
            if let url = url {
                print("Generated URL from empty base: \(url.absoluteString)")
            } else {
                print("Correctly returned nil for empty base URL")
            }
        }
        
    // @Test("Handle camera fetch errors")
    func testCameraFetchErrorHandling() async throws {
            let client = LiveFeedAPIClient(baseURL: "http://192.168.255.255:5000")
            
            do {
                _ = try await client.fetchAvailableCameras()
                throw TestError.unexpectedSuccess
            } catch {
                print("Correctly caught camera fetch error: \(error)")
            }
        }
        
    // @Test("Handle empty camera names")
    func testEmptyCameraNameHandling() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            
            let url = client.getLiveStreamURL(for: "", quality: StreamQuality.main)
            let snapshotURL = client.getSnapshotURL(for: "")
            
            // Should handle empty camera names gracefully
            XCTAssertNotNil(url) // URL structure should still be valid
            XCTAssertNotNil(snapshotURL)
        }
        
    // @Test("Handle special characters in camera names")
    func testSpecialCharactersInCameraNames() async throws {
            let client = LiveFeedAPIClient(baseURL: CameraFeedLoadingTests.testBaseURL)
            let specialCameras = [
                "camera with spaces",
                "camera-with-dashes",
                "camera_with_underscores",
                "camera.with.dots",
                "camera123",
                "摄像头"  // Unicode characters
            ]
            
            for camera in specialCameras {
                let url = client.getLiveStreamURL(for: camera, quality: StreamQuality.main)
                let snapshotURL = client.getSnapshotURL(for: camera)
                
                XCTAssertNotNil(url)
                XCTAssertNotNil(snapshotURL)
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