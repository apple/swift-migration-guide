import Library

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

/// MainActor-isolated function that accepts non-`Sendable` parameters.
@MainActor
func globallyIsolated_updateStyle(backgroundColor: ColorComponents) async {
    // This is safe because backgroundColor cannot change domains. It also
    // now no longer necessary to await the call to `applyBackground`.
    applyBackground(backgroundColor)
}

/// An overload used by `sendable_updateStyle` to match types.
@MainActor
func applyBackground(_ color: SendableColorComponents) {
}

// The Sendable variant is safe to pass across isolation domains.
func sendable_updateStyle(backgroundColor: SendableColorComponents) async {
    await applyBackground(backgroundColor)
}

func exerciseBoundaryCrossingExamples() async {
    print("Isolation Boundary Crossing Examples")

#if swift(<6.0)
    print("  - updateStyle(backgroundColor:) passing its argument unsafely")
#endif

    print("  - using ColorComponents only from the main actor")
    let t1 = Task { @MainActor in
        let components = ColorComponents()
        
        await globallyIsolated_updateStyle(backgroundColor: components)
    }

    await t1.value
}
