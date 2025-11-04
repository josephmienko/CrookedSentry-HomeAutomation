//
//  NetworkManager.swift
//

import Foundation

public struct NetworkManager {
    public let baseURL: URL
    public var session: URLSession = .shared
    public var defaultHeaders: [String: String] = [:]

    public init(baseURL: URL, headers: [String: String] = [:]) {
        self.baseURL = baseURL
        self.defaultHeaders = headers
    }

    public func checkNetworkStatus() async -> NetworkStatus {
        // Simple reachability check via /whoami per provided API; fall back to internet
        let endpoint = URL(string: "/whoami", relativeTo: baseURL)!
        var req = URLRequest(url: endpoint)
        req.httpMethod = HTTPMethod.GET.rawValue
        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return NetworkStatus(network: .internet, ip: "")
            }
            if let status = try? JSONDecoder().decode(NetworkStatus.self, from: data) {
                return status
            }
        } catch { }
        return NetworkStatus(network: .internet, ip: "")
    }

    public func ensureConnected() async throws {
        // Placeholder: in your architecture this would activate VPN if needed
    }

    public func request<T: Decodable>(_ endpoint: String, method: HTTPMethod = .GET, body: Data? = nil) async throws -> T {
        let url = URL(string: endpoint, relativeTo: baseURL)!
        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        for (k, v) in defaultHeaders { req.setValue(v, forHTTPHeaderField: k) }
        if let body = body {
            req.httpBody = body
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder.frigate.decode(T.self, from: data)
    }
}

public extension JSONDecoder {
    static let frigate: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }()
}

public struct NetworkStatus: Codable {
    public let network: NetworkType
    public let ip: String
}

public enum NetworkType: String, Codable { case lan, vpn, internet }
