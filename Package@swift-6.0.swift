// swift-tools-version: 6.0

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
    swiftLanguageVersions: [.v6]
)

let swiftSettings: [SwiftSetting] = [
]

for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(contentsOf: swiftSettings)
    target.swiftSettings = settings
}
