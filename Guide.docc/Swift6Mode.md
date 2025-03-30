# Enabling The Swift 6 Language Mode

Guarantee your code is free of data races by enabling the Swift 6 language mode.

## Using the Swift compiler

To enable the Swift 6 language mode when running `swift` or `swiftc`
directly at the command line, pass `-swift-version 6`:

```
~ swift -swift-version 6 main.swift
```

## Using SwiftPM

### Command-line invocation

`-swift-version 6` can be passed in a Swift package manager command-line
invocation using the `-Xswiftc` flag:

```
~ swift build -Xswiftc -swift-version -Xswiftc 6
~ swift test -Xswiftc -swift-version -Xswiftc 6
```

### Package manifest

A `Package.swift` file that uses `swift-tools-version` of `6.0` will enable the Swift 6 language
mode for all targets. You can still set the language mode for the package as a whole using the
`swiftLanguageModes` property of `Package`. However, you can now also change the language mode as
needed on a per-target basis using the new `swiftLanguageMode` build setting:

```swift
// swift-tools-version: 6.0

let package = Package(
    name: "MyPackage",
    products: [
        // ...
    ],
    targets: [
        // Uses the default tools language mode (6)
        .target(
            name: "FullyMigrated",
        ),
        // Still requires 5
        .target(
            name: "NotQuiteReadyYet",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
```

Note that if your package needs to continue supporting earlier Swift toolchain versions and you want
to use per-target `swiftLanguageMode`, you will need to create a version-specific manifest for pre-6
toolchains. For example, if you'd like to continue supporting 5.9 toolchains and up, you could have
one manifest `Package@swift-5.9.swift`:
```swift
// swift-tools-version: 5.9

let package = Package(
    name: "MyPackage",
    products: [
        // ...
    ],
    targets: [
        .target(
            name: "FullyMigrated",
        ),
        .target(
            name: "NotQuiteReadyYet",
        )
    ]
)
```

And another `Package.swift` for Swift toolchains 6.0+:
```swift
// swift-tools-version: 6.0

let package = Package(
    name: "MyPackage",
    products: [
        // ...
    ],
    targets: [
        // Uses the default tools language mode (6)
        .target(
            name: "FullyMigrated",
        ),
        // Still requires 5
        .target(
            name: "NotQuiteReadyYet",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
```

If instead you would just like to use Swift 6 language mode when it's available (while still
continuing to support older modes) you can keep a single `Package.swift` and specify the version in
a compatible manner:
```swift
// swift-tools-version: 5.9

let package = Package(
    name: "MyPackage",
    products: [
        // ...
    ],
    targets: [
        .target(
            name: "FullyMigrated",
        ),
    ],
    // `swiftLanguageVersions` and `.version("6")` to support pre 6.0 swift-tools-version.
    swiftLanguageVersions: [.version("6"), .v5]
)
```


## Using Xcode

### Build Settings

You can control the language mode for an Xcode project or target by setting
the "Swift Language Version" build setting to "6".

### XCConfig

You can also set the `SWIFT_VERSION` setting to `6` in an xcconfig file:

```
// In a Settings.xcconfig

SWIFT_VERSION = 6;
```
