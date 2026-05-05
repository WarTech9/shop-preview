import Testing
import Foundation
@testable import ReactivShopKit
@testable import Reactiv_Shop_Clip

@MainActor
@Suite struct CatalogViewModelTests {
    private func makeProduct(handle: String = "h1") -> Product {
        let m = Money(amount: 10, currencyCode: "CAD")
        return Product(
            id: handle, handle: handle, title: "P", vendor: "V", description: "",
            isAvailable: true,
            priceRange: PriceRange(min: m, max: m),
            compareAtPriceRange: nil,
            images: [], options: [],
            variants: [ProductVariant(
                id: "v", title: "V", isAvailable: true,
                price: m, compareAtPrice: nil,
                selectedOptions: [], imageId: nil
            )]
        )
    }

    @Test func initialState_isIdle() {
        let repo = InMemoryProductsRepository(outcome: .success([]))
        let vm = CatalogViewModel(repository: repo)
        if case .idle = vm.state {} else { Issue.record("expected .idle") }
    }

    @Test func load_success_transitionsToLoaded() async {
        let products = [makeProduct(handle: "a"), makeProduct(handle: "b")]
        let repo = InMemoryProductsRepository(outcome: .success(products))
        let vm = CatalogViewModel(repository: repo)
        await vm.load()
        guard case .loaded(let loaded) = vm.state else {
            Issue.record("expected .loaded; got \(vm.state)")
            return
        }
        #expect(loaded.count == 2)
        #expect(loaded.map(\.handle) == ["a", "b"])
    }

    @Test func load_offline_transitionsToErrorOffline() async {
        let repo = InMemoryProductsRepository(outcome: .failure(.offline))
        let vm = CatalogViewModel(repository: repo)
        await vm.load()
        #expect(vm.state == .error(.offline))
    }

    @Test func load_serverError_propagatesStatus() async {
        let repo = InMemoryProductsRepository(outcome: .failure(.server(500)))
        let vm = CatalogViewModel(repository: repo)
        await vm.load()
        #expect(vm.state == .error(.server(500)))
    }

    @Test func load_decodingError_transitionsToErrorDecoding() async {
        let repo = InMemoryProductsRepository(outcome: .failure(.decoding))
        let vm = CatalogViewModel(repository: repo)
        await vm.load()
        #expect(vm.state == .error(.decoding))
    }

    @Test func load_whenAlreadyLoaded_isNoop() async {
        let repo = InMemoryProductsRepository(outcome: .success([makeProduct()]))
        let vm = CatalogViewModel(repository: repo)
        await vm.load()
        await vm.load()
        await vm.load()
        #expect(repo.fetchAllCount == 1)
    }

    @Test func load_whenInError_isNoop() async {
        let repo = InMemoryProductsRepository(outcome: .failure(.offline))
        let vm = CatalogViewModel(repository: repo)
        await vm.load()      // → .error
        await vm.load()      // strict guard — no-op
        await vm.load()
        #expect(repo.fetchAllCount == 1)
    }

    @Test func retry_fromErrorState_triggersFreshFetch() async {
        let repo = InMemoryProductsRepository(outcome: .failure(.offline))
        let vm = CatalogViewModel(repository: repo)
        await vm.load()
        #expect(vm.state == .error(.offline))

        repo.setOutcome(.success([makeProduct()]))
        await vm.retry()
        guard case .loaded = vm.state else {
            Issue.record("expected .loaded after retry; got \(vm.state)")
            return
        }
        #expect(repo.fetchAllCount == 2)
    }
}
