@preconcurrency import Library

/// A non-isolated function  that accepts non-`Sendable` parameters.
func preconcurrency_updateStyle(backgroundColor: ColorComponents) async {
    // Swift 5: no diagnostics
    // Swift 6 Warning: sending 'backgroundColor' risks causing data races
    await applyBackground(backgroundColor)
}
