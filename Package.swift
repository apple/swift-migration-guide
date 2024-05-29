// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MigrationGuide",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
        .macCatalyst(.v13),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "FullyMigratedModule",
            targets: [
                "FullyMigratedModule",
                "MigrationInProgressModule",
            ]
        ),
    ],
    targets: [
        .target(
            name: "FullyMigratedModule"
        ),
        .target(
            name: "MigrationInProgressModule",
            dependencies: ["FullyMigratedModule"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)

let swiftSettings: [SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency")
]

for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(contentsOf: swiftSettings)
    target.swiftSettings = settings
}
