import Testing
import Foundation
import Observation
@testable import ReactivShopKit

@MainActor
@Suite struct CartStoreTests {
    private func makeProduct(id: String = "p1", variantId: String = "v1",
                             amount: Decimal = 10, currency: String = "CAD") -> Product {
        let m = Money(amount: amount, currencyCode: currency)
        let v = ProductVariant(
            id: variantId, title: "T", isAvailable: true,
            price: m, compareAtPrice: nil,
            selectedOptions: [], imageId: nil
        )
        return Product(
            id: id, handle: id, title: "P", vendor: "X", description: "",
            isAvailable: true,
            priceRange: PriceRange(min: m, max: m),
            compareAtPriceRange: nil,
            images: [], options: [], variants: [v]
        )
    }

    @Test func add_newVariant_appendsLine() throws {
        let store = CartStore()
        let p = makeProduct()
        try store.add(p.variants[0], of: p)
        #expect(store.cart.lines.count == 1)
        #expect(store.cart.itemCount == 1)
    }

    @Test func add_sameVariantTwice_incrementsLine() throws {
        let store = CartStore()
        let p = makeProduct()
        try store.add(p.variants[0], of: p)
        try store.add(p.variants[0], of: p)
        #expect(store.cart.lines.count == 1)
        #expect(store.cart.lines[0].quantity == 2)
        #expect(store.cart.itemCount == 2)
    }

    @Test func setQuantity_zero_removesLine() throws {
        let store = CartStore()
        let p = makeProduct()
        try store.add(p.variants[0], of: p)
        store.setQuantity(0, for: "v1")
        #expect(store.cart.lines.isEmpty)
    }

    @Test func setQuantity_positive_updatesLine() throws {
        let store = CartStore()
        let p = makeProduct()
        try store.add(p.variants[0], of: p)
        store.setQuantity(5, for: "v1")
        #expect(store.cart.lines[0].quantity == 5)
        #expect(store.cart.itemCount == 5)
    }

    @Test func add_propagatesCurrencyMismatch() throws {
        let store = CartStore()
        let cad = makeProduct(id: "p-cad", variantId: "v-cad", currency: "CAD")
        let usd = makeProduct(id: "p-usd", variantId: "v-usd", currency: "USD")
        try store.add(cad.variants[0], of: cad)
        #expect(throws: CartError.currencyMismatch) {
            try store.add(usd.variants[0], of: usd)
        }
        // Cart unchanged after the failed add.
        #expect(store.cart.lines.count == 1)
        #expect(store.cart.lines[0].variant.id == "v-cad")
    }

    @Test func subtotalAndTotal_reflectStoreContents() throws {
        let store = CartStore()
        let p = makeProduct(amount: 10)
        try store.add(p.variants[0], of: p)
        try store.add(p.variants[0], of: p)
        #expect(store.cart.subtotal == Money(amount: 20, currencyCode: "CAD"))
        #expect(store.cart.total == Money(amount: 20, currencyCode: "CAD"))
    }

    @Test func add_triggersObservation() throws {
        let store = CartStore()
        let p = makeProduct()
        let flag = ObservationFlag()
        withObservationTracking {
            _ = store.cart
        } onChange: {
            flag.didFire = true
        }
        try store.add(p.variants[0], of: p)
        #expect(flag.didFire == true)
    }
}

/// `withObservationTracking`'s `onChange:` closure is `@Sendable`, so it can't capture a
/// `var Bool` from the surrounding scope. The flag is observed synchronously on the same
/// (main) actor, so unchecked Sendable is sound here.
private final class ObservationFlag: @unchecked Sendable {
    var didFire = false
}
