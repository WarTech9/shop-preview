import Foundation

extension Money {
    /// Locale-aware currency formatting using the price's own `currencyCode`.
    /// Example: `Money(amount: 28.52, currencyCode: "CAD")` → "CA$28.52" (en_US),
    /// "28,52 $ CA" (fr_CA), etc.
    public func formatted() -> String {
        amount.formatted(.currency(code: currencyCode))
    }
}

extension PriceRange {
    /// Single value when min == max; en-dash range otherwise: "CA$28.52 – CA$32.09".
    public func formatted() -> String {
        isSingle ? min.formatted() : "\(min.formatted()) – \(max.formatted())"
    }
}
