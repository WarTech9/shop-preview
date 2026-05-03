import Testing
import Foundation
@testable import ReactiveShopKit

@Suite struct CartTests {
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

    @Test func add_newVariant_createsLineWithQuantityOne() throws {
        var cart = Cart()
        let p = makeProduct()
        try cart.add(p.variants[0], of: p)
        #expect(cart.lines.count == 1)
        #expect(cart.lines[0].quantity == 1)
        #expect(cart.itemCount == 1)
    }

    @Test func add_sameVariantTwice_incrementsExistingLine() throws {
        var cart = Cart()
        let p = makeProduct()
        try cart.add(p.variants[0], of: p)
        try cart.add(p.variants[0], of: p)
        #expect(cart.lines.count == 1)
        #expect(cart.lines[0].quantity == 2)
        #expect(cart.itemCount == 2)
    }

    @Test func add_differentVariants_appendsSeparateLines() throws {
        var cart = Cart()
        let a = makeProduct(id: "p1", variantId: "v1")
        let b = makeProduct(id: "p2", variantId: "v2")
        try cart.add(a.variants[0], of: a)
        try cart.add(b.variants[0], of: b)
        #expect(cart.lines.count == 2)
        #expect(cart.itemCount == 2)
    }

    @Test func setQuantity_zero_removesLine() throws {
        var cart = Cart()
        let p = makeProduct()
        try cart.add(p.variants[0], of: p)
        cart.setQuantity(0, for: "v1")
        #expect(cart.lines.isEmpty)
        #expect(cart.itemCount == 0)
    }

    @Test func setQuantity_negative_clampsToZeroAndRemoves() throws {
        var cart = Cart()
        let p = makeProduct()
        try cart.add(p.variants[0], of: p)
        cart.setQuantity(-3, for: "v1")
        #expect(cart.lines.isEmpty)
    }

    @Test func setQuantity_unknownLine_isNoop() {
        var cart = Cart()
        cart.setQuantity(5, for: "does-not-exist")
        #expect(cart.lines.isEmpty)
    }

    @Test func subtotalAndTotal_areNilOnEmptyCart() {
        let cart = Cart()
        #expect(cart.subtotal == nil)
        #expect(cart.total == nil)
        #expect(cart.itemCount == 0)
    }

    @Test func subtotalAndTotal_sumLineTotalsInCartCurrency() throws {
        var cart = Cart()
        let p = makeProduct(amount: 10)
        try cart.add(p.variants[0], of: p)
        try cart.add(p.variants[0], of: p)  // qty 2 × $10
        #expect(cart.subtotal == Money(amount: 20, currencyCode: "CAD"))
        #expect(cart.total == Money(amount: 20, currencyCode: "CAD"))
    }

    @Test func add_throwsCurrencyMismatch_whenMixingCurrencies() throws {
        var cart = Cart()
        let cad = makeProduct(id: "p-cad", variantId: "v-cad", currency: "CAD")
        let usd = makeProduct(id: "p-usd", variantId: "v-usd", currency: "USD")
        try cart.add(cad.variants[0], of: cad)
        #expect(throws: CartError.currencyMismatch) {
            try cart.add(usd.variants[0], of: usd)
        }
        // Cart unchanged after the failed add.
        #expect(cart.lines.count == 1)
        #expect(cart.lines[0].variant.id == "v-cad")
    }
}
