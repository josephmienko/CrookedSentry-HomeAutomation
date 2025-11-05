import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = 0

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
    }
    
    private func isVersionSupported(_ versionString: String) -> Bool {
        let components = versionString.components(separatedBy: ".")
        guard let major = Int(components.first ?? "0"),
              let minor = Int(components.count > 1 ? components[1] : "0") else {
            return false
        }
        
        // Support Frigate v0.12.x and later
        if major == 0 && minor >= 12 {
            return true
        }
        
        // Support Frigate v1.0.0 and later
        if major >= 1 {
            return true
        }
        
        return false
    }
    
    private func getCompatibilityStatus(_ versionString: String) -> (status: String, color: Color) {
        let components = versionString.components(separatedBy: ".")
        guard let major = Int(components.first ?? "0"),
              let minor = Int(components.count > 1 ? components[1] : "0") else {
            return ("Unknown", .gray)
        }
        
        // Fully supported versions
        if (major == 0 && minor >= 13) || major >= 1 {
            return ("Fully Supported", .green)
        }
        
        // Limited support for older versions
        if major == 0 && minor >= 12 {
            return ("Limited Support", .orange)
        }
        
        // Unsupported versions
        return ("Unsupported", .red)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Settings Category", selection: $selectedTab) {
                    Text("CCTV").tag(0)
                    Text("Network").tag(1)
                    Text("About").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    // CCTV Settings Tab
                    CCTVSettingsTab()
                        .environmentObject(settingsStore)
                        .tag(0)
                    
                    // Network & VPN Settings Tab  
                    NetworkSettingsTab()
                        .environmentObject(settingsStore)
                        .tag(1)
                    
                    // About Tab
                    AboutSettingsTab(appVersion: appVersion, appBuild: appBuild)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Color.background)
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.blue))
        }
    }
}

// MARK: - CCTV Settings Tab

struct CCTVSettingsTab: View {
    @EnvironmentObject var settingsStore: SettingsStore
    
    var body: some View {
        Form {
            Section(header: Text("Frigate Server")) {
                TextField("Base URL", text: $settingsStore.frigateBaseURL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            Section(header: Text("Label Filter")) {
                if settingsStore.availableLabels.isEmpty {
                    Text("No labels found in recent events.")
                        .foregroundColor(.gray)
                } else {
                    List(settingsStore.availableLabels, id: \.self) { label in
                        Button(action: {
                            if settingsStore.selectedLabels.contains(label) {
                                settingsStore.selectedLabels.remove(label)
                            } else {
                                settingsStore.selectedLabels.insert(label)
                            }
                        }) {
                            HStack {
                                Text(label.toFriendlyName())
                                    .foregroundColor(.primary)
                                if settingsStore.selectedLabels.contains(label) {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }

            Section(header: Text("Zone Filter")) {
                if settingsStore.availableZones.isEmpty {
                    Text("No zones found in recent events.")
                        .foregroundColor(.gray)
                } else {
                    List(settingsStore.availableZones, id: \.self) { zone in
                        Button(action: {
                            if settingsStore.selectedZones.contains(zone) {
                                settingsStore.selectedZones.remove(zone)
                            } else {
                                settingsStore.selectedZones.insert(zone)
                            }
                        }) {
                            HStack {
                                Text(zone.toFriendlyName())
                                    .foregroundColor(.primary)
                                if settingsStore.selectedZones.contains(zone) {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }

            Section(header: Text("Camera Filter")) {
                if settingsStore.availableCameras.isEmpty {
                    Text("No cameras found. Pull to refresh on the main screen to populate this list.")
                        .foregroundColor(.gray)
                } else {
                    List(settingsStore.availableCameras, id: \.self) { camera in
                        Button(action: {
                            if settingsStore.selectedCameras.contains(camera) {
                                settingsStore.selectedCameras.remove(camera)
                            } else {
                                settingsStore.selectedCameras.insert(camera)
                            }
                        }) {
                            HStack {
                                Text(camera.toFriendlyName())
                                    .foregroundColor(.primary)
                                if settingsStore.selectedCameras.contains(camera) {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Live Feed Settings")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Default Stream Quality")
                        .font(.subheadline)
                    
                    Picker("Quality", selection: $settingsStore.defaultStreamQuality) {
                        Text("High Quality").tag("main")
                        Text("Low Quality").tag("sub")
                        Text("MJPEG").tag("mjpeg")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Toggle("Auto-expand camera feeds", isOn: $settingsStore.autoExpandFeeds)
                
                Text("Live feeds show real-time video from your cameras. Lower quality streams use less bandwidth and are recommended for mobile connections.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Section(header: Text("Camera IP Addresses")) {
                Text("Configure direct IP access for cameras when Frigate proxy fails")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                ForEach(settingsStore.availableCameras, id: \.self) { camera in
                    HStack {
                        Text(camera.toFriendlyName())
                            .frame(width: 100, alignment: .leading)
                        
                        TextField("IP Address", text: Binding(
                            get: { settingsStore.cameraIPAddresses[camera] ?? "" },
                            set: { settingsStore.cameraIPAddresses[camera] = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    }
                }
                
                if settingsStore.availableCameras.isEmpty {
                    Text("No cameras found. Pull to refresh on the main screen to populate camera list.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("Camera Authentication")) {
                HStack {
                    Text("Username")
                        .frame(width: 80, alignment: .leading)
                    TextField("Username", text: $settingsStore.cameraUsername)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                HStack {
                    Text("Password")
                        .frame(width: 80, alignment: .leading)
                    SecureField("Password", text: $settingsStore.cameraPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Text("Credentials for direct camera access when Frigate is unavailable")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Network Settings Tab

struct NetworkSettingsTab: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @ObservedObject var vpnManager = VPNManager.shared
    @State private var showingVPNSetup = false
    @State private var showingAdvancedSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // VPN Connection Card
                VPNConnectionCard()
                
                // Security Features Card  
                SecurityFeaturesCard()
                
                // Network Information Card
                NetworkInfoCard()
                
                // Quick Actions Card
                QuickActionsCard()
            }
            .padding(.horizontal, 16)
        }
        .sheet(isPresented: $showingVPNSetup) {
            VPNSetupView()
        }
        .sheet(isPresented: $showingAdvancedSettings) {
            VPNConfigurationView()
        }
    }
}

// MARK: - About Settings Tab

struct AboutSettingsTab: View {
    let appVersion: String
    let appBuild: String
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Image("CrookedSentryIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                        
                        VStack(spacing: 8) {
                            Text("CrookedSentry")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.onSurface)
                            
                            Text("CCTV Home Automation")
                                .font(.subheadline)
                                .foregroundColor(.onSurfaceVariant)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Version \(appVersion)")
                                .font(.body)
                                .foregroundColor(.onSurface)
                            
                            Text("Build \(appBuild)")
                                .font(.caption)
                                .foregroundColor(.onSurfaceVariant)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            }
            .listRowBackground(Color.clear)
            
            Section("Security & Debugging") {
                NavigationLink(destination: NetworkSecurityDebugViewSimple()) {
                    HStack {
                        Image(systemName: "shield.lefthalf.filled")
                            .foregroundColor(.red)
                        Text("Network Security Investigation")
                        Spacer()
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Section("Features") {
                FeatureRow(icon: "video.fill", title: "Real-time Events", description: "Monitor security events as they happen")
                FeatureRow(icon: "play.rectangle.fill", title: "Live Feeds", description: "Stream cameras in real-time")
                FeatureRow(icon: "lock.shield.fill", title: "Secure Access", description: "VPN-protected connections")
                FeatureRow(icon: "slider.horizontal.3", title: "Advanced Filtering", description: "Filter by labels, zones, and cameras")
            }
            
            Section("System") {
                InfoRow(label: "iOS Version", value: UIDevice.current.systemVersion)
                InfoRow(label: "Device Model", value: UIDevice.current.model)
                InfoRow(label: "Bundle ID", value: Bundle.main.bundleIdentifier ?? "Unknown")
            }
            
            Section("Acknowledgments") {
                Text("Built with SwiftUI and love for home automation enthusiasts.")
                    .font(.body)
                    .foregroundColor(.onSurfaceVariant)
                    .padding(.vertical, 8)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.onSurface)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.onSurfaceVariant)
            }
        }
        .padding(.vertical, 4)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.onSurfaceVariant)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.onSurface)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let settingsStore = SettingsStore()
        settingsStore.availableLabels = ["person", "car", "dog"]
        settingsStore.selectedLabels = ["person"]
        settingsStore.availableZones = ["porch", "driveway"]
        settingsStore.selectedZones = ["porch"]
        settingsStore.availableCameras = ["front_door", "driveway_camera", "wyze_camera"]
        settingsStore.selectedCameras = ["front_door"]

        return SettingsView()
            .environmentObject(settingsStore)
    }
}
