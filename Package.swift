// swift-tools-version: 5.10

import PackageDescription

#if compiler(>=6.0)
// this can be further improved once SE-0435 is available
let swift5Mode = SwiftSetting.unsafeFlags(["-swift-version", "5"])
let swift6Mode = SwiftSetting.unsafeFlags(["-swift-version", "6"])
let toolsSwiftMode = swift6Mode
let baseSettings: [SwiftSetting] = [
]
#else
let swift5Mode = SwiftSetting.unsafeFlags(["-swift-version", "5"])
let swift6Mode = SwiftSetting.unsafeFlags(["-swift-version", "6"])
let toolsSwiftMode = swift5Mode
let baseSettings: [SwiftSetting] = [
	.enableExperimentalFeature("StrictConcurrency")
]
#endif

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
		.executable(name: "swift5_examples", targets: ["Swift5Examples"]),
	],
	targets: [
		.target(
			name: "FullyMigratedModule",
			swiftSettings: [toolsSwiftMode] + baseSettings
		),
		.target(
			name: "MigrationInProgressModule",
			dependencies: ["FullyMigratedModule"],
			swiftSettings: [toolsSwiftMode] + baseSettings
		),
		.executableTarget(
			name: "Swift5Examples",
			dependencies: [],
			swiftSettings: [swift5Mode] + baseSettings
		),
	]
)

#if compiler(<6.0)
print("swift6_examples is unavailable with this version of the compiler")
#else
package.targets.append(
	.executableTarget(
		name: "Swift6Examples",
		dependencies: [],
		swiftSettings: [swift6Mode] + baseSettings
	)
)

package.products.append(
	.executable(name: "swift6_examples", targets: ["Swift6Examples"])
)
#endif
