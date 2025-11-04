//
//  CameraFeedCard.swift
//  ccCCTV
//
//  Created by Assistant on 2025
//

import SwiftUI
import AVKit
import AVFoundation

struct CameraFeedCard: View {
    let camera: String
    let baseURL: String
    @EnvironmentObject var settingsStore: SettingsStore
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var streamQuality: StreamQuality = .sub
    @State private var isExpanded = false
    @State private var lastSnapshotUpdate = Date()
    @State private var snapshotTimer: Timer?
    
    private let liveFeedClient: LiveFeedAPIClient
    
    init(camera: String, baseURL: String) {
        self.camera = camera
        self.baseURL = baseURL
        self.liveFeedClient = LiveFeedAPIClient(baseURL: baseURL)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Camera Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(camera.toFriendlyName())
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        // Status indicator
                        Circle()
                            .fill(player != nil ? Color.green : (isLoading ? Color.orange : Color.red))
                            .frame(width: 8, height: 8)
                        
                        Text(getStatusText())
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Debug button
                NavigationLink(destination: StreamDebugView(camera: camera, baseURL: baseURL)) {
                    Image(systemName: "wrench.and.screwdriver")
                        .foregroundColor(.orange)
                        .padding(8)
                }
                
                // Quality selector
                Menu {
                    ForEach(StreamQuality.allCases, id: \.self) { quality in
                        Button(quality.displayName) {
                            streamQuality = quality
                            Task { await setupLiveStream() }
                        }
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(.blue)
                        .padding(8)
                }
                
                // Expand/collapse button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .padding(8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Video Feed (expandable)
            if isExpanded {
                ZStack {
                    // Black background
                    Color.black
                        .aspectRatio(16/9, contentMode: .fit)
                    
                    if isLoading {
                        VStack(spacing: 12) {
                            if #available(iOS 15.0, *) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(.white)
                            } else {
                                // Fallback on earlier versions
                            }
                            Text("Connecting...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else if let player = player {
                        // Live video player
                        VideoPlayer(player: player)
                            .aspectRatio(16/9, contentMode: .fit)
                            .onAppear {
                                setupAudioSession()
                                player.play()
                            }
                            .onDisappear {
                                player.pause()
                                cleanupAudioSession()
                            }
                    } else if errorMessage != nil {
                        // Fallback to snapshot updates when live stream fails
                        SnapshotFeedView(camera: camera, baseURL: baseURL)
                    } else {
                        // No feed available
                        VStack(spacing: 12) {
                            Image(systemName: "video.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("Camera Unavailable")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.slide)
            }
        }
        .background(Color(red: 25/255, green: 25/255, blue: 25/255))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(radius: 4)
        .onAppear {
            // Set initial quality from settings
            if let quality = StreamQuality(rawValue: settingsStore.defaultStreamQuality) {
                streamQuality = quality
            }
            
            // Auto-expand if enabled in settings
            isExpanded = settingsStore.autoExpandFeeds
            
            // Update credentials
            liveFeedClient.updateCredentials(
                username: settingsStore.cameraUsername,
                password: settingsStore.cameraPassword
            )
            
            Task { await setupLiveStream() }
        }
        .onDisappear {
            cleanupPlayer()
        }
    }
    
    // MARK: - Stream Setup
    
    private func setupLiveStream() async {
        isLoading = true
        errorMessage = nil
        
        print("🔍 Setting up live stream for camera: \(camera)")
        
        // First, run diagnostics to see what's available
        let diagnostics = await liveFeedClient.diagnoseStreamingEndpoints(for: camera)
        print("🔍 Diagnostic results for \(camera):")
        for diagnostic in diagnostics {
            print("   \(diagnostic.url) -> Status: \(diagnostic.status), Type: \(diagnostic.contentType ?? "none")")
        }
        
        // Test direct URL accessibility and check Go2RTC response
        if let streamURL = liveFeedClient.getLiveStreamURL(for: camera, quality: streamQuality) {
            await testDirectURLAccess(url: streamURL)
        }
        
        // Check what Go2RTC actually returns
        await checkGo2RTCInfo(for: camera)
        
        // First, try the selected quality stream
        if let streamURL = liveFeedClient.getLiveStreamURL(for: camera, quality: streamQuality) {
            print("📡 Trying \(streamQuality.displayName) stream for \(camera): \(streamURL)")
            
            let result = await liveFeedClient.testStreamURL(streamURL)
            if result.accessible {
                print("✅ Primary stream successful for \(camera)")
                await MainActor.run {
                    setupPlayer(with: streamURL)
                    return
                }
            } else {
                print("❌ Primary stream failed for \(camera): \(result.error ?? "Unknown error")")
            }
        }
        
        // If primary stream fails, try alternatives
        let alternativeURLs = liveFeedClient.getAlternativeStreamURLs(for: camera)
        for (index, url) in alternativeURLs.enumerated() {
            print("📡 Trying alternative \(index + 1)/\(alternativeURLs.count) for \(camera): \(url)")
            
            let result = await liveFeedClient.testStreamURL(url)
            if result.accessible {
                print("✅ Alternative stream \(index + 1) successful for \(camera)")
                await MainActor.run {
                    setupPlayer(with: url)
                    return
                }
            } else {
                print("❌ Alternative \(index + 1) failed for \(camera): \(result.error ?? "Unknown error")")
            }
        }
        
        // All streams failed, will fallback to snapshot updates
        await MainActor.run {
            isLoading = false
            errorMessage = "Live stream unavailable"
            print("⚠️ All streams failed for \(camera), falling back to snapshots")
        }
    }
    
    private func setupPlayer(with url: URL) {
        cleanupPlayer()
        
        print("🎬 Setting up AVPlayer with URL: \(url)")
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.automaticallyWaitsToMinimizeStalling = false
        
        // Add more detailed observers
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            print("🎬 Player reached end for \(self.camera)")
        }
        
        // Monitor player status changes
        Task {
            await monitorPlayerStatus(playerItem: playerItem)
        }
        
        // Try to play immediately
        player?.play()
        print("🎬 Called play() on player for \(camera)")
        
        // Add observers for connection status
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            print("⚠️ Stream failed for \(camera), attempting reconnection...")
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds
                await setupLiveStream()
            }
        }
        
        isLoading = false
        errorMessage = nil
        print("✅ Successfully set up stream for \(camera)")
    }
    
    private func cleanupPlayer() {
        player?.pause()
        player = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Audio Session Management
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ Failed to setup audio session: \(error)")
        }
    }
    
    private func cleanupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("⚠️ Failed to cleanup audio session: \(error)")
        }
    }
    
    // MARK: - Player Monitoring
    
    private func monitorPlayerStatus(playerItem: AVPlayerItem) async {
        // Check status periodically
        for i in 0..<30 { // Check for 30 seconds
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            await MainActor.run {
                switch playerItem.status {
                case .readyToPlay:
                    print("✅ AVPlayerItem ready to play for \(camera) (check \(i+1))")
                    return // Success, stop monitoring
                case .failed:
                    print("❌ AVPlayerItem failed for \(camera) (check \(i+1)): \(playerItem.error?.localizedDescription ?? "Unknown error")")
                    return // Failed, stop monitoring
                case .unknown:
                    print("⏳ AVPlayerItem status unknown for \(camera) (check \(i+1))")
                @unknown default:
                    print("❓ AVPlayerItem unknown status for \(camera) (check \(i+1))")
                }
                
                // Log loaded time ranges
                if !playerItem.loadedTimeRanges.isEmpty {
                    print("📊 Time ranges loaded for \(camera): \(playerItem.loadedTimeRanges.count) ranges")
                }
            }
        }
        
        await MainActor.run {
            print("⏰ Stopped monitoring \(camera) after 30 seconds")
        }
    }
    
    private func testDirectURLAccess(url: URL) async {
        print("🌐 Testing direct URL access for \(camera): \(url)")
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 10
            request.setValue("VLC/3.0.0 LibVLC/3.0.0", forHTTPHeaderField: "User-Agent") // Pretend to be VLC
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 Direct URL test for \(camera): HTTP \(httpResponse.statusCode)")
                print("🌐 Content-Type: \(httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "none")")
                print("🌐 Content-Length: \(data.count) bytes")
                
                // For HLS, check if we get a valid playlist
                if url.pathExtension == "m3u8" {
                    let content = String(data: data, encoding: .utf8) ?? ""
                    print("🌐 HLS Playlist content preview: \(String(content.prefix(200)))")
                    
                    if content.contains("#EXTM3U") {
                        print("✅ Valid HLS playlist detected for \(camera)")
                    } else {
                        print("❌ Invalid HLS playlist for \(camera)")
                    }
                }
            }
        } catch {
            print("❌ Direct URL test failed for \(camera): \(error.localizedDescription)")
        }
    }
    
    private func checkGo2RTCInfo(for camera: String) async {
        let go2rtcURL = "\(liveFeedClient.baseURL)/api/go2rtc/streams?src=\(camera)"
        print("🔍 Checking Go2RTC info for \(camera): \(go2rtcURL)")
        
        guard let url = URL(string: go2rtcURL) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let jsonString = String(data: data, encoding: .utf8) ?? ""
            print("📡 Go2RTC response for \(camera): \(jsonString)")
            
            // Parse JSON to find actual streaming URLs
            if let jsonData = jsonString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                print("📊 Go2RTC parsed data: \(json)")
                
                // Try to extract actual stream URLs from the JSON
                for (key, value) in json {
                    print("📊   \(key): \(value)")
                }
            }
            
            // Test some actual Go2RTC streaming URLs
            await testActualGo2RTCStreams(for: camera)
        } catch {
            print("❌ Failed to check Go2RTC info: \(error.localizedDescription)")
        }
    }
    
    private func testActualGo2RTCStreams(for camera: String) async {
        let streamUrls = [
            "\(liveFeedClient.baseURL)/api/go2rtc/api/stream?src=\(camera)&mode=hls",
            "\(liveFeedClient.baseURL)/api/go2rtc/api/stream?src=\(camera)&mode=mjpeg",
            "\(liveFeedClient.baseURL)/api/go2rtc/api/stream.m3u8?src=\(camera)",
            "\(liveFeedClient.baseURL)/api/go2rtc/api/ws?src=\(camera)"
        ]
        
        for urlString in streamUrls {
            guard let url = URL(string: urlString) else { continue }
            
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "HEAD"
                request.timeoutInterval = 5
                
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "unknown"
                    print("🎯 Go2RTC stream test \(camera): \(urlString) -> HTTP \(httpResponse.statusCode), Type: \(contentType)")
                }
            } catch {
                print("🎯 Go2RTC stream test \(camera): \(urlString) -> Failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getStatusText() -> String {
        if isLoading {
            return "Connecting..."
        } else if player != nil {
            return "Live • \(streamQuality.displayName)"
        } else if errorMessage != nil {
            return "Snapshots"
        } else {
            return "Offline"
        }
    }
}

// MARK: - Snapshot Fallback View

struct SnapshotFeedView: View {
    let camera: String
    let baseURL: String
    @State private var snapshotImage: UIImage?
    @State private var lastUpdate = Date()
    @State private var updateTimer: Timer?
    
    var body: some View {
        ZStack {
            Color.black
                .aspectRatio(16/9, contentMode: .fit)
            
            if let image = snapshotImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .transition(.opacity)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("Loading snapshot...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Update indicator
            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("SNAPSHOT MODE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text(timeAgo(from: lastUpdate))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(6)
                }
                Spacer()
            }
        }
        .onAppear {
            startSnapshotUpdates()
        }
        .onDisappear {
            stopSnapshotUpdates()
        }
    }
    
    private func startSnapshotUpdates() {
        // Initial load
        loadSnapshot()
        
        // Update every 5 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            loadSnapshot()
        }
    }
    
    private func stopSnapshotUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func loadSnapshot() {
        let liveFeedClient = LiveFeedAPIClient(baseURL: baseURL)
        
        // Try primary snapshot URL first
        if let snapshotURL = liveFeedClient.getSnapshotURL(for: camera) {
            trySnapshotURL(snapshotURL)
            return
        }
        
        // If primary fails, try alternatives
        let alternativeURLs = liveFeedClient.getAlternativeSnapshotURLs(for: camera)
        for url in alternativeURLs {
            trySnapshotURL(url)
            return // Try one at a time
        }
    }
    
    private func trySnapshotURL(_ url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Snapshot failed for \(url): \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ Snapshot HTTP error for \(url): \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return
            }
            
            guard let data = data,
                  let image = UIImage(data: data) else {
                print("❌ Invalid image data from \(url)")
                return
            }
            
            print("✅ Snapshot loaded from \(url)")
            
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.snapshotImage = image
                    self.lastUpdate = Date()
                }
            }
        }.resume()
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 10 {
            return "Just now"
        } else if seconds < 60 {
            return "\(seconds)s ago"
        } else {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        }
    }
}

struct CameraFeedCard_Previews: PreviewProvider {
    static var previews: some View {
        CameraFeedCard(camera: "front_door", baseURL: "http://192.168.1.100:5000")
            .padding()
            .background(Color.black)
    }
}
