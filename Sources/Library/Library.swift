import Foundation

/// An example of a struct with only `Sendable` properties.
///
/// This type is **not** Sendable because it is public. If we want a public type to be `Sendable`, we must annotate it explicitly.
public struct ColorComponents {
	public let red: Float
	public let green: Float
	public let blue: Float

	public init(red: Float, green: Float, blue: Float) {
		self.red = red
		self.green = green
		self.blue = blue
	}

	public init() {
		self.red = 1.0
		self.green = 1.0
		self.blue = 1.0
	}
}

/// Explicitly-Sendable variant of `ColorComponents`.
public struct SendableColorComponents : Sendable {
	public let red: Float = 1.0
	public let green: Float = 1.0
	public let blue: Float = 1.0

	public init() {}
}

@MainActor
public struct GlobalActorIsolatedColorComponents : Sendable {
	public let red: Float = 1.0
	public let green: Float = 1.0
	public let blue: Float = 1.0

	public init() {}
}
