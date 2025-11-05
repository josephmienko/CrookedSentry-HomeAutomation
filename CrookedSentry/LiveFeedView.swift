//
//  LiveFeedView.swift
//  ccCCTV
//
//  Created by Assistant on 2025
//

import SwiftUI
import AVKit

struct LiveFeedView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @StateObject private var liveFeedClient: LiveFeedAPIClient
    @State private var availableCameras: [String] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var refreshId = UUID()
    
    init() {
        _liveFeedClient = StateObject(wrappedValue: LiveFeedAPIClient(baseURL: ""))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ZStack {
                        Color.background
                            .edgesIgnoringSafeArea(.all)
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.primary)
                            Text("Loading camera feeds...")
                                .foregroundColor(.onSurface)
                        }
                    }
                } else if let errorMessage = errorMessage {
                    ZStack {
                        Color.background
                            .edgesIgnoringSafeArea(.all)
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.error)
                            
                            Text("Connection Error")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.onSurface)
                            
                            Text(errorMessage)
                                .font(.body)
                                .foregroundColor(.onSurfaceVariant)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button("Retry") {
                                Task { await loadCameras() }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.primary)
                            .foregroundColor(.onPrimary)
                            .cornerRadius(8)
                        }
                    }
                } else if availableCameras.isEmpty {
                    ZStack {
                        Color.background
                            .edgesIgnoringSafeArea(.all)
                        VStack(spacing: 20) {
                            Image(systemName: "video.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.onSurfaceVariant)
                            
                            Text("No Cameras Found")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.onSurface)
                            
                            Text("Make sure your Frigate server is running and cameras are configured.")
                                .font(.body)
                                .foregroundColor(.onSurfaceVariant)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button("Refresh") {
                                Task { await loadCameras() }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.primary)
                            .foregroundColor(.onPrimary)
                            .cornerRadius(8)
                        }
                    }
                } else {
                    // Camera feeds
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(availableCameras, id: \.self) { camera in
                                CameraFeedCard(camera: camera, baseURL: settingsStore.frigateBaseURL)
                                    .environmentObject(settingsStore)
                                    .id("\(camera)_\(refreshId)")
                            }
                        }
                        .padding()
                    }
                    .background(Color.background)
                    .applyRefreshable {
                        await refreshFeeds()
                    }
                }
            }
            .background(Color.background)
            #if !targetEnvironment(macCatalyst)
            .navigationTitle("Live Cameras")
            #endif
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: connectionStatusView,
                trailing: HStack(spacing: 16) {
                    Button(action: {
                        Task { await refreshFeeds() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.primary)
                    }
                }
            )
        }
        .navigationViewStyle(.stack)
        .onAppear {
            setupLiveFeedClient()
            Task { await loadCameras() }
        }
    }
    
    // MARK: - Connection Status Indicator
    
    private var connectionStatusView: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(getConnectionColor())
                .frame(width: 8, height: 8)
            
            Text(getConnectionStatus())
                .font(.caption)
                .foregroundColor(.onSurfaceVariant)
        }
    }
    
    private func getConnectionColor() -> Color {
        if isLoading {
            return .tertiary
        } else if errorMessage != nil {
            return .error
        } else if !availableCameras.isEmpty {
            return .primary
        } else {
            return .onSurfaceVariant
        }
    }
    
    private func getConnectionStatus() -> String {
        if isLoading {
            return "Connecting..."
        } else if errorMessage != nil {
            return "Offline"
        } else if !availableCameras.isEmpty {
            return "Online"
        } else {
            return "No Cameras"
        }
    }
    
    // MARK: - Data Loading
    
    private func setupLiveFeedClient() {
        liveFeedClient.baseURL = settingsStore.frigateBaseURL
        liveFeedClient.updateCredentials(
            username: settingsStore.cameraUsername,
            password: settingsStore.cameraPassword
        )
    }
    
    private func loadCameras() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        setupLiveFeedClient()
        
        do {
            let cameras = try await liveFeedClient.fetchAvailableCameras()
            
            await MainActor.run {
                self.availableCameras = cameras
                self.isLoading = false
                print("📹 Loaded \(cameras.count) cameras: \(cameras)")
            }
        } catch {
            // Fallback to hardcoded camera names if API fails
            await MainActor.run {
                // Use common camera names that should work with your setup
                self.availableCameras = ["backyard", "cam1", "camera_1", "camera_2"]
                self.errorMessage = "Using fallback cameras (API connection failed: \(error.localizedDescription))"
                self.isLoading = false
                print("❌ API failed, using fallback cameras: \(self.availableCameras)")
            }
        }
    }
    
    private func refreshFeeds() async {
        // Force refresh all camera feeds
        await MainActor.run {
            refreshId = UUID()
        }
        
        // Reload camera list
        await loadCameras()
    }
}

// MARK: - Backward-compat helpers

private extension View {
    // Apply refreshable only where available; otherwise return the view unchanged.
    func applyRefreshable(_ action: @escaping () async -> Void) -> some View {
        if #available(iOS 15.0, macOS 12.0, *) {
            return AnyView(self.refreshable { await action() })
        } else {
            return AnyView(self)
        }
    }
}

struct LiveFeedView_Previews: PreviewProvider {
    static var previews: some View {
        let settingsStore = SettingsStore()
        
        Group {
            LiveFeedView()
                .environmentObject(settingsStore)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            LiveFeedView()
                .environmentObject(settingsStore)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
