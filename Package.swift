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
			name: "Library",
			targets: ["Library"]
		),
		.executable(name: "swift5_examples", targets: ["Swift5Examples"]),
		.executable(name: "swift6_examples", targets: ["Swift6Examples"]),
	],
	targets: [
		.target(
			name: "Library"
		),
        .target(
            name: "ObjCLibrary",
            publicHeadersPath: "."
        ),
		.executableTarget(
			name: "Swift5Examples",
			dependencies: ["Library"],
			swiftSettings: [
				.swiftLanguageVersion(.v5)
			]
		),
		.executableTarget(
			name: "Swift6Examples",
			dependencies: ["Library"]
		)
	],
	swiftLanguageVersions: [.v6]
)
