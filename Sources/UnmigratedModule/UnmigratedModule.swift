import Foundation

/// An example of a struct with only `Sendable` properties.
///
/// This type is implicitly-`Sendable` within its defining module.
public struct ColorComponents {
    public let red: Float
    public let green: Float
    public let blue: Float

    public init(red: Float, green: Float, blue: Float) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}


public protocol Styling {
    func updateStyle(completionHandler: () -> Void)
}

public class NonSendableThing {
}

public protocol MyProtocol {
    func protocolRequirement(_ value: NonSendableThing)
}
