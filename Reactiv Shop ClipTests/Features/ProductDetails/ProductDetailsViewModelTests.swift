import Testing
import Foundation
@testable import ReactivShopKit
@testable import Reactiv_Shop_Clip

@MainActor
@Suite struct ProductDetailsViewModelTests {
    /// Two-option product (Color × Size) → 4 variants. Black/S is unavailable so the
    /// `Docs/01` F3 acceptance check (Black/S → disabled) can be exercised here too.
    private func makeProduct(handle: String = "tee") -> Product {
        let price = Money(amount: 10, currencyCode: "CAD")
        let variants: [ProductVariant] = [
            .init(id: "v-bs", title: "Black/S", isAvailable: false, price: price, compareAtPrice: nil,
                  selectedOptions: [.init(name: "Color", value: "Black"), .init(name: "Size", value: "S")],
                  imageId: nil),
            .init(id: "v-bm", title: "Black/M", isAvailable: true, price: price, compareAtPrice: nil,
                  selectedOptions: [.init(name: "Color", value: "Black"), .init(name: "Size", value: "M")],
                  imageId: nil),
            .init(id: "v-ws", title: "White/S", isAvailable: true, price: price, compareAtPrice: nil,
                  selectedOptions: [.init(name: "Color", value: "White"), .init(name: "Size", value: "S")],
                  imageId: nil),
            .init(id: "v-wm", title: "White/M", isAvailable: true, price: price, compareAtPrice: nil,
                  selectedOptions: [.init(name: "Color", value: "White"), .init(name: "Size", value: "M")],
                  imageId: nil),
        ]
        return Product(
            id: handle, handle: handle, title: "Tee", vendor: "X", description: "",
            isAvailable: true,
            priceRange: PriceRange(min: price, max: price),
            compareAtPriceRange: nil,
            images: [], options: [
                .init(id: "o-color", name: "Color", values: ["Black", "White"]),
                .init(id: "o-size", name: "Size", values: ["S", "M"]),
            ],
            variants: variants
        )
    }

    @Test func initialState_isIdle_andSelectionIsEmpty() {
        let repo = InMemoryProductsRepository(outcome: .success([]))
        let cart = InMemoryCartStore()
        let vm = ProductDetailsViewModel(handle: "tee", repository: repo, cart: cart)
        if case .idle = vm.state {} else { Issue.record("expected .idle") }
        #expect(vm.selection.isEmpty)
        #expect(vm.lastAddedAt == nil)
    }

    @Test func load_success_transitionsToLoaded() async {
        let repo = InMemoryProductsRepository(outcome: .success([makeProduct()]))
        let cart = InMemoryCartStore()
        let vm = ProductDetailsViewModel(handle: "tee", repository: repo, cart: cart)
        await vm.load()
        guard case .loaded(let product) = vm.state else {
            Issue.record("expected .loaded; got \(vm.state)")
            return
        }
        #expect(product.handle == "tee")
    }

    @Test func load_unknownHandle_transitionsToErrorNotFound() async {
        let repo = InMemoryProductsRepository(outcome: .success([makeProduct()]))
        let cart = InMemoryCartStore()
        let vm = ProductDetailsViewModel(handle: "missing", repository: repo, cart: cart)
        await vm.load()
        #expect(vm.state == .error(.notFound(handle: "missing")))
    }

    @Test func load_offline_transitionsToErrorOffline() async {
        let repo = InMemoryProductsRepository(outcome: .failure(.offline))
        let cart = InMemoryCartStore()
        let vm = ProductDetailsViewModel(handle: "tee", repository: repo, cart: cart)
        await vm.load()
        #expect(vm.state == .error(.offline))
    }

    @Test func load_whenInError_isNoop() async {
        let repo = InMemoryProductsRepository(outcome: .failure(.offline))
        let cart = InMemoryCartStore()
        let vm = ProductDetailsViewModel(handle: "tee", repository: repo, cart: cart)
        await vm.load()
        await vm.load()
        await vm.load()
        #expect(repo.fetchHandleCount == 1)
    }

    @Test func retry_fromError_triggersFreshFetch() async {
        let repo = InMemoryProductsRepository(outcome: .failure(.offline))
        let cart = InMemoryCartStore()
        let vm = ProductDetailsViewModel(handle: "tee", repository: repo, cart: cart)
        await vm.load()
        repo.setOutcome(.success([makeProduct()]))
        await vm.retry()
        if case .loaded = vm.state {} else { Issue.record("expected .loaded after retry") }
        #expect(repo.fetchHandleCount == 2)
    }

    @Test func selectedVariant_returnsNilForIncompleteSelection() async {
        let repo = InMemoryProductsRepository(outcome: .success([makeProduct()]))
        let cart = InMemoryCartStore()
        let vm = ProductDetailsViewModel(handle: "tee", repository: repo, cart: cart)
        await vm.load()
        #expect(vm.selectedVariant == nil)
        vm.selection = ["Color": "Black"]
        #expect(vm.selectedVariant == nil)
    }

    @Test func selectedVariant_resolvesCompleteSelection() async {
        let repo = InMemoryProductsRepository(outcome: .success([makeProduct()]))
        let cart = InMemoryCartStore()
        let vm = ProductDetailsViewModel(handle: "tee", repository: repo, cart: cart)
        await vm.load()
        vm.selection = ["Color": "Black", "Size": "M"]
        #expect(vm.selectedVariant?.id == "v-bm")
    }

    @Test func canAddToCart_falseForUnavailableVariant() async {
        let repo = InMemoryProductsRepository(outcome: .success([makeProduct()]))
        let cart = InMemoryCartStore()
        let vm = ProductDetailsViewModel(handle: "tee", repository: repo, cart: cart)
        await vm.load()
        // F3 acceptance: Black/S exists but isAvailable == false; canAddToCart == false.
        vm.selection = ["Color": "Black", "Size": "S"]
        #expect(vm.selectedVariant?.id == "v-bs")
        #expect(vm.selectedVariant?.isAvailable == false)
        #expect(vm.canAddToCart == false)
    }

    @Test func canAddToCart_trueForAvailableVariant() async {
        let repo = InMemoryProductsRepository(outcome: .success([makeProduct()]))
        let cart = InMemoryCartStore()
        let vm = ProductDetailsViewModel(handle: "tee", repository: repo, cart: cart)
        await vm.load()
        vm.selection = ["Color": "Black", "Size": "M"]
        #expect(vm.canAddToCart == true)
    }

    @Test func addToCart_addsLineToStore_andUpdatesLastAddedAt() async throws {
        let repo = InMemoryProductsRepository(outcome: .success([makeProduct()]))
        let cart = InMemoryCartStore()
        let vm = ProductDetailsViewModel(handle: "tee", repository: repo, cart: cart)
        await vm.load()
        vm.selection = ["Color": "Black", "Size": "M"]
        let beforeAdd = vm.lastAddedAt
        try vm.addToCart()
        #expect(cart.cart.lines.count == 1)
        #expect(cart.cart.lines[0].variant.id == "v-bm")
        #expect(cart.addCallCount == 1)
        #expect(vm.lastAddedAt != beforeAdd)
    }

    @Test func addToCart_isNoop_whenSelectionIncomplete() async throws {
        let repo = InMemoryProductsRepository(outcome: .success([makeProduct()]))
        let cart = InMemoryCartStore()
        let vm = ProductDetailsViewModel(handle: "tee", repository: repo, cart: cart)
        await vm.load()
        try vm.addToCart()
        #expect(cart.cart.lines.isEmpty)
        #expect(cart.addCallCount == 0)
        #expect(vm.lastAddedAt == nil)
    }

    @Test func addToCart_isNoop_whenSelectedVariantUnavailable() async throws {
        let repo = InMemoryProductsRepository(outcome: .success([makeProduct()]))
        let cart = InMemoryCartStore()
        let vm = ProductDetailsViewModel(handle: "tee", repository: repo, cart: cart)
        await vm.load()
        vm.selection = ["Color": "Black", "Size": "S"]   // unavailable variant
        try vm.addToCart()
        #expect(cart.cart.lines.isEmpty)
        #expect(cart.addCallCount == 0)
    }
}
