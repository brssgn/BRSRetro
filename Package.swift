// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BRSRetro",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "BRSRetro",
            targets: ["BRSRetro"]
        ),
    ],
    targets: [
        .target(
            name: "BRSRetro",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "BRSRetroTests",
            dependencies: ["BRSRetro"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
