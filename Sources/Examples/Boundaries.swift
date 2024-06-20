import Library

// MARK: Core Example Problem

/// A `MainActor`-isolated function that accepts non-`Sendable` parameters.
@MainActor
func applyBackground(_ color: ColorComponents) {
}

#if swift(<6.0)
/// A non-isolated function that accepts non-`Sendable` parameters.
func updateStyle(backgroundColor: ColorComponents) async {
    // the `backgroundColor` parameter is being moved from the
    // non-isolated domain to the `MainActor` here.
    //
    // Swift 5 Warning: passing argument of non-sendable type 'ColorComponents' into main actor-isolated context may introduce data races
    // Swift 6 Error: sending 'backgroundColor' risks causing data races
    await applyBackground(backgroundColor)
}
#endif

#if swift(>=6.0)
/// A non-isolated function that accepts non-`Sendable` parameters which must be safe to use at callsites.
func sending_updateStyle(backgroundColor: sending ColorComponents) async {
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

#if swift(>=6.0)
/// A function that uses a sending parameter to leverage region-based isolation.
func sendingValue_updateStyle(backgroundColor: sending ColorComponents) async {
    await applyBackground(backgroundColor)
}
#endif

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

// MARK: actor isolation

/// An actor that assumes the responsibility of managing the non-Sendable data.
actor Style {
    private var background: ColorComponents

    init(background: ColorComponents) {
        self.background = background
    }

    func applyBackground() {
        // make use of background here
    }
}

// MARK: Manual Synchronization

extension RetroactiveColorComponents: @retroactive @unchecked Sendable {
}

/// An overload used by `retroactive_updateStyle` to match types.
@MainActor
func applyBackground(_ color: RetroactiveColorComponents	) {
}

/// A non-isolated function that accepts retroactively-`Sendable` parameters.
func retroactive_updateStyle(backgroundColor: RetroactiveColorComponents) async {
    await applyBackground(backgroundColor)
}

func exerciseBoundaryCrossingExamples() async {
    print("Isolation Boundary Crossing Examples")

#if swift(<6.0)
    print("  - updateStyle(backgroundColor:) passing its argument unsafely")
#endif

#if swift(>=6.0)
    print("  - using sending to allow safe usage of ColorComponents")
    let nonSendableComponents = ColorComponents()

    await sending_updateStyle(backgroundColor: nonSendableComponents)
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

#if swift(>=6.0)
    print("  - enable region-based isolation with a sending argument")
    let capturableComponents = ColorComponents()

    await sendingValue_updateStyle(backgroundColor: capturableComponents)
#endif

    print("  - using a globally-isolated type")
    let components = await GlobalActorIsolatedColorComponents()

    await globalActorIsolated_updateStyle(backgroundColor: components)

    print("  - using an actor")
    let actorComponents = ColorComponents()

    let actor = Style(background: actorComponents)

    await actor.applyBackground()

    print("  - using a retroactive unchecked Sendable argument")
    let retroactiveComponents = RetroactiveColorComponents()

    await retroactive_updateStyle(backgroundColor: retroactiveComponents)
}
