import Foundation
import Combine

class SettingsStore: ObservableObject {
    @Published var frigateBaseURL: String {
        didSet {
            UserDefaults.standard.set(frigateBaseURL, forKey: "frigateBaseURL")
        }
    }
    
    @Published var frigateVersion: String = "Unknown"

    @Published var availableLabels: [String] = []
    @Published var selectedLabels: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(selectedLabels), forKey: "selectedLabels")
        }
    }

    @Published var availableZones: [String] = []
    @Published var selectedZones: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(selectedZones), forKey: "selectedZones")
        }
    }

    @Published var availableCameras: [String] = ["backyard", "cam1"]
    @Published var selectedCameras: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(selectedCameras), forKey: "selectedCameras")
        }
    }

    // Live Feed Settings
    @Published var defaultStreamQuality: String {
        didSet {
            UserDefaults.standard.set(defaultStreamQuality, forKey: "defaultStreamQuality")
        }
    }
    
    @Published var autoExpandFeeds: Bool {
        didSet {
            UserDefaults.standard.set(autoExpandFeeds, forKey: "autoExpandFeeds")
        }
    }
    
    @Published var cameraIPAddresses: [String: String] {
        didSet {
            UserDefaults.standard.set(cameraIPAddresses, forKey: "cameraIPAddresses")
        }
    }
    
    @Published var cameraUsername: String {
        didSet {
            UserDefaults.standard.set(cameraUsername, forKey: "cameraUsername")
        }
    }
    
    @Published var cameraPassword: String {
        didSet {
            UserDefaults.standard.set(cameraPassword, forKey: "cameraPassword")
        }
    }

    init() {
        self.frigateBaseURL = UserDefaults.standard.string(forKey: "frigateBaseURL") ?? "http://192.168.0.200:5000"
        
        if let savedLabels = UserDefaults.standard.array(forKey: "selectedLabels") as? [String] {
            self.selectedLabels = Set(savedLabels)
        } else {
            self.selectedLabels = []
        }

        if let savedZones = UserDefaults.standard.array(forKey: "selectedZones") as? [String] {
            self.selectedZones = Set(savedZones)
        } else {
            self.selectedZones = []
        }

        if let savedCameras = UserDefaults.standard.array(forKey: "selectedCameras") as? [String] {
            self.selectedCameras = Set(savedCameras)
        } else {
            self.selectedCameras = []
        }
        
        // Initialize live feed settings
        self.defaultStreamQuality = UserDefaults.standard.string(forKey: "defaultStreamQuality") ?? "sub"
        self.autoExpandFeeds = UserDefaults.standard.bool(forKey: "autoExpandFeeds")
        
        // Initialize camera IP addresses with defaults
        if let savedIPs = UserDefaults.standard.dictionary(forKey: "cameraIPAddresses") as? [String: String] {
            self.cameraIPAddresses = savedIPs
        } else {
            // Set default IP for your specific cameras
            self.cameraIPAddresses = [
                "backyard": "192.168.0.210",  // First ANNKE camera
                "cam1": "192.168.0.211"       // Second ANNKE camera
            ]
        }
        
        // Initialize camera credentials
        self.cameraUsername = UserDefaults.standard.string(forKey: "cameraUsername") ?? "admin"
        self.cameraPassword = UserDefaults.standard.string(forKey: "cameraPassword") ?? "DavidAlan"
    }
    
    @MainActor
    func fetchFrigateVersion(apiClient: FrigateAPIClient) async {
        do {
            let version = try await apiClient.fetchVersion()
            self.frigateVersion = version
        } catch let apiError as FrigateAPIError {
            switch apiError {
            case .invalidURL:
                self.frigateVersion = "Error: Invalid URL"
            case .networkError(let error):
                self.frigateVersion = "Error: Network issue - \(error.localizedDescription)"
            case .invalidResponse:
                self.frigateVersion = "Error: Invalid response format"
            case .unsupportedVersion(let version):
                self.frigateVersion = "Error: Unsupported version \(version)"
            case .decodingError:
                self.frigateVersion = "Error: Could not decode version"
            }
        } catch {
            self.frigateVersion = "Error: \(error.localizedDescription)"
        }
    }
}
