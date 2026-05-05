import Testing
import Foundation
@testable import ReactivShopKit
@testable import Reactiv_Shop_Clip

@MainActor
@Suite struct CartViewModelTests {
    private func makeProduct(id: String = "p1", variantId: String = "v1",
                             amount: Decimal = 10) -> Product {
        let m = Money(amount: amount, currencyCode: "CAD")
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

    @Test func initialState_isEmpty() {
        let store = InMemoryCartStore()
        let vm = CartViewModel(cart: store)
        #expect(vm.isEmpty)
        #expect(vm.itemCount == 0)
        #expect(vm.subtotal == nil)
        #expect(vm.total == nil)
        #expect(vm.lines.isEmpty)
    }

    @Test func lines_reflectStoreContents() throws {
        let store = InMemoryCartStore()
        let p = makeProduct()
        try store.add(p.variants[0], of: p)
        let vm = CartViewModel(cart: store)
        #expect(vm.lines.count == 1)
        #expect(!vm.isEmpty)
        #expect(vm.itemCount == 1)
    }

    @Test func subtotalAndTotal_propagateFromStore() throws {
        let store = InMemoryCartStore()
        let p = makeProduct(amount: 10)
        try store.add(p.variants[0], of: p)
        try store.add(p.variants[0], of: p)   // qty 2
        let vm = CartViewModel(cart: store)
        #expect(vm.subtotal == Money(amount: 20, currencyCode: "CAD"))
        #expect(vm.total == Money(amount: 20, currencyCode: "CAD"))
    }

    @Test func itemCount_sumsAcrossLines() throws {
        let store = InMemoryCartStore()
        let p1 = makeProduct(id: "p1", variantId: "v1")
        let p2 = makeProduct(id: "p2", variantId: "v2")
        try store.add(p1.variants[0], of: p1)
        try store.add(p1.variants[0], of: p1)    // qty 2 of v1
        try store.add(p2.variants[0], of: p2)    // qty 1 of v2
        let vm = CartViewModel(cart: store)
        #expect(vm.itemCount == 3)
        #expect(vm.lines.count == 2)
    }

    @Test func setQuantity_forwardsToStore() throws {
        let store = InMemoryCartStore()
        let p = makeProduct()
        try store.add(p.variants[0], of: p)
        let vm = CartViewModel(cart: store)
        vm.setQuantity(5, for: "v1")
        #expect(store.setQuantityCallCount == 1)
        #expect(store.cart.lines[0].quantity == 5)
    }

    @Test func setQuantityZero_removesLine() throws {
        let store = InMemoryCartStore()
        let p = makeProduct()
        try store.add(p.variants[0], of: p)
        let vm = CartViewModel(cart: store)
        vm.setQuantity(0, for: "v1")
        #expect(vm.isEmpty)
    }

    @Test func remove_forwardsToSetQuantityZero() throws {
        let store = InMemoryCartStore()
        let p = makeProduct()
        try store.add(p.variants[0], of: p)
        let vm = CartViewModel(cart: store)
        vm.remove("v1")
        #expect(store.setQuantityCallCount == 1)
        #expect(vm.isEmpty)
    }
}
