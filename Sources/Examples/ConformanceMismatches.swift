import Library

// MARK: Under-Specified Protocol

#if swift(<6.0)
/// A conforming type that has now adopted global isolation.
@MainActor
class WindowStyler: Styler {
    // Swift 5 Warning: main actor-isolated instance method 'applyStyle()' cannot be used to satisfy nonisolated protocol requirement
    // Swift 6 Error: main actor-isolated instance method 'applyStyle()' cannot be used to satisfy nonisolated protocol requirement
    func applyStyle() {
    }
}
#endif

// MARK: Globally-Isolated Protocol

/// A type conforming to the global actor annotated `GloballyIsolatedStyler` protocol,
///  will infer the protocol's global actor isolation.
class GloballyIsolatedWindowStyler: GloballyIsolatedStyler {
    func applyStyle() {
    }
}

/// A type conforming to `PerRequirementIsolatedStyler` which has MainActor isolated protocol requirements,
/// will infer the protocol's requirements isolation for methods witnessing those protocol requirements *only*
/// for the satisfying methods.
class PerRequirementIsolatedWindowStyler: PerRequirementIsolatedStyler {
    func applyStyle() {
        // only this is MainActor-isolated
    }

    func checkStyle() {
        // this method is non-isolated; it is not witnessing any isolated protocol requirement
    }
}

// MARK: Asynchronous Requirements

/// A conforming type that can have arbitrary isolation and
/// still matches the async requirement.
class AsyncWindowStyler: AsyncStyler {
    func applyStyle() {
    }
}

// MARK: Using preconcurrency

/// A conforming type that will infer the protocol's global isolation *but*
/// with downgraded diagnostics in Swift 6 mode and Swift 5 + complete checking
class StagedGloballyIsolatedWindowStyler: StagedGloballyIsolatedStyler {
    func applyStyle() {
    }
}

// MARK: Using Dynamic Isolation

/// A conforming type that uses a nonisolated function to match
/// with dynamic isolation in the method body.
@MainActor
class DynamicallyIsolatedStyler: Styler {
    nonisolated func applyStyle() {
        MainActor.assumeIsolated {
            // MainActor state is available here
        }
    }
}

/// A conforming type that uses a preconcurency conformance, which
/// is a safer and more ergonomic version of DynamicallyIsolatedStyler.
@MainActor
class PreconcurrencyConformanceStyler: @preconcurrency Styler {
    func applyStyle() {
    }
}

// MARK: Non-Isolated

/// A conforming type that uses nonisolated and non-Sendable types but
/// still performs useful work.
@MainActor
class NonisolatedWindowStyler: StylerConfiguration {
    nonisolated var primaryColorComponents: ColorComponents {
        ColorComponents(red: 0.2, green: 0.3, blue: 0.4)
    }
}

// MARK: Conformance by Proxy

/// An intermediary type that conforms to the protocol so it can be
/// used by an actor
struct CustomWindowStyle: Styler {
    func applyStyle() {
    }
}

/// An actor that interacts with the Style protocol indirectly.
actor ActorWindowStyler {
    private let internalStyle = CustomWindowStyle()

    func applyStyle() {
        // forward the call through to the conforming type
        internalStyle.applyStyle()
    }
}

func exerciseConformanceMismatchExamples() async {
    print("Protocol Conformance Isolation Mismatch Examples")

    // Could also all be done with async calls, but this
    // makes the isolation, and the ability to invoke them
    // from a synchronous context explicit.
    await MainActor.run {
#if swift(<6.0)
        print("  - using a mismatched conformance")
        WindowStyler().applyStyle()
#endif

        print("  - using a MainActor-isolated type")
        GloballyIsolatedWindowStyler().applyStyle()

        print("  - using a per-requirement MainActor-isolated type")
        PerRequirementIsolatedWindowStyler().applyStyle()

        print("  - using an async conformance")
        AsyncWindowStyler().applyStyle()

        print("  - using staged isolation")
        StagedGloballyIsolatedWindowStyler().applyStyle()

        print("  - using dynamic isolation")
        DynamicallyIsolatedStyler().applyStyle()

        print("  - using a preconcurrency conformance")
        PreconcurrencyConformanceStyler().applyStyle()

        let value = NonisolatedWindowStyler().primaryColorComponents
        print("  - accessing a non-isolated conformance: ", value)
    }

    print("  - using an actor with a proxy conformance")
    await ActorWindowStyler().applyStyle()
}
