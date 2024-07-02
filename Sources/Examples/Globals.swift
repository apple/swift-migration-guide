import Dispatch

#if swift(<6.0)
/// An unsafe global variable.
///
/// See swift-6-concurrency-migration-guide/commonproblems/#Sendable-Types
var supportedStyleCount = 42
#endif

/// Version of `supportedStyleCount` that uses global-actor isolation.
@MainActor
var globallyIsolated_supportedStyleCount = 42

/// Version of `supportedStyleCount` that uses immutability.
let constant_supportedStyleCount = 42

/// Version of `supportedStyleCount` that uses a computed property.
var computed_supportedStyleCount: Int {
    42
}

/// Version of `supportedStyleCount` that uses manual synchronization via `sharedQueue`
nonisolated(unsafe) var queueProtected_supportedStyleCount = 42

/// A non-isolated async function used to exercise all of the global mutable state examples.
func exerciseGlobalExamples() async {
    print("Global Variable Examples")
#if swift(<6.0)
    // Here is how we access `supportedStyleCount` concurrently in an unsafe way
    for _ in 0..<10 {
        DispatchQueue.global().async {
            supportedStyleCount += 1
        }
    }

    print("  - accessing supportedStyleCount unsafely:", supportedStyleCount)

    await DispatchQueue.global().pendingWorkComplete()
#endif
    
    print("  - accessing globallyIsolated_supportedStyleCount")
    // establish a MainActor context to access the globally-isolated version
    await MainActor.run {
        globallyIsolated_supportedStyleCount += 1
    }

    // freely access the immutable version from any isolation domain
    print("  - accessing constant_supportedStyleCount when non-isolated: ", constant_supportedStyleCount)

    await MainActor.run {
        print("  - accessing constant_supportedStyleCount from MainActor: ", constant_supportedStyleCount)
    }

    // freely access the computed property from any isolation domain
    print("  - accessing computed_supportedStyleCount when non-isolated: ", computed_supportedStyleCount)

    // access the manually-synchronized version... carefully
    manualSerialQueue.async {
        queueProtected_supportedStyleCount += 1
    }

    manualSerialQueue.async {
        print("  - accessing queueProtected_supportedStyleCount: ", queueProtected_supportedStyleCount)
    }

    await manualSerialQueue.pendingWorkComplete()
}
