import XCTest
@testable import CoreLogic

final class CoreLogicTests: XCTestCase {
    
    // MARK: - HTTPMethod Tests
    
    func testHTTPMethodRawValues() {
        XCTAssertEqual(HTTPMethod.GET.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.POST.rawValue, "POST")
        XCTAssertEqual(HTTPMethod.PUT.rawValue, "PUT")
        XCTAssertEqual(HTTPMethod.DELETE.rawValue, "DELETE")
        XCTAssertEqual(HTTPMethod.PATCH.rawValue, "PATCH")
    }
    
    func testHTTPMethodEquality() {
        XCTAssertEqual(HTTPMethod.GET, .GET)
        XCTAssertNotEqual(HTTPMethod.POST, .GET)
        XCTAssertEqual(HTTPMethod.DELETE, .DELETE)
    }
    
    func testHTTPMethodHashable() {
        let methods: Set<HTTPMethod> = [.GET, .POST, .GET, .PUT]
        XCTAssertEqual(methods.count, 3) // GET appears twice but Set deduplicates
    }
    
    // MARK: - Codec Tests
    
    func testBase64Encoding() {
        let original = "CrookedSentry:TestPassword123"
        let encoded = Codec.base64Encode(original)
        XCTAssertEqual(encoded, "Q3Jvb2tlZFNlbnRyeTpUZXN0UGFzc3dvcmQxMjM=")
    }
    
    func testBase64RoundTrip() {
        let original = "admin:secure_password"
        let encoded = Codec.base64Encode(original)
        let decoded = Codec.base64Decode(encoded)
        XCTAssertEqual(decoded, original)
    }
    
    func testBase64EmptyString() {
        let empty = ""
        let encoded = Codec.base64Encode(empty)
        let decoded = Codec.base64Decode(encoded)
        XCTAssertEqual(decoded, empty)
    }
    
    func testBase64SpecialCharacters() {
        let special = "user@example.com:p@ssw0rd!#$%^&*()"
        let encoded = Codec.base64Encode(special)
        let decoded = Codec.base64Decode(encoded)
        XCTAssertEqual(decoded, special)
    }
    
    func testBase64UnicodeSupport() {
        let unicode = "Hello 世界 🌍 Привет"
        let encoded = Codec.base64Encode(unicode)
        let decoded = Codec.base64Decode(encoded)
        XCTAssertEqual(decoded, unicode)
    }
    
    func testBase64LargeString() {
        let large = String(repeating: "A", count: 10000)
        let encoded = Codec.base64Encode(large)
        let decoded = Codec.base64Decode(encoded)
        XCTAssertEqual(decoded, large)
    }
    
    // MARK: - NetworkStatus Decoding Tests
    
    func testNetworkStatusDecoding() throws {
        let json = """
        {"network":"lan","ip":"192.168.0.100"}
        """.data(using: .utf8)!
        let status = try JSONDecoder.frigate.decode(NetworkStatus.self, from: json)
        XCTAssertEqual(status, NetworkStatus(network: .lan, ip: "192.168.0.100"))
    }
    
    func testNetworkStatusLANNetwork() throws {
        let json = """
        {"network":"lan","ip":"10.0.0.50"}
        """.data(using: .utf8)!
        let status = try JSONDecoder.frigate.decode(NetworkStatus.self, from: json)
        XCTAssertEqual(status.network, .lan)
        XCTAssertEqual(status.ip, "10.0.0.50")
    }
    
    func testNetworkStatusVPNNetwork() throws {
        let json = """
        {"network":"vpn","ip":"10.8.0.2"}
        """.data(using: .utf8)!
        let status = try JSONDecoder.frigate.decode(NetworkStatus.self, from: json)
        XCTAssertEqual(status.network, .vpn)
        XCTAssertEqual(status.ip, "10.8.0.2")
    }
    
    // MARK: - Integration Tests
    
    func testHTTPMethodWithAuthEncoding() {
        // Simulate realistic workflow: encode credentials for HTTP request
        let credentials = "admin:secure123"
        let authHeader = "Basic \(Codec.base64Encode(credentials))"
        
        XCTAssertTrue(authHeader.hasPrefix("Basic "))
        XCTAssertEqual(Codec.base64Decode(String(authHeader.dropFirst(6))), credentials)
        
        // Should work with all HTTP methods
        let methods: [HTTPMethod] = [.GET, .POST, .PUT, .DELETE, .PATCH]
        XCTAssertEqual(methods.count, 5)
    }
    
    func testMultipleEncodingsIndependent() {
        let cred1 = "user1:pass1"
        let cred2 = "user2:pass2"
        
        let enc1 = Codec.base64Encode(cred1)
        let enc2 = Codec.base64Encode(cred2)
        
        XCTAssertNotEqual(enc1, enc2)
        XCTAssertEqual(Codec.base64Decode(enc1), cred1)
        XCTAssertEqual(Codec.base64Decode(enc2), cred2)
    }
}
