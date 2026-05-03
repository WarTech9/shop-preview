import Testing
@testable import ReactiveShopKit

@Suite struct PriceRangeTests {
    @Test func isSingle_trueWhenMinEqualsMax() {
        let m = Money(amount: 10, currencyCode: "CAD")
        #expect(PriceRange(min: m, max: m).isSingle)
    }

    @Test func isSingle_falseWhenMinAndMaxDiffer() {
        let lo = Money(amount: 10, currencyCode: "CAD")
        let hi = Money(amount: 20, currencyCode: "CAD")
        #expect(!PriceRange(min: lo, max: hi).isSingle)
    }
}
