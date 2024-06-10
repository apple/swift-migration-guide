import Library

// MARK: Core Example Problem

/// A `MainActor`-isolated function that accepts non-`Sendable` parameters.
@MainActor
func applyBackground(_ color: ColorComponents) {
}

#if swift(<6.0)
/// A non-isolated function  that accepts non-`Sendable` parameters.
func updateStyle(backgroundColor: ColorComponents) async {
    // the `backgroundColor` parameter is being moved from the
    // non-isolated domain to the `MainActor` here.
    //
    // Swift 5 Warning: passing argument of non-sendable type 'ColorComponents' into main actor-isolated context may introduce data races
    // Swift 6 Error: sending 'backgroundColor' risks causing data races
    await applyBackground(backgroundColor)
}
#endif

// MARK: Latent Isolation

/// MainActor-isolated function that accepts non-`Sendable` parameters.
@MainActor
func isolatedFunction_updateStyle(backgroundColor: ColorComponents) async {
    // This is safe because backgroundColor cannot change domains. It also
    // now no longer necessary to await the call to `applyBackground`.
    applyBackground(backgroundColor)
}

// MARK: Explicit Sendable

/// An overload used by `sendable_updateStyle` to match types.
@MainActor
func applyBackground(_ color: SendableColorComponents) {
}

/// The Sendable variant is safe to pass across isolation domains.
func sendable_updateStyle(backgroundColor: SendableColorComponents) async {
    await applyBackground(backgroundColor)
}

// MARK: Computed Value

/// A Sendable function is used to compute the value in a different isolation domain.
func computedValue_updateStyle(using backgroundColorProvider: @Sendable () -> ColorComponents) async {
#if swift(<6.0)
    // pass backgroundColorProvider into the MainActor here
    await MainActor.run {
        // invoke it in this domain to actually create the needed value
        let components = backgroundColorProvider()
        applyBackground(components)
    }
#else
    // The Swift 6 compiler can automatically determine this value is
    // being transferred in a safe way
    let components = backgroundColorProvider()
    await applyBackground(components)
#endif
}

// MARK: Global Isolation
/// An overload used by `globalActorIsolated_updateStyle` to match types.
@MainActor
func applyBackground(_ color: GlobalActorIsolatedColorComponents) {
}

/// MainActor-isolated function that accepts non-`Sendable` parameters.
@MainActor
func globalActorIsolated_updateStyle(backgroundColor: GlobalActorIsolatedColorComponents) async {
    // This is safe because backgroundColor cannot change domains. It also
    // now no longer necessary to await the call to `applyBackground`.
    applyBackground(backgroundColor)
}

func exerciseBoundaryCrossingExamples() async {
    print("Isolation Boundary Crossing Examples")
    
#if swift(<6.0)
    print("  - updateStyle(backgroundColor:) passing its argument unsafely")
#endif

    print("  - using ColorComponents only from the main actor")
    let t1 = Task { @MainActor in
        let components = ColorComponents()

        await isolatedFunction_updateStyle(backgroundColor: components)
    }

    await t1.value

    print("  - using preconcurrency_updateStyle to deal with non-Sendable argument")

    print("  - using a Sendable closure to defer creation")
    await computedValue_updateStyle(using: {
        ColorComponents()
    })

    print("  - using a globally-isolated type")
    let components = await GlobalActorIsolatedColorComponents()

    await globalActorIsolated_updateStyle(backgroundColor: components)
}
