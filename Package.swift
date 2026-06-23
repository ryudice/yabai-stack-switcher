// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "YabaiStackSwitcher",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "YabaiStackSwitcherCore",
            path: "Sources/YabaiStackSwitcherCore"
        ),
        .executableTarget(
            name: "YabaiStackSwitcher",
            dependencies: ["YabaiStackSwitcherCore"],
            path: "Sources/YabaiStackSwitcher"
        ),
        .testTarget(
            name: "YabaiStackSwitcherTests",
            dependencies: ["YabaiStackSwitcherCore"],
            path: "Tests/YabaiStackSwitcherTests"
        )
    ]
)
