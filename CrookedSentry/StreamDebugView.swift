//
//  StreamDebugView.swift
//  ccCCTV
//
//  Created by Assistant on 2025
//

import SwiftUI

struct StreamDebugView: View {
    let camera: String
    let baseURL: String
    @State private var debugResults: [(url: String, status: Int, contentType: String?)] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Testing endpoints...")
                        .padding()
                } else {
                    List(debugResults, id: \.url) { result in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(result.url)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Circle()
                                    .fill(result.status == 200 ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                            }
                            
                            HStack {
                                Text("Status: \(result.status)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                if let contentType = result.contentType {
                                    Text("Type: \(contentType)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                Button("Test All Endpoints") {
                    Task { await runDiagnostics() }
                }
                .padding()
                .disabled(isLoading)
            }
            .navigationTitle("Debug: \(camera)")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            Task { await runDiagnostics() }
        }
    }
    
    private func runDiagnostics() async {
        await MainActor.run {
            isLoading = true
            debugResults = []
        }
        
        let liveFeedClient = LiveFeedAPIClient(baseURL: baseURL)
        let results = await liveFeedClient.diagnoseStreamingEndpoints(for: camera)
        
        await MainActor.run {
            self.debugResults = results
            self.isLoading = false
        }
    }
}

struct StreamDebugView_Previews: PreviewProvider {
    static var previews: some View {
        StreamDebugView(camera: "test", baseURL: "http://192.168.1.100:5000")
    }
}