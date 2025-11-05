//
//  VPNComponents.swift
//  CrookedSentry
//
//  Material 3 VPN UI Components
//  Created by Assistant on 2025
//

import SwiftUI

// MARK: - VPN Status Indicator for Navigation Drawer

struct VPNStatusIndicator: View {
    @ObservedObject var vpnManager = VPNManager.shared
    
    var body: some View {
        HStack(spacing: 8) {
            // VPN Status Icon
            Image(systemName: vpnIconName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(vpnManager.connectionState.statusColor)
            
            // Status Text
            Text(vpnManager.connectionState.displayText)
                .font(.caption2)
                .foregroundColor(vpnManager.connectionState.statusColor)
            
            Spacer()
            
            // Connection Toggle (if not connecting/disconnecting)
            if case .connecting = vpnManager.connectionState {
                ProgressView()
                    .scaleEffect(0.6)
            } else if case .disconnecting = vpnManager.connectionState {
                ProgressView()
                    .scaleEffect(0.6)
            } else {
                Button(action: toggleConnection) {
                    Image(systemName: vpnManager.connectionState.isActive ? "stop.circle" : "play.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(vpnBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(vpnBorderColor, lineWidth: 1)
                )
        )
    }
    
    private var vpnIconName: String {
        switch vpnManager.connectionState {
        case .connected:
            return "lock.shield.fill"
        case .connecting, .disconnecting:
            return "lock.shield"
        case .disconnected:
            return "lock.shield"
        case .error:
            return "exclamationmark.shield"
        }
    }
    
    private var vpnBackgroundColor: Color {
        switch vpnManager.connectionState {
        case .connected:
            return Color.primaryContainer.opacity(0.3)
        case .error:
            return Color.errorContainer.opacity(0.3)
        default:
            return Color.surfaceContainer
        }
    }
    
    private var vpnBorderColor: Color {
        switch vpnManager.connectionState {
        case .connected:
            return Color.primary.opacity(0.5)
        case .error:
            return Color.error.opacity(0.5)
        default:
            return Color.outline.opacity(0.2)
        }
    }
    
    private func toggleConnection() {
        if vpnManager.connectionState.isActive {
            vpnManager.disconnect()
        } else {
            vpnManager.connect()
        }
    }
}

// MARK: - Security Gate Component

struct SecurityGate<Content: View>: View {
    let isSecureContentRequired: Bool
    let content: () -> Content
    
    @ObservedObject var vpnManager = VPNManager.shared
    @State private var showingVPNSetup = false
    @State private var isCheckingSecurityState = false
    
    private var securityMessage: String {
        if vpnManager.deviceVPNActive {
            return "Device VPN detected, but connection verification needed"
        } else if vpnManager.isOnSecureNetwork {
            return "Local network access detected, refreshing permissions"
        } else {
            return "Connect to VPN to access this feature securely"
        }
    }
    
    var body: some View {
        Group {
            if !isSecureContentRequired || vpnManager.isSecureMode {
                content()
            } else {
                VPNPromptView(
                    title: "Secure Connection Required",
                    message: securityMessage,
                    onConnect: {
                        // Always refresh security state first
                        isCheckingSecurityState = true
                        vpnManager.checkCurrentSecurityState()
                        
                        // Give it a moment to check
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isCheckingSecurityState = false
                            
                            // If still not secure, proceed with connection setup
                            if !vpnManager.isSecureMode {
                                if vpnManager.canAutoConnect() {
                                    vpnManager.connect()
                                } else {
                                    showingVPNSetup = true
                                }
                            }
                        }
                    },
                    isLoading: isCheckingSecurityState
                )
            }
        }
        .sheet(isPresented: $showingVPNSetup) {
            VPNSetupView()
        }
        .onAppear {
            // Always check security state when gate appears
            vpnManager.checkCurrentSecurityState()
        }
    }
}

// MARK: - VPN Prompt Component

struct VPNPromptView: View {
    let title: String
    let message: String
    let onConnect: () -> Void
    var isLoading: Bool = false
    
    @ObservedObject var vpnManager = VPNManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Security Icon
            Image(systemName: "lock.shield")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.primary)
            
            // Title and Message
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.onSurface)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Connection Status
            if case .connecting = vpnManager.connectionState {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Establishing secure connection...")
                        .font(.body)
                        .foregroundColor(.onSurfaceVariant)
                }
            } else if isLoading {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Checking security status...")
                        .font(.body)
                        .foregroundColor(.onSurfaceVariant)
                }
            }
            
            // Connect Button
            Button(action: onConnect) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.onPrimary)
                        Text("Checking...")
                    } else {
                        Image(systemName: "lock.shield.fill")
                        Text("Connect Securely")
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.onPrimary)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Color.primary)
                )
            }
            .disabled(isLoading || vpnManager.connectionState == .connecting)
            .buttonStyle(PlainButtonStyle())
            .disabled(vpnManager.connectionState == .connecting)
            .opacity(vpnManager.connectionState == .connecting ? 0.6 : 1.0)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surface)
                .shadow(color: Color.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 24)
    }
}

// MARK: - VPN Setup View

struct VPNSetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var vpnManager = VPNManager.shared
    
    @State private var serverEndpoint = ""
    @State private var adminPassword = ""
    @State private var isConnecting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 56, weight: .light))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        Text("Secure Access Setup")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.onSurface)
                        
                        Text("Connect to your CrookedKeys VPN server for secure access to your home automation system")
                            .font(.body)
                            .foregroundColor(.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 32)
                
                // CrookedKeys Onboarding Option
                VStack(spacing: 16) {
                    // Quick Setup Button
                    Button(action: openCrookedKeysOnboarding) {
                        HStack(spacing: 12) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 20))
                                .foregroundColor(.onPrimary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Quick Family Setup")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.onPrimary)
                                
                                Text("Use QR code for instant mobile setup")
                                    .font(.caption)
                                    .foregroundColor(.onPrimary.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 14))
                                .foregroundColor(.onPrimary.opacity(0.8))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.primary)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Status indicator
                    if vpnManager.crookedKeysAvailable {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.primary)
                                .font(.caption)
                            
                            Text("CrookedKeys service online")
                                .font(.caption)
                                .foregroundColor(.onSurfaceVariant)
                            
                            Spacer()
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.tertiary)
                                .font(.caption)
                            
                            Text("Service status: \(vpnManager.crookedKeysHealthStatus)")
                                .font(.caption)
                                .foregroundColor(.onSurfaceVariant)
                            
                            Spacer()
                        }
                    }
                    
                    // Divider
                    HStack {
                        VStack { Divider() }
                        Text("OR")
                            .font(.caption)
                            .foregroundColor(.onSurfaceVariant)
                            .padding(.horizontal, 12)
                        VStack { Divider() }
                    }
                    .padding(.vertical, 8)
                }
                
                // Manual Configuration Form
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Server Endpoint")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.onSurface)
                        
                        TextField("192.168.1.100 or your-domain.com", text: $serverEndpoint)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Admin Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.onSurface)
                        
                        SecureField("Enter admin password", text: $adminPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.horizontal, 24)
                
                // Connect Button
                Button(action: setupVPN) {
                    HStack {
                        if isConnecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .onPrimary))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "lock.shield.fill")
                        }
                        Text(isConnecting ? "Setting up..." : "Setup Secure Connection")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(canConnect ? Color.primary : Color.onSurface.opacity(0.3))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!canConnect || isConnecting)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Info Footer
                VStack(spacing: 8) {
                    Text("Your credentials are stored securely on device")
                        .font(.caption)
                        .foregroundColor(.onSurfaceVariant)
                    
                    Text("Need help? Contact your GI Jooooe! 🪖")
                        .font(.caption)
                        .foregroundColor(.onSurfaceVariant)
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 32)
            }
            .background(Color.background.ignoresSafeArea())
            .navigationBarTitle("VPN Setup", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            serverEndpoint = vpnManager.serverEndpoint
        }
    }
    
    private var canConnect: Bool {
        !serverEndpoint.isEmpty && !adminPassword.isEmpty
    }
    
    private func openCrookedKeysOnboarding() {
        guard let url = URL(string: VPNManager.CrookedKeysEndpoints.onboardingURL) else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func setupVPN() {
        isConnecting = true
        
        // Configure VPN
        vpnManager.configure(serverEndpoint: serverEndpoint)
        
        // TODO: Use actual CrookedKeys registration
        // For now, simulate setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            vpnManager.connect()
            isConnecting = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - VPN Settings Section

struct VPNSettingsSection: View {
    @ObservedObject var vpnManager = VPNManager.shared
    @State private var showingVPNSetup = false
    
    var body: some View {
        Section("Network & Security") {
            // VPN Status Row
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(vpnManager.connectionState.statusColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("VPN Connection")
                        .font(.body)
                    Text(vpnManager.connectionState.displayText)
                        .font(.caption)
                        .foregroundColor(.onSurfaceVariant)
                }
                
                Spacer()
                
                Button(vpnManager.connectionState.isActive ? "Disconnect" : "Connect") {
                    if vpnManager.connectionState.isActive {
                        vpnManager.disconnect()
                    } else if vpnManager.canAutoConnect() {
                        vpnManager.connect()
                    } else {
                        showingVPNSetup = true
                    }
                }
                .font(.body)
                .foregroundColor(.primary)
            }
            
            // VPN Configuration Row
            NavigationLink("VPN Configuration") {
                VPNConfigurationView()
            }
            
            // Security Features Toggle
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Require VPN for cameras", isOn: Binding(
                    get: { VPNFeatureFlags.vpnRequiredForCameras },
                    set: { _ in }  // TODO: Make this configurable
                ))
                
                Text("Automatically require VPN connection when accessing camera feeds")
                    .font(.caption)
                    .foregroundColor(.onSurfaceVariant)
            }
        }
        .sheet(isPresented: $showingVPNSetup) {
            VPNSetupView()
        }
    }
}

// MARK: - VPN Configuration Detail View

struct VPNConfigurationView: View {
    @ObservedObject var vpnManager = VPNManager.shared
    @State private var serverEndpoint = ""
    
    var body: some View {
        Form {
            Section("Server Configuration") {
                HStack {
                    Text("Endpoint")
                        .frame(width: 80, alignment: .leading)
                    TextField("Server IP or domain", text: $serverEndpoint)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            
            Section("Connection Info") {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(vpnManager.connectionState.displayText)
                        .foregroundColor(vpnManager.connectionState.statusColor)
                }
                
                HStack {
                    Text("CrookedKeys Service")
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(vpnManager.crookedKeysAvailable ? Color.primary : Color.error)
                            .frame(width: 6, height: 6)
                        
                        Text(vpnManager.crookedKeysHealthStatus)
                            .foregroundColor(vpnManager.crookedKeysAvailable ? Color.primary : Color.error)
                    }
                    .font(.caption)
                }
                
                if vpnManager.connectionState.isActive {
                    HStack {
                        Text("Connected Since")
                        Spacer()
                        Text("Just now")  // TODO: Add actual timestamp
                            .foregroundColor(.onSurfaceVariant)
                    }
                }
            }
            
            Section("CrookedKeys Family Setup") {
                Button(action: {
                    guard let url = URL(string: VPNManager.CrookedKeysEndpoints.onboardingURL) else { return }
                    UIApplication.shared.open(url)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "qrcode.viewfinder")
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Open Family Onboarding")
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Text("QR code setup for mobile devices")
                                .font(.caption)
                                .foregroundColor(.onSurfaceVariant)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.onSurfaceVariant)
                    }
                }
                
                if !vpnManager.crookedKeysAvailable {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.tertiary)
                            .font(.caption)
                        
                        Text("Service offline - manual setup only")
                            .font(.caption)
                            .foregroundColor(.onSurfaceVariant)
                    }
                }
            }
        }
        .navigationTitle("VPN Configuration")
        .navigationBarItems(
            trailing: Button("Save") {
                vpnManager.configure(serverEndpoint: serverEndpoint)
            }
        )
        .onAppear {
            serverEndpoint = vpnManager.serverEndpoint
        }
    }
}

