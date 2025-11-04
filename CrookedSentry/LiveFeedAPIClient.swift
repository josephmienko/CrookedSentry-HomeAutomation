//
//  LiveFeedAPIClient.swift
//  ccCCTV
//
//  Created by Assistant on 2025
//

import Foundation
import AVFoundation
import Combine

class LiveFeedAPIClient: ObservableObject {
    private let session: URLSession
    var baseURL: String
    
    init(baseURL: String) {
        self.baseURL = baseURL
        
        // Optimized session configuration for live streams
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 10
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 120
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil // Disable caching for live streams
        
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Live Stream URLs
    
    /// Get the live stream URL for a specific camera
    /// Using direct Go2RTC streaming endpoints for Frigate 0.16+
    func getLiveStreamURL(for camera: String, quality: StreamQuality = .main) -> URL? {
        switch quality {
        case .main:
            // Direct Go2RTC HLS stream
            return URL(string: "\(baseURL)/api/go2rtc/api/stream.m3u8?src=\(camera)")
        case .sub:
            // Go2RTC sub stream
            return URL(string: "\(baseURL)/api/go2rtc/api/stream.m3u8?src=\(camera)_sub")
        case .webrtc:
            // Go2RTC MJPEG stream
            return URL(string: "\(baseURL)/api/go2rtc/api/stream?src=\(camera)&mode=mjpeg")
        case .mjpeg:
            // Go2RTC MJPEG stream
            return URL(string: "\(baseURL)/api/go2rtc/api/stream?src=\(camera)&mode=mjpeg")
        }
    }
    
    /// Get alternative stream URLs to try if the primary fails
    /// Using direct Go2RTC streaming endpoints for Frigate 0.16+
    func getAlternativeStreamURLs(for camera: String) -> [URL] {
        let alternatives = [
            "\(baseURL)/api/go2rtc/api/stream.m3u8?src=\(camera)",                   // Go2RTC HLS
            "\(baseURL)/api/go2rtc/api/stream?src=\(camera)&mode=mjpeg",            // Go2RTC MJPEG  
            "\(baseURL)/api/go2rtc/api/stream.m3u8?src=\(camera)_sub",              // Go2RTC sub HLS
            "\(baseURL)/api/go2rtc/api/stream?src=\(camera)&mode=hls",              // Go2RTC HLS alt
        ]
        
        return alternatives.compactMap { URL(string: $0) }
    }
    
    /// Extract camera IP from camera name or use default mapping
    private func getCameraIP(for camera: String) -> String? {
        // Your specific camera IP addresses
        let defaultMapping: [String: String] = [
            "backyard": "192.168.0.210",  // First ANNKE camera
            "cam1": "192.168.0.211"       // Second ANNKE camera
        ]
        
        return defaultMapping[camera.lowercased()]
    }
    
    // Camera credentials (will be set from settings)
    var cameraUsername: String = "admin"
    var cameraPassword: String = "DavidAlan"
    
    /// Get camera credentials for authentication
    private func getCameraCredentials(for camera: String) -> (username: String, password: String)? {
        return (cameraUsername, cameraPassword)
    }
    
    /// Update camera credentials from settings
    func updateCredentials(username: String, password: String) {
        self.cameraUsername = username
        self.cameraPassword = password
    }
    
    /// Update camera IP mapping from settings
    func updateCameraIPs(_ ipMapping: [String: String]) {
        // This will be called from the UI to update IP mappings
        // For now, we use the default mapping, but this can be expanded
    }
    
    /// Test if a stream URL is accessible
    func testStreamURL(_ url: URL) async -> (accessible: Bool, contentType: String?, error: String?) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10
        
        do {
            let (_, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return (false, nil, "Invalid response type")
            }
            
            let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")
            let accessible = (200...299).contains(httpResponse.statusCode)
            
            return (accessible, contentType, accessible ? nil : "HTTP \(httpResponse.statusCode)")
        } catch {
            return (false, nil, error.localizedDescription)
        }
    }
    
    /// Get a snapshot URL for fallback when live stream isn't available
    func getSnapshotURL(for camera: String) -> URL? {
        // Use the working non-API pattern first (green status ✅)
        let timestamp = Date().timeIntervalSince1970
        return URL(string: "\(baseURL)/\(camera)/latest.jpg?t=\(timestamp)")
    }
    
    /// Get alternative snapshot URLs to try if the primary fails
    func getAlternativeSnapshotURLs(for camera: String) -> [URL] {
        let timestamp = Date().timeIntervalSince1970
        
        // ONLY use the working snapshot patterns (green status ✅)
        let alternatives = [
            "\(baseURL)/\(camera)/latest.jpg?t=\(timestamp)",            // Working ✅
            "\(baseURL)/snapshot/\(camera)?t=\(timestamp)"               // Working ✅
        ]
        
        return alternatives.compactMap { URL(string: $0) }
    }
    
    /// Fetch available cameras from Frigate config
    func fetchAvailableCameras() async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/api/config") else {
            throw URLError(.badURL)
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let config = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let cameras = config?["cameras"] as? [String: Any]
            return cameras?.keys.sorted() ?? []
        } catch {
            throw error
        }
    }
    
    /// Diagnose available streaming endpoints for debugging
    /// Now only shows the 4 confirmed working endpoints
    func diagnoseStreamingEndpoints(for camera: String) async -> [(url: String, status: Int, contentType: String?)] {
        let testUrls = [
            // Direct Go2RTC streaming endpoints for Frigate 0.16+
            "\(baseURL)/api/go2rtc/api/stream.m3u8?src=\(camera)",                  // Go2RTC HLS direct
            "\(baseURL)/api/go2rtc/api/stream?src=\(camera)&mode=mjpeg",            // Go2RTC MJPEG direct
            "\(baseURL)/api/go2rtc/api/stream.m3u8?src=\(camera)_sub",              // Go2RTC sub HLS
            "\(baseURL)/api/go2rtc/streams?src=\(camera)",                          // Go2RTC metadata
            
            // Snapshot endpoints
            "\(baseURL)/api/\(camera)/latest.jpg",                                 // API snapshot
            "\(baseURL)/\(camera)/latest.jpg"                                      // Direct snapshot
        ]
        
        var results: [(url: String, status: Int, contentType: String?)] = []
        
        for urlString in testUrls {
            guard let url = URL(string: urlString) else { continue }
            
            let result = await testStreamURL(url)
            let status = result.accessible ? 200 : -1
            results.append((urlString, status, result.contentType))
            
            print("🔍 Tested: \(urlString) -> Status: \(status), ContentType: \(result.contentType ?? "none"), Error: \(result.error ?? "none")")
        }
        
        return results
    }
}

// MARK: - Stream Quality Options

enum StreamQuality: String, CaseIterable {
    case main = "main"
    case sub = "sub"
    case webrtc = "webrtc"
    case mjpeg = "mjpeg"
    
    var displayName: String {
        switch self {
        case .main:
            return "High Quality"
        case .sub:
            return "Low Quality"
        case .webrtc:
            return "WebRTC"
        case .mjpeg:
            return "MJPEG"
        }
    }
    
    var description: String {
        switch self {
        case .main:
            return "Full resolution stream"
        case .sub:
            return "Mobile optimized stream"
        case .webrtc:
            return "Low latency WebRTC"
        case .mjpeg:
            return "MJPEG snapshots"
        }
    }
}