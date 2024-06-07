# Enabling The Swift 6 Language Mode

Guarantee your code is free of data races by enabling the Swift 6 language mode.

## Using the Swift compiler

To enable complete concurrency checking when running `swift` or `swiftc`
directly at the command line, pass `-swift-version 6`:

```
~ swift -swift-version 6 main.swift
```

## Using SwiftPM

### Command-line invocation

`-swift-version 6` can be passed in a Swift package manager command-line
invocation using the `-Xswiftc` flag:

```
~ swift build -Xswiftc -swift-version 6
~ swift test -Xswiftc -swift-version 6
```

### Package manifest

To change the language mode for package as a whole:

```swift
// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

let package = Package(
  name: "MyPackage",
  products: [
    // ...
  ],
  targets: [
    // ...
  ],
  swiftLanguageVersions: [.v6]
)
```

To change the language mode on a per-target basis:

```swift
.target(
  name: "MyTarget",
  swiftSettings: [
    .swiftLanguageVersion(.v6)
  ]
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
