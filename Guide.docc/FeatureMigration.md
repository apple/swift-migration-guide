# Migrating to upcoming language features

Migrate your project to upcoming language features.

Upcoming language features can be enabled in the Swift compiler via a `-enable-upcoming-feature
<FeatureName>` flag. Some of these features also support a migration mode. This mode does not
actually enable the desired feature. Instead, it produces compiler warnings with the necessary
fix-its to make the existing code both source- and binary-compatible with the feature. The exact
semantics of such a migration is dependent on the feature, see their [corresponding
documentation](https://docs.swift.org/compiler/documentation/diagnostics/upcoming-language-features)
for more details.

## SwiftPM

> Note: This feature is in active development. Test with a [nightly
> snapshot](https://www.swift.org/install) for best results.

`swift package migrate` builds and applies migration fix-its to allow for semi-automated migration.
Make sure to start with a clean working tree (no current changes staged or otherwise) and a working
build - applying the fix-its requires there to be no build errors and will modify files in the
package *in place*.

To eg. migrate all targets in your package to `NonisolatedNonsendingByDefault`:
```sh
swift package migrate --to-feature NonisolatedNonsendingByDefault
```

Or a target at a time with `--targets`:
```sh
swift package migrate --targets TargetA --to-feature NonisolatedNonsendingByDefault
```

This will start a build, apply any migration fix-its, and then update the manifest:
```
> Starting the build.
... regular build output with migration diagnostics ...
> Applying fix-its.
> Updating manifest.
```

Check out the changes with your usual version control tooling, e.g., `git diff`:
```diff
diff --git a/Package.swift b/Package.swift
index a1e587c..11097be 100644
--- a/Package.swift
+++ b/Package.swift
@@ -14,10 +14,16 @@ let package = Package(
     targets: [
         .target(
             name: "TargetA",
+            swiftSettings: [
+                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
+            ]
         ),
     ]

diff --git a/Sources/packtest/packtest.swift b/Sources/packtest/packtest.swift
index 85253f5..8498bb5 100644
--- a/Sources/TargetA/TargetA.swift
+++ b/Sources/TargetA/TargetA.swift
@@ -1,5 +1,5 @@
 struct S: Sendable {
-  func alwaysSwitch() async {}
+  @concurrent func alwaysSwitch() async {}
 }
```

In some cases, the automated application of upcoming features to a target in the package manifest
can fail for more complicated packages, e.g., if settings have been factored out into a variable
that's then applied to multiple targets:
```
error: Could not update manifest for 'TargetA' (unable to find array literal for 'swiftSettings' argument). Please enable 'NonisolatedNonsendingByDefault' features manually.
```

If this happens, manually add a `.enableUpcomingFeature("SomeFeature")` Swift setting to complete
the migration:
```swift
// swift-tools-version: 6.2

let targetSettings: [SwiftSetting] = [
    // ...
    .enableUpcomingFeature("NonisolatedNonsendingByDefault")
]

let targetSettings:
let package = Package(
    name: "MyPackage",
    products: [
        // ...
    ],
    targets: [
        .target(
            name: "TargetA",
            swiftSettings: targetSettings
        ),
    ]
)
```
