import Testing
//@testable import ReactivShopKit
@testable import Reactiv_Shop_Clip

@MainActor
@Suite struct AppRouterTests {
    @Test func initialPathIsEmpty() {
        let router = AppRouter()
        #expect(router.path.isEmpty)
    }

    @Test func push_productDetails_appendsToPath() {
        let router = AppRouter()
        router.push(.productDetails(handle: "foo"))
        #expect(router.path == [.productDetails(handle: "foo")])
    }

    @Test func push_multipleDestinations_stacksInOrder() {
        let router = AppRouter()
        router.push(.productDetails(handle: "foo"))
        router.push(.productDetails(handle: "bar"))
        #expect(router.path == [
            .productDetails(handle: "foo"),
            .productDetails(handle: "bar"),
        ])
    }

    @Test func push_catalog_clearsToRoot() {
        let router = AppRouter()
        router.push(.productDetails(handle: "foo"))
        router.push(.productDetails(handle: "bar"))
        router.push(.catalog)
        #expect(router.path.isEmpty)
    }

    @Test func push_catalogOnEmptyPath_isNoop() {
        let router = AppRouter()
        router.push(.catalog)
        #expect(router.path.isEmpty)
    }

    @Test func pop_removesLastDestination() {
        let router = AppRouter()
        router.push(.productDetails(handle: "foo"))
        router.push(.productDetails(handle: "bar"))
        router.pop()
        #expect(router.path == [.productDetails(handle: "foo")])
    }

    @Test func pop_emptyPath_isNoop() {
        let router = AppRouter()
        router.pop()
        #expect(router.path.isEmpty)
    }

    @Test func popToRoot_clearsAll() {
        let router = AppRouter()
        router.push(.productDetails(handle: "foo"))
        router.push(.productDetails(handle: "bar"))
        router.push(.productDetails(handle: "baz"))
        router.popToRoot()
        #expect(router.path.isEmpty)
    }

    @Test func directPathAssignment_isAllowedForSwiftUIBindings() {
        // Confirms `path` is settable directly (required by NavigationStack's back-gesture sync).
        let router = AppRouter()
        router.path = [.productDetails(handle: "external")]
        #expect(router.path == [.productDetails(handle: "external")])
    }
}
