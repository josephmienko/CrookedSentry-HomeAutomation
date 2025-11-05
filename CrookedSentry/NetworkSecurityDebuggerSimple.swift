//
//  NetworkSecurityDebuggerSimple.swift
//  CrookedSentry
//
//  iOS-Compatible Network Security Debugger
//  Created by Assistant on 2025
//

import Foundation
import SwiftUI
import Network
import Combine

class NetworkSecurityDebuggerSimple: ObservableObject {
    static let shared = NetworkSecurityDebuggerSimple()
    
    @Published var debugResults: [String] = []
    @Published var isDebugging = false
    
    private init() {}
    
    func performBasicSecurityCheck() async {
        await MainActor.run {
            isDebugging = true
            debugResults.removeAll()
            debugResults.append("🔍 Starting security investigation...")
        }
        
        // Basic VPN check
        let vpnStatus = checkBasicVPNStatus()
        await MainActor.run {
            debugResults.append("🔐 VPN Status: \(vpnStatus)")
        }
        
        // Network type check
        let networkType = checkNetworkType()
        await MainActor.run {
            debugResults.append("📡 Network Type: \(networkType)")
        }
        
        // Service connectivity test
        let serviceStatus = await testServiceConnectivity()
        await MainActor.run {
            debugResults.append("🌐 Service Access: \(serviceStatus)")
        }
        
        await MainActor.run {
            isDebugging = false
            debugResults.append("✅ Investigation complete")
        }
    }
    
    private func checkBasicVPNStatus() -> String {
        let vpnManager = VPNManager.shared
        
        if vpnManager.connectionState.isActive {
            return "App VPN Connected"
        } else if vpnManager.deviceVPNActive {
            return "System VPN Detected"
        } else {
            return "No VPN Connection"
        }
    }
    
    private func checkNetworkType() -> String {
        // Basic network type detection
        let vpnManager = VPNManager.shared
        
        if vpnManager.isOnSecureNetwork {
            return "Secure/Local Network"
        } else {
            return "External Network"
        }
    }
    
    private func testServiceConnectivity() async -> String {
        let settingsStore = SettingsStore()
        let testURL = "\(settingsStore.frigateBaseURL)/api/version"
        
        do {
            guard let url = URL(string: testURL) else {
                return "❌ Invalid URL"
            }
            
            let (_, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    return "✅ Service Accessible (HTTP \(httpResponse.statusCode))"
                } else {
                    return "⚠️ Service Error (HTTP \(httpResponse.statusCode))"
                }
            } else {
                return "❌ Invalid Response"
            }
        } catch {
            return "❌ Connection Failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Simple UI Component

struct NetworkSecurityDebugViewSimple: View {
    @StateObject private var debugger = NetworkSecurityDebuggerSimple.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Network Security Investigation")
                .font(.title2)
                .fontWeight(.bold)
            
            // Debug button
            Button(action: {
                Task {
                    await debugger.performBasicSecurityCheck()
                }
            }) {
                HStack {
                    if debugger.isDebugging {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "shield.lefthalf.filled")
                    }
                    Text(debugger.isDebugging ? "Investigating..." : "Start Security Investigation")
                }
                .foregroundColor(.white)
                .padding()
                .background(debugger.isDebugging ? Color.orange : Color.red)
                .cornerRadius(8)
            }
            .disabled(debugger.isDebugging)
            
            // Results
            if !debugger.debugResults.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Investigation Results:")
                        .font(.headline)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(debugger.debugResults.indices, id: \.self) { index in
                                Text(debugger.debugResults[index])
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}