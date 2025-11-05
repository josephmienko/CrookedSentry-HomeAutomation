//
//  EventsDebugHelper.swift
//  CrookedSentry
//
//  Events Feed Debugging Helper
//  Created by Assistant on 2025
//

import Foundation

class EventsDebugHelper {
    static func testEventAPIConnectivity(baseURL: String) async {
        print("🔍 Testing Events API Connectivity...")
        print("🔍 Base URL: \(baseURL)")
        
        // Test endpoints
        let endpoints = [
            "/api/version",
            "/api/events?limit=1",
            "/api/events?limit=1&in_progress=0",
            "/api/events?limit=1&in_progress=1"
        ]
        
        for endpoint in endpoints {
            guard let url = URL(string: "\(baseURL)\(endpoint)") else {
                print("❌ Invalid URL: \(baseURL)\(endpoint)")
                continue
            }
            
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("✅ \(endpoint) -> HTTP \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 200 {
                        if let responseString = String(data: data, encoding: .utf8) {
                            let preview = String(responseString.prefix(200))
                            print("   📄 Response preview: \(preview)...")
                        }
                        print("   📊 Response size: \(data.count) bytes")
                    } else {
                        if let errorString = String(data: data, encoding: .utf8) {
                            print("   ❌ Error response: \(errorString)")
                        }
                    }
                } else {
                    print("❌ \(endpoint) -> Invalid HTTP response")
                }
            } catch {
                print("❌ \(endpoint) -> Network error: \(error.localizedDescription)")
            }
        }
    }
    
    static func testEventsParsing(baseURL: String) async {
        print("🔍 Testing Events Parsing...")
        
        guard let url = URL(string: "\(baseURL)/api/events?limit=5") else {
            print("❌ Invalid events URL")
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ API request failed")
                return
            }
            
            print("✅ Got events data (\(data.count) bytes)")
            
            // Try to parse as JSON array
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    print("✅ Successfully parsed as JSON array with \(jsonArray.count) events")
                    
                    // Check first event structure
                    if let firstEvent = jsonArray.first {
                        print("📋 First event keys: \(Array(firstEvent.keys).sorted())")
                        
                        // Check required fields
                        let requiredFields = ["id", "camera", "label", "start_time"]
                        for field in requiredFields {
                            if firstEvent[field] != nil {
                                print("   ✅ Has \(field)")
                            } else {
                                print("   ❌ Missing \(field)")
                            }
                        }
                    }
                } else if let jsonDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("📋 Response is a dictionary with keys: \(Array(jsonDict.keys).sorted())")
                } else {
                    print("❌ Unexpected JSON structure")
                }
            } catch {
                print("❌ JSON parsing error: \(error)")
                
                // Show raw response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Raw response: \(String(responseString.prefix(500)))")
                }
            }
            
            // Try using the actual FrigateEvent decoder
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                let events = try decoder.decode([FrigateEvent].self, from: data)
                print("✅ Successfully decoded \(events.count) FrigateEvent objects")
                
                if let firstEvent = events.first {
                    print("   📋 First event: ID=\(firstEvent.id), Camera=\(firstEvent.camera), Label=\(firstEvent.label)")
                }
            } catch {
                print("❌ FrigateEvent decoding error: \(error)")
            }
            
        } catch {
            print("❌ Network error: \(error)")
        }
    }
    
    static func checkAppSettings() {
        print("🔍 Checking App Settings...")
        
        let frigateURL = UserDefaults.standard.string(forKey: "frigateBaseURL") ?? "Not set"
        print("📋 Stored Frigate URL: \(frigateURL)")
        
        let selectedCameras = UserDefaults.standard.array(forKey: "selectedCameras") as? [String] ?? []
        print("📋 Selected Cameras: \(selectedCameras)")
        
        let selectedLabels = UserDefaults.standard.array(forKey: "selectedLabels") as? [String] ?? []
        print("📋 Selected Labels: \(selectedLabels)")
        
        let selectedZones = UserDefaults.standard.array(forKey: "selectedZones") as? [String] ?? []
        print("📋 Selected Zones: \(selectedZones)")
        
        // Check for any stored error times
        if let lastErrorTime = UserDefaults.standard.object(forKey: "lastNetworkErrorTime") as? Date {
            print("⚠️ Last network error: \(lastErrorTime)")
        }
    }
}

// MARK: - Debug Extension for ContentView
extension ContentView {
    func debugEventsFeed() async {
        print("🚀 Starting Events Feed Debug...")
        
        EventsDebugHelper.checkAppSettings()
        
        await EventsDebugHelper.testEventAPIConnectivity(baseURL: settingsStore.frigateBaseURL)
        
        await EventsDebugHelper.testEventsParsing(baseURL: settingsStore.frigateBaseURL)
        
        print("🏁 Events Feed Debug Complete")
    }
}