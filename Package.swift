// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EatNeatMCP",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "EatNeatMCP",
            targets: ["EatNeatMCP"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Cocoanetics/SwiftMCP.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "EatNeatMCP",
            dependencies: [
                .product(name: "SwiftMCP", package: "SwiftMCP")
            ],
            path: "Sources"
        )
    ]
)
