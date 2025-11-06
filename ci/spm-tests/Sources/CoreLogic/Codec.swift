import Foundation

// MARK: - Base64 Encoding/Decoding Utilities

public enum Codec {
    /// Encodes a string to Base64
    public static func base64Encode(_ input: String) -> String {
        return input.data(using: .utf8)?.base64EncodedString() ?? ""
    }
    
    /// Decodes a Base64 string
    public static func base64Decode(_ input: String) -> String {
        guard let data = Data(base64Encoded: input),
              let decoded = String(data: data, encoding: .utf8) else {
            return ""
        }
        return decoded
    }
}

// MARK: - JSON Decoder Extensions

public extension JSONDecoder {
    static let frigate: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }()
}

// MARK: - Network Models

public struct NetworkStatus: Codable, Sendable, Equatable {
    public let network: NetworkType
    public let ip: String
    public init(network: NetworkType, ip: String) {
        self.network = network
        self.ip = ip
    }
}

public enum NetworkType: String, Codable, Sendable { case lan, vpn, internet }

