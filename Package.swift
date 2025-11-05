// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CrookedSentry",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CrookedSentry",
            targets: ["CrookedSentry"]
        )
    ],
    dependencies: [
        // Add your CocoaPods dependencies here if needed
    ],
    targets: [
        .target(
            name: "CrookedSentry",
            path: "CrookedSentry",
            sources: [
                "FrigateEventAPIClient.swift",
                "SettingsStore.swift", 
                "CameraFeedCard.swift",
                "ImageLoader.swift",
                "LiveFeedAPIClient.swift",
                "NetworkSecurityDebugger.swift",
                "SecureAPIClient.swift",
                "NetworkSecurityValidator.swift",
                "VPNManager.swift",
                "Core/Network/NetworkManager.swift",
                "Core/Network/HTTPMethod.swift",
                "Core/Utils/AuthHeaders.swift"
            ]
        ),
        .testTarget(
            name: "CrookedSentryTests",
            dependencies: ["CrookedSentry"],
            path: "CrookedSentryTests"
        )
    ]
)