import Testing
import Foundation
@testable import ReactiveShopKit

@Suite struct ProductSelectionTests {
    /// Two-option product (Color × Size) → 4 variants. Black/S is intentionally unavailable so
    /// the disabled-chip rule (F3.3) and the unavailable-but-resolvable case can both be tested.
    private func makeTestProduct() -> Product {
        let cad = "CAD"
        let price = Money(amount: 10, currencyCode: cad)

        let variants: [ProductVariant] = [
            .init(id: "v-bs", title: "Black / S", isAvailable: false, price: price, compareAtPrice: nil,
                  selectedOptions: [.init(name: "Color", value: "Black"), .init(name: "Size", value: "S")],
                  imageId: nil),
            .init(id: "v-bm", title: "Black / M", isAvailable: true, price: price, compareAtPrice: nil,
                  selectedOptions: [.init(name: "Color", value: "Black"), .init(name: "Size", value: "M")],
                  imageId: nil),
            .init(id: "v-ws", title: "White / S", isAvailable: true, price: price, compareAtPrice: nil,
                  selectedOptions: [.init(name: "Color", value: "White"), .init(name: "Size", value: "S")],
                  imageId: nil),
            .init(id: "v-wm", title: "White / M", isAvailable: true, price: price, compareAtPrice: nil,
                  selectedOptions: [.init(name: "Color", value: "White"), .init(name: "Size", value: "M")],
                  imageId: nil),
        ]

        return Product(
            id: "p1", handle: "tee", title: "Tee", vendor: "X", description: "",
            isAvailable: true,
            priceRange: PriceRange(min: price, max: price),
            compareAtPriceRange: nil,
            images: [],
            options: [
                ProductOption(id: "o-color", name: "Color", values: ["Black", "White"]),
                ProductOption(id: "o-size", name: "Size", values: ["S", "M"]),
            ],
            variants: variants
        )
    }

    @Test func availableValues_noSelection_returnsEveryValueBackedByAnAvailableVariant() {
        let p = makeTestProduct()
        #expect(p.availableValues(for: p.options[0], given: [:]) == ["Black", "White"])
        #expect(p.availableValues(for: p.options[1], given: [:]) == ["S", "M"])
    }

    @Test func availableValues_filtersByPartialSelection() {
        let p = makeTestProduct()
        let sizeOpt = p.options[1]
        // With Color = Black, only Size = M is reachable (Black/S is unavailable).
        #expect(p.availableValues(for: sizeOpt, given: ["Color": "Black"]) == ["M"])
        // With Color = White, both sizes remain reachable.
        #expect(p.availableValues(for: sizeOpt, given: ["Color": "White"]) == ["S", "M"])
    }

    @Test func availableValues_ignoresPickOnTheOptionBeingAsked() {
        let p = makeTestProduct()
        let colorOpt = p.options[0]
        // Asking which Colors are available while Color is already picked should still show
        // every Color that has any available variant — otherwise the user can't change colour.
        #expect(p.availableValues(for: colorOpt, given: ["Color": "Black"]) == ["Black", "White"])
    }

    @Test func variantMatching_resolvesUniqueVariantForCompleteSelection() {
        let p = makeTestProduct()
        #expect(p.variant(matching: ["Color": "Black", "Size": "M"])?.id == "v-bm")
        #expect(p.variant(matching: ["Color": "White", "Size": "S"])?.id == "v-ws")
    }

    @Test func variantMatching_returnsNilForIncompleteSelection() {
        let p = makeTestProduct()
        #expect(p.variant(matching: ["Color": "Black"]) == nil)
        #expect(p.variant(matching: [:]) == nil)
    }

    @Test func variantMatching_resolvesUnavailableVariant_callerJudgesAvailability() {
        let p = makeTestProduct()
        let v = p.variant(matching: ["Color": "Black", "Size": "S"])
        #expect(v?.id == "v-bs")
        #expect(v?.isAvailable == false)
    }
}
