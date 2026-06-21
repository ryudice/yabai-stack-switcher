// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "YabaiStackSwitcher",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "YabaiStackSwitcher",
            path: "Sources/YabaiStackSwitcher"
        )
    ]
)
