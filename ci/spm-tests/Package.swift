// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CrookedSentryCoreLogic",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "CoreLogic", targets: ["CoreLogic"])
    ],
    targets: [
        .target(
            name: "CoreLogic",
            path: "Sources/CoreLogic"
        ),
        .testTarget(
            name: "CoreLogicTests",
            dependencies: ["CoreLogic"],
            path: "Tests/CoreLogicTests"
        )
    ]
)
