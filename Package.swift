// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Translator",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "Translator",
            path: "Sources/Translator",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
