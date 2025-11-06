# Operational Mock Integration Strategy

## 🎯 Overview
This document outlines the complete strategy for integrating your packaged operational mock infrastructure (`crooked-services-test-mocks-1.0.0.tar.gz`) with the iOS CrookedSentry app testing framework.

## 🏗️ Architecture

### Integration Components
```
CrookedSentryTests/OperationalMocks/
├── CrookedServicesMockData.swift        ← Mock data matching ops exactly  
├── CrookedServicesMockURLProtocol.swift ← Network interception system
├── CrookedServicesTestHelpers.swift     ← XCTest integration utilities
└── INTEGRATION_STRATEGY.md              ← This document
```

### Bridge Architecture
```
Operational Python Mocks  ←→  iOS URLProtocol System
        ↓                           ↓
  JSON Responses              Swift Mock Data
        ↓                           ↓  
   Test Scripts              iOS XCTest Framework
```

## 🔄 Mock Mode Mapping

Your operational infrastructure provides 4 modes, now mapped to iOS testing:

| Operational Mode | iOS Implementation | Use Case |
|-----------------|-------------------|----------|
| `healthy` | All services active, fast responses | Normal operation testing |
| `degraded` | Some failures, slow responses | Network issues, service degradation |
| `offline` | Complete outage, timeouts | VPN blocking, system failures |
| `testing` | Predictable data, VPN bypass scenarios | Automated testing, security investigation |

## 📡 API Response Consistency

### Frigate API Endpoints
- ✅ `/api/version` - Service version and build info
- ✅ `/api/config` - Camera configuration and zones
- ✅ `/api/events` - Event detection data with thumbnails
- ✅ `/api/stats` - Performance metrics and FPS data

### Home Assistant API Endpoints  
- ✅ `/api/` - Service health check
- ✅ `/api/config` - System configuration
- ✅ `/api/states` - Entity states (cameras, climate, etc.)

### CrookedKeys API Endpoints
- ✅ `/whoami` - Network identity and VPN detection
- ✅ `/network-info` - Interface and routing information

## 🖥️ SSH Command Consistency

### System Commands
- ✅ `whoami` - Current user identification
- ✅ `hostname` - System hostname  
- ✅ `uptime` - System uptime and load
- ✅ `uname -a` - Kernel and system info

### Service Management
- ✅ `systemctl is-active docker` - Docker service status
- ✅ `systemctl is-active frigate` - Frigate service status  
- ✅ `systemctl is-active homeassistant` - Home Assistant status
- ✅ `docker ps --format 'table {{.Names}}\t{{.Status}}'` - Container status

## 🌐 Network Connectivity Mapping

### Hosts Tested
- ✅ `192.168.0.200` - Primary Pi server
- ✅ `crookedservices.local` - DNS name resolution
- ✅ `8.8.8.8` - External connectivity verification

### Metrics Provided
- ✅ **Reachability**: Boolean connectivity status
- ✅ **Latency**: Round-trip time in milliseconds
- ✅ **Packet Loss**: Percentage packet loss
- ✅ **Error Messages**: Descriptive failure reasons

## 🔒 VPN Bypass Investigation

### Investigation Scenarios

#### Normal VPN Operation
```swift
// VPN active, local services properly blocked
CrookedServicesMockData.setMode(.offline)
// Results: Local APIs return 503, SSH fails, network unreachable
```

#### VPN Bypass Vulnerability  
```swift
// VPN active BUT local services remain accessible
CrookedServicesMockURLProtocol.simulateVPNBypassScenario()
// Results: Local APIs return 200, SSH succeeds, network accessible
```

#### Service Degradation
```swift  
// Mixed connectivity, some services failing
CrookedServicesMockData.setMode(.degraded)
// Results: Intermittent failures, high latency, packet loss
```

## 🧪 Test Implementation Strategy

### Phase 1: Base Integration (Immediate)
1. **Replace Existing Mocks**: Update current `MockNetworkInfrastructure.swift` to use operational data
2. **Enable URL Protocol**: Integrate `CrookedServicesMockURLProtocol` with existing tests
3. **Validate Consistency**: Run existing 240 test cases with operational mock data

### Phase 2: Enhanced Testing (Next Sprint)
1. **Multi-Mode Testing**: Test all scenarios across healthy/degraded/offline/testing modes  
2. **VPN Investigation**: Implement comprehensive VPN bypass vulnerability testing
3. **Performance Testing**: Use degraded mode to test app resilience under poor conditions

### Phase 3: CI/CD Integration (Future)
1. **Automated Validation**: Ensure operational mock changes don't break iOS tests
2. **Cross-Repo Sync**: Automated updates when operational mocks change
3. **Performance Benchmarking**: Track app performance across all mock modes

## 🛠️ Migration Guide

### Existing Test Updates
```swift
// BEFORE: Manual mock responses
class FrigateAPIClientTests: XCTestCase {
    func testGetVersion() {
        // Manual mock setup...
    }
}

// AFTER: Operational mock integration
class FrigateAPIClientTests: CrookedServicesTestCase {
    override var defaultMockMode: CrookedServicesMockData.MockMode { .healthy }
    
    func testGetVersion() {
        testFrigateAPI(endpoint: "/api/version")
        // Automatically uses operational mock data
    }
}
```

### New VPN Bypass Tests
```swift
func testVPNBypassVulnerability() {
    let investigation = performVPNBypassVulnerabilityTest()
    
    XCTAssertTrue(investigation.bypassDetected, "Should detect VPN bypass")
    XCTAssertEqual(investigation.securityRisk, "HIGH - VPN bypass vulnerability detected")
}
```

## 🎯 Benefits

### For iOS Development
- **Consistent Data**: Same responses between operational scripts and iOS tests
- **Multiple Scenarios**: Test app behavior under various network conditions  
- **No Dependencies**: Fast, reliable testing without real Pi infrastructure
- **Security Focus**: Comprehensive VPN bypass vulnerability investigation

### For Cross-Platform Consistency
- **Shared Infrastructure**: Both repos test against identical mock data
- **Reliable CI/CD**: No dependencies on actual Pi services
- **Faster Development**: Immediate feedback without network delays
- **Better Quality**: Catch integration issues early in development

## 🚀 Next Steps

1. **Extract Package**: `tar -xzf crooked-services-ios-integration.tar.gz`
2. **Review Integration**: Study the generated Swift files
3. **Test Compatibility**: Verify operational responses work with existing models
4. **Migrate Gradually**: Start with 2-3 test cases, then expand
5. **Validate Results**: Run full test suite to ensure compatibility

## 📊 Success Metrics

- ✅ **240+ Tests Pass**: All existing tests work with operational mock data
- ✅ **4 Mock Modes**: Tests run successfully in healthy/degraded/offline/testing modes
- ✅ **VPN Investigation**: Comprehensive bypass vulnerability detection
- ✅ **Performance**: Test execution time remains under 30 seconds
- ✅ **Consistency**: iOS and operational mocks return identical responses

---

*This integration ensures your iOS app tests use the same reliable, comprehensive mock infrastructure as your operational scripts, providing consistent testing experiences across the entire CrookedSentry ecosystem.* 🏠🔒