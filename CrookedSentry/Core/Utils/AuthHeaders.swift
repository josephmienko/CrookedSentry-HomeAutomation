//
//  AuthHeaders.swift
//

import Foundation

public enum AppDefaults {
    /// Read camera credentials from Info.plist, supporting either uppercase or lowercase keys.
    public static var cameraUsername: String? {
        let b = Bundle.main
        return (b.object(forInfoDictionaryKey: "CAM_USER") as? String)
            ?? (b.object(forInfoDictionaryKey: "cam_user") as? String)
    }
    public static var cameraPassword: String? {
        let b = Bundle.main
        return (b.object(forInfoDictionaryKey: "CAM_PASSWORD") as? String)
            ?? (b.object(forInfoDictionaryKey: "cam_password") as? String)
    }
}

public enum AuthHeaders {
    /// Builds default headers including Referer, User-Agent and optional Basic auth.
    public static func build(baseURL: URL,
                             username: String?,
                             password: String?,
                             extra: [String: String] = [:]) -> [String: String] {
        var headers: [String: String] = [
            "Referer": baseURL.absoluteString,
            "User-Agent": "CrookedSentry/1.0 (iOS)"
        ]
        // Prefer provided username/password, otherwise fall back to Info.plist values
        let effectiveUsername = (username?.isEmpty == false ? username : AppDefaults.cameraUsername)
        let effectivePassword = (password?.isEmpty == false ? password : AppDefaults.cameraPassword)
        if let u = effectiveUsername, !u.isEmpty {
            let p = effectivePassword ?? ""
            let token = "\(u):\(p)".data(using: .utf8)?.base64EncodedString() ?? ""
            headers["Authorization"] = "Basic \(token)"
        }
        for (k, v) in extra { headers[k] = v }
        return headers
    }
}
