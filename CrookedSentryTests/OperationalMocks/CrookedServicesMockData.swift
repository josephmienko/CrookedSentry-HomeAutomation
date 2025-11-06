//
//  CrookedServicesMockData.swift
//  CrookedSentryTests
//
//  Auto-generated from operational mock infrastructure
//  Ensures iOS tests use identical responses to operational scripts
//

import Foundation

/// Operational mock data matching the packaged infrastructure exactly
/// This ensures consistency between Python operational mocks and iOS testing
struct CrookedServicesMockData {
    
    // MARK: - Mock Modes (matching operational infrastructure)
    
    enum MockMode: String, CaseIterable {
        case healthy = "healthy"       // All services running normally
        case degraded = "degraded"     // Some services failing/warnings
        case offline = "offline"       // Complete system outage  
        case testing = "testing"       // Predictable test environment
    }
    
    static var currentMode: MockMode = .healthy
    
    // MARK: - API Response Data (matching operational JSON exactly)
    
    /// Frigate API responses matching operational mock-curl.py
    static let frigateAPIResponses: [MockMode: [String: MockAPIResponse]] = [
        .healthy: [
            "/api/version": MockAPIResponse(
                statusCode: 200,
                data: """
                {
                  "version": "0.13.2",
                  "api_version": "1.0",
                  "commit": "abc123def456",
                  "build_date": "2024-01-15T10:30:00Z"
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json", "Server": "nginx/1.18.0"]
            ),
            "/api/config": MockAPIResponse(
                statusCode: 200,
                data: """
                {
                  "cameras": {
                    "backyard": {
                      "name": "backyard",
                      "enabled": true,
                      "width": 1920,
                      "height": 1080,
                      "fps": 15,
                      "detect": {
                        "enabled": true,
                        "width": 640,
                        "height": 480
                      },
                      "zones": {
                        "driveway": {
                          "coordinates": [0, 461, 417, 461, 417, 0, 0, 0]
                        }
                      }
                    },
                    "cam1": {
                      "name": "cam1", 
                      "enabled": true,
                      "width": 1920,
                      "height": 1080,
                      "fps": 15,
                      "detect": {
                        "enabled": true,
                        "width": 640,
                        "height": 480
                      }
                    }
                  },
                  "detectors": {
                    "coral": {
                      "type": "edgetpu",
                      "device": "usb"
                    }
                  }
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            ),
            "/api/events": MockAPIResponse(
                statusCode: 200,
                data: """
                [
                  {
                    "id": "1699142400.123456-abc123",
                    "camera": "backyard",
                    "label": "person",
                    "start_time": 1699142400.123456,
                    "end_time": 1699142460.789012,
                    "has_clip": true,
                    "has_snapshot": true,
                    "zones": ["driveway"],
                    "thumbnail": "/api/events/1699142400.123456-abc123/thumbnail.jpg",
                    "data": {
                      "score": 0.85,
                      "top_score": 0.92,
                      "type": "object",
                      "region": [320, 240, 80, 120],
                      "box": [340, 260, 40, 80]
                    }
                  },
                  {
                    "id": "1699142300.654321-def456", 
                    "camera": "cam1",
                    "label": "car",
                    "start_time": 1699142300.654321,
                    "end_time": 1699142320.987654,
                    "has_clip": false,
                    "has_snapshot": true,
                    "zones": [],
                    "thumbnail": "/api/events/1699142300.654321-def456/thumbnail.jpg",
                    "data": {
                      "score": 0.72,
                      "top_score": 0.78,
                      "type": "object",
                      "region": [160, 120, 100, 150],
                      "box": [180, 140, 60, 110]
                    }
                  }
                ]
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            ),
            "/api/stats": MockAPIResponse(
                statusCode: 200,
                data: """
                {
                  "detection_fps": 12.5,
                  "detectors": {
                    "coral": {
                      "detection_start": 1699142400.0,
                      "inference_speed": 8.2,
                      "pid": 1234
                    }
                  },
                  "cameras": {
                    "backyard": {
                      "camera_fps": 15.0,
                      "capture_pid": 5678,
                      "detection_fps": 5.2,
                      "pid": 9012,
                      "process_fps": 15.0,
                      "skipped_fps": 0.0
                    },
                    "cam1": {
                      "camera_fps": 15.0,
                      "capture_pid": 3456,
                      "detection_fps": 4.8,
                      "pid": 7890,
                      "process_fps": 15.0,
                      "skipped_fps": 0.0
                    }
                  }
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            )
        ],
        
        .degraded: [
            "/api/version": MockAPIResponse(
                statusCode: 200,
                data: """
                {
                  "version": "0.13.2",
                  "api_version": "1.0",
                  "commit": "abc123def456",
                  "build_date": "2024-01-15T10:30:00Z",
                  "warnings": ["High CPU usage detected", "Camera cam1 intermittent"]
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            ),
            "/api/stats": MockAPIResponse(
                statusCode: 200,
                data: """
                {
                  "detection_fps": 8.1,
                  "detectors": {
                    "coral": {
                      "detection_start": 1699142400.0,
                      "inference_speed": 12.8,
                      "pid": 1234
                    }
                  },
                  "cameras": {
                    "backyard": {
                      "camera_fps": 12.3,
                      "capture_pid": 5678,
                      "detection_fps": 3.2,
                      "pid": 9012,
                      "process_fps": 12.3,
                      "skipped_fps": 2.7
                    },
                    "cam1": {
                      "camera_fps": 6.8,
                      "capture_pid": 3456,
                      "detection_fps": 1.8,
                      "pid": 7890,
                      "process_fps": 6.8,
                      "skipped_fps": 8.2
                    }
                  }
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            )
        ],
        
        .offline: [
            "/api/version": MockAPIResponse(
                statusCode: 503,
                data: """
                {
                  "error": "Service Unavailable",
                  "message": "Frigate service is not responding"
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            ),
            "/api/config": MockAPIResponse(
                statusCode: 503,
                data: """
                {
                  "error": "Service Unavailable",
                  "message": "Frigate service is not responding"
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            ),
            "/api/events": MockAPIResponse(
                statusCode: 503,
                data: """
                {
                  "error": "Service Unavailable",
                  "message": "Frigate service is not responding"
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            ),
            "/api/stats": MockAPIResponse(
                statusCode: 503,
                data: """
                {
                  "error": "Service Unavailable",
                  "message": "Frigate service is not responding"
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            )
        ],
        
        .testing: [
            "/api/version": MockAPIResponse(
                statusCode: 200,
                data: """
                {
                  "version": "0.13.2-test",
                  "api_version": "1.0",
                  "commit": "test123test456",
                  "build_date": "2024-01-01T00:00:00Z",
                  "test_mode": true
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            ),
            "/api/config": MockAPIResponse(
                statusCode: 200,
                data: """
                {
                  "cameras": {
                    "backyard": {
                      "name": "backyard",
                      "enabled": true,
                      "test_mode": true
                    }
                  },
                  "test_mode": true
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            ),
            "/api/events": MockAPIResponse(
                statusCode: 200,
                data: """
                [
                  {
                    "id": "test-event-predictable-001",
                    "camera": "backyard",
                    "label": "person",
                    "start_time": 1704067200.0,
                    "end_time": 1704067260.0,
                    "has_clip": true,
                    "has_snapshot": true,
                    "zones": ["driveway"],
                    "thumbnail": "/api/events/test-event-predictable-001/thumbnail.jpg",
                    "data": {
                      "score": 0.90,
                      "top_score": 0.95,
                      "type": "object",
                      "region": [300, 200, 100, 150],
                      "box": [320, 220, 60, 110]
                    }
                  }
                ]
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            ),
            "/api/stats": MockAPIResponse(
                statusCode: 200,
                data: """
                {
                  "detection_fps": 15.0,
                  "test_mode": true,
                  "detectors": {
                    "coral": {
                      "detection_start": 1704067200.0,
                      "inference_speed": 5.0,
                      "pid": 9999
                    }
                  }
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            )
        ]
    ]
    
    /// Home Assistant API responses matching operational mocks
    static let homeAssistantAPIResponses: [MockMode: [String: MockAPIResponse]] = [
        .healthy: [
            "/api/": MockAPIResponse(
                statusCode: 200,
                data: """
                {
                  "message": "API running.",
                  "version": "2023.11.3"
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json", "Server": "Python/3.11 aiohttp/3.8.6"]
            ),
            "/api/config": MockAPIResponse(
                statusCode: 200,
                data: """
                {
                  "components": ["automation", "camera", "climate", "light", "sensor"],
                  "config_dir": "/config",
                  "elevation": 123,
                  "latitude": 40.7128,
                  "longitude": -74.0060,
                  "location_name": "Home",
                  "time_zone": "America/New_York",
                  "unit_system": {
                    "length": "km",
                    "mass": "kg",
                    "temperature": "°C",
                    "volume": "L"
                  },
                  "version": "2023.11.3",
                  "whitelist_external_dirs": ["/config/www"]
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            ),
            "/api/states": MockAPIResponse(
                statusCode: 200,
                data: """
                [
                  {
                    "entity_id": "camera.backyard",
                    "state": "streaming",
                    "attributes": {
                      "friendly_name": "Backyard Camera",
                      "supported_features": 2
                    },
                    "last_changed": "2024-01-15T10:30:00+00:00",
                    "last_updated": "2024-01-15T10:30:00+00:00"
                  },
                  {
                    "entity_id": "climate.thermostat",
                    "state": "heat",
                    "attributes": {
                      "current_temperature": 22.2,
                      "temperature": 23.0,
                      "friendly_name": "Thermostat"
                    },
                    "last_changed": "2024-01-15T09:15:00+00:00",
                    "last_updated": "2024-01-15T10:25:00+00:00"
                  }
                ]
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            )
        ],
        
        .degraded: [
            "/api/": MockAPIResponse(
                statusCode: 200,
                data: """
                {
                  "message": "API running (degraded).",
                  "warning": "Intermittent connectivity",
                  "version": "2023.11.3"
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            ),
            "/api/states": MockAPIResponse(
                statusCode: 200,
                data: """
                [
                  {
                    "entity_id": "camera.backyard",
                    "state": "unavailable",
                    "attributes": {
                      "friendly_name": "Backyard Camera",
                      "supported_features": 2,
                      "error": "Connection timeout"
                    },
                    "last_changed": "2024-01-15T10:30:00+00:00",
                    "last_updated": "2024-01-15T10:30:00+00:00"
                  }
                ]
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            )
        ],
        
        .offline: [
            "/api/": MockAPIResponse(
                statusCode: 503,
                data: """
                {
                  "error": "Service Unavailable",
                  "message": "Home Assistant is not responding"
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            ),
            "/api/config": MockAPIResponse(
                statusCode: 503,
                data: """
                {
                  "error": "Service Unavailable",
                  "message": "Home Assistant is not responding"
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            ),
            "/api/states": MockAPIResponse(
                statusCode: 503,
                data: """
                {
                  "error": "Service Unavailable",
                  "message": "Home Assistant is not responding"
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            )
        ],
        
        .testing: [
            "/api/": MockAPIResponse(
                statusCode: 200,
                data: """
                {
                  "message": "API running (test mode)",
                  "test_mode": true
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            ),
            "/api/config": MockAPIResponse(
                statusCode: 200,
                data: """
                {
                  "latitude": 37.7749,
                  "longitude": -122.4194,
                  "elevation": 0,
                  "unit_system": {
                    "length": "km",
                    "mass": "g",
                    "temperature": "°C",
                    "volume": "L"
                  },
                  "location_name": "Test Home",
                  "time_zone": "America/Los_Angeles",
                  "version": "2024.1.0-test",
                  "test_mode": true
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            ),
            "/api/states": MockAPIResponse(
                statusCode: 200,
                data: """
                [
                  {
                    "entity_id": "climate.living_room",
                    "state": "heat",
                    "attributes": {
                      "temperature": 21.0,
                      "current_temperature": 20.5,
                      "hvac_modes": ["heat", "cool", "off"],
                      "test_mode": true
                    },
                    "last_changed": "2024-01-01T00:00:00Z",
                    "last_updated": "2024-01-01T00:00:00Z"
                  },
                  {
                    "entity_id": "light.kitchen",
                    "state": "on",
                    "attributes": {
                      "brightness": 255,
                      "test_mode": true
                    },
                    "last_changed": "2024-01-01T00:00:00Z",
                    "last_updated": "2024-01-01T00:00:00Z"
                  }
                ]
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            )
        ]
    ]
    
    /// CrookedKeys API responses (matching operational infrastructure)
    static let crookedKeysAPIResponses: [MockMode: [String: MockAPIResponse]] = [
        .healthy: [
            "/whoami": MockAPIResponse(
                statusCode: 200,
                data: """
                {
                  "ip": "192.168.0.100",
                  "hostname": "iPhone-Test",
                  "vpn_detected": false,
                  "network": "local",
                  "timestamp": "2024-01-15T10:30:15Z",
                  "user_agent": "CrookedSentry/1.0 iOS/17.0"
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            ),
            "/network-info": MockAPIResponse(
                statusCode: 200,
                data: """
                {
                  "interfaces": {
                    "en0": {
                      "name": "WiFi",
                      "type": "wifi", 
                      "ip": "192.168.0.100",
                      "active": true
                    },
                    "pdp_ip0": {
                      "name": "Cellular",
                      "type": "cellular",
                      "active": false
                    }
                  },
                  "routing": {
                    "default_gateway": "192.168.0.1",
                    "dns_servers": ["192.168.0.1", "8.8.8.8"]
                  }
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            )
        ],
        
        .testing: [
            "/whoami": MockAPIResponse(
                statusCode: 200,
                data: """
                {
                  "ip": "10.0.0.100",
                  "hostname": "test-device",
                  "vpn_detected": true,
                  "network": "vpn",
                  "timestamp": "2024-01-01T12:00:00Z",
                  "user_agent": "CrookedSentry/1.0-test iOS/17.0",
                  "test_mode": true
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            ),
            "/network-info": MockAPIResponse(
                statusCode: 200,
                data: """
                {
                  "interfaces": {
                    "ipsec0": {
                      "name": "VPN",
                      "type": "vpn",
                      "active": true
                    }
                  },
                  "vpn_bypass_detected": true,
                  "local_services_accessible": true,
                  "security_risk": "HIGH",
                  "test_mode": true
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            )
        ],
        
        .offline: [
            // External diagnostic endpoints remain available even when VPN blocks local services
            "/whoami": MockAPIResponse(
                statusCode: 200,
                data: """
                {
                  "ip": "10.0.0.100",
                  "hostname": "test-device",
                  "vpn_detected": true,
                  "network": "vpn",
                  "timestamp": "2024-01-01T12:00:00Z",
                  "user_agent": "CrookedSentry/1.0-test iOS/17.0"
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            ),
            "/network-info": MockAPIResponse(
                statusCode: 200,
                data: """
                {
                  "interfaces": {
                    "ipsec0": {
                      "name": "VPN",
                      "type": "vpn",
                      "active": true
                    }
                  },
                  "routing": {
                    "default_gateway": "10.0.0.1",
                    "vpn_gateway": "10.0.0.1"
                  }
                }
                """.data(using: .utf8)!,
                headers: ["Content-Type": "application/json"]
            )
        ]
    ]
    
    // MARK: - SSH Command Responses (matching operational mock-ssh.py)
    
    static let sshCommandResponses: [MockMode: [String: SSHCommandResult]] = [
        .healthy: [
            "whoami": SSHCommandResult(exitCode: 0, stdout: "pi\n", stderr: "", executionTime: 0.1),
            "hostname": SSHCommandResult(exitCode: 0, stdout: "crookedservices.local\n", stderr: "", executionTime: 0.1),
            "uptime": SSHCommandResult(
                exitCode: 0, 
                stdout: " 10:30:15 up 7 days, 14:32,  1 user,  load average: 0.45, 0.52, 0.48\n", 
                stderr: "", 
                executionTime: 0.1
            ),
            "systemctl is-active docker": SSHCommandResult(exitCode: 0, stdout: "active\n", stderr: "", executionTime: 0.2),
            "systemctl is-active frigate": SSHCommandResult(exitCode: 0, stdout: "active\n", stderr: "", executionTime: 0.2),
            "systemctl is-active homeassistant": SSHCommandResult(exitCode: 0, stdout: "active\n", stderr: "", executionTime: 0.2),
            "docker ps --format 'table {{.Names}}\\t{{.Status}}'": SSHCommandResult(
                exitCode: 0,
                stdout: """
                NAMES\t\t\tSTATUS
                frigate\t\t\tUp 7 days
                homeassistant\t\tUp 7 days
                nginx\t\t\tUp 7 days
                
                """,
                stderr: "",
                executionTime: 0.4
            )
        ],
        
        .degraded: [
            "systemctl is-active frigate": SSHCommandResult(exitCode: 0, stdout: "active\n", stderr: "", executionTime: 0.2),
            "systemctl is-active homeassistant": SSHCommandResult(exitCode: 3, stdout: "failed\n", stderr: "", executionTime: 0.2),
            "docker ps --format 'table {{.Names}}\\t{{.Status}}'": SSHCommandResult(
                exitCode: 0,
                stdout: """
                NAMES\t\t\tSTATUS
                frigate\t\t\tUp 7 days
                homeassistant\t\tRestarting (1) 2 minutes ago
                nginx\t\t\tUp 7 days
                
                """,
                stderr: "",
                executionTime: 0.4
            )
        ],
        
        .offline: [
            "whoami": SSHCommandResult(exitCode: 255, stdout: "", stderr: "ssh: connect to host 192.168.0.200 port 22: Connection refused\n", executionTime: 5.0)
        ]
    ]
    
    // MARK: - Network Connectivity Results (matching operational mock-network.py)
    
    static let networkConnectivityResults: [MockMode: [String: NetworkConnectivityResult]] = [
        .healthy: [
            "192.168.0.200": NetworkConnectivityResult(
                isReachable: true,
                latency: 12.5,
                packetLoss: 0.0,
                error: nil
            ),
            "crookedservices.local": NetworkConnectivityResult(
                isReachable: true,
                latency: 15.2,
                packetLoss: 0.0,
                error: nil
            ),
            "8.8.8.8": NetworkConnectivityResult(
                isReachable: true,
                latency: 28.7,
                packetLoss: 0.0,
                error: nil
            )
        ],
        
        .degraded: [
            "192.168.0.200": NetworkConnectivityResult(
                isReachable: true,
                latency: 45.3,
                packetLoss: 15.0,
                error: "Intermittent connectivity"
            ),
            "crookedservices.local": NetworkConnectivityResult(
                isReachable: false,
                latency: nil,
                packetLoss: 100.0,
                error: "DNS resolution timeout"
            )
        ],
        
        .offline: [
      "192.168.0.200": NetworkConnectivityResult(
        isReachable: false,
        latency: nil,
        packetLoss: 100.0,
        error: "Network unreachable"
      ),
      "crookedservices.local": NetworkConnectivityResult(
        isReachable: false,
        latency: nil,
        packetLoss: 100.0,
        error: "Network unreachable"
      )
        ],
        
        .testing: [
            "192.168.0.200": NetworkConnectivityResult(
                isReachable: true,
                latency: 10.0,
                packetLoss: 0.0,
                error: nil
            ),
            "crookedservices.local": NetworkConnectivityResult(
                isReachable: true,
                latency: 12.0,
                packetLoss: 0.0,
                error: nil
            ),
            "8.8.8.8": NetworkConnectivityResult(
                isReachable: true,
                latency: 25.0,
                packetLoss: 0.0,
                error: nil
            )
        ]
    ]
}

// MARK: - Supporting Data Structures

struct MockAPIResponse {
    let statusCode: Int
    let data: Data
    let headers: [String: String]
}

struct NetworkConnectivityResult {
    let isReachable: Bool
    let latency: Double?        // milliseconds
    let packetLoss: Double      // percentage 
    let error: String?
}

// MARK: - Mock Mode Management

extension CrookedServicesMockData {
    
    /// Switch to different operational mode for testing scenarios
    static func setMode(_ mode: MockMode) {
        currentMode = mode
        print("🎛️ Mock infrastructure switched to: \(mode.rawValue)")
    }
    
    /// Get API response for current mode and endpoint
    static func getAPIResponse(service: String, endpoint: String) -> MockAPIResponse? {
    // Try several common endpoint variants to be tolerant of trailing slashes
    // and root-path vs api-root differences used across tests.
    let normalized = endpoint.hasSuffix("/") && endpoint.count > 1 ? String(endpoint.dropLast()) : endpoint
    let variants = [endpoint, normalized, endpoint + "/", "/api" + endpoint, "/api" + normalized]

    func lookup(_ dict: [String: MockAPIResponse]?) -> MockAPIResponse? {
      guard let dict = dict else { return nil }
      for v in variants {
        if let resp = dict[v] { return resp }
      }
      return nil
    }

    switch service.lowercased() {
    case "frigate":
      return lookup(frigateAPIResponses[currentMode])
    case "homeassistant", "ha":
      return lookup(homeAssistantAPIResponses[currentMode])
    case "crookedkeys":
      return lookup(crookedKeysAPIResponses[currentMode])
    default:
      return nil
    }
    }
    
    /// Get SSH command response for current mode
    static func getSSHResponse(command: String) -> SSHCommandResult? {
        return sshCommandResponses[currentMode]?[command]
    }
    
    /// Get network connectivity result for current mode
    static func getNetworkResult(host: String) -> NetworkConnectivityResult? {
        return networkConnectivityResults[currentMode]?[host]
    }
}