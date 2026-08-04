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
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
