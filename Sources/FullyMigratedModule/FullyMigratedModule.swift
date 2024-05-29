/// An example of a struct with only `Sendable` properties.
///
/// This type is implicitly-`Sendable` within its defining module.
public struct ColorComponents {
    public let red: Float
    public let green: Float
    public let blue: Float
}
