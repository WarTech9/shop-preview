import Foundation

public struct PriceRange: Hashable, Sendable {
    public let min: Money
    public let max: Money

    public init(min: Money, max: Money) {
        self.min = min
        self.max = max
    }

    public var isSingle: Bool { min == max }
}
