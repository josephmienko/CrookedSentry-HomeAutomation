// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CrookedSentryCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "CrookedSentryCore", targets: ["CrookedSentryCore"])
    ],
    targets: [
        .target(
            name: "CrookedSentryCore",
            path: "Sources",
            sources: [
                "HTTPMethod.swift",
                "AuthHeaders.swift",
                "NetworkManager.swift"
            ]
        ),
        .testTarget(
            name: "CrookedSentryCoreTests",
            dependencies: ["CrookedSentryCore"],
            path: "Tests"
        )
    ]
)