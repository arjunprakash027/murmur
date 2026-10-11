// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "murmur",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", exact: "1.15.0"),
    ],
    targets: [
        .executableTarget(
            name: "murmur",
            dependencies: [
                "KeyboardShortcuts",
                "WhisperFramework",
            ],
            path: "Sources/murmur"
        ),
        .binaryTarget(
            name: "WhisperFramework",
            path: "vendor/xcframework/unpacked/build-apple/whisper.xcframework"
        ),
    ]
)
