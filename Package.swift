// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RoundedScreen",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(name: "RoundedScreen", path: "Sources/RoundedScreen")
    ]
)
