import Testing
import Foundation
@testable import ReactivShopKit

@Suite struct MoneyTests {
    @Test func equalityRequiresMatchingAmountAndCurrency() {
        #expect(Money(amount: 10, currencyCode: "CAD") == Money(amount: 10, currencyCode: "CAD"))
        #expect(Money(amount: 10, currencyCode: "CAD") != Money(amount: 10, currencyCode: "USD"))
        #expect(Money(amount: 10, currencyCode: "CAD") != Money(amount: 11, currencyCode: "CAD"))
    }

    @Test func decimalArithmeticAvoidsBinaryFloatRoundoff() {
        // 0.1 + 0.2 != 0.3 in binary float; Decimal must get this right.
        let a = Decimal(string: "0.1")!
        let b = Decimal(string: "0.2")!
        #expect(a + b == Decimal(string: "0.3")!)
    }

    @Test func hashableDeduplicatesEqualValues() {
        var set: Set<Money> = []
        set.insert(Money(amount: 10, currencyCode: "CAD"))
        set.insert(Money(amount: 10, currencyCode: "CAD"))
        set.insert(Money(amount: 10, currencyCode: "USD"))
        #expect(set.count == 2)
    }
}
