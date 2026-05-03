import Testing
import Foundation
@testable import ReactiveShopKit

@Suite struct RouterTests {

    // MARK: - parse(_:) — happy paths

    @Test func parse_collectionsAll_returnsCatalog() {
        #expect(Router.parse(URL(string: "https://shop.reactivapp.com/collections/all")!) == .catalog)
    }

    @Test func parse_productHandle_returnsProduct() {
        #expect(Router.parse(URL(string: "https://shop.reactivapp.com/product/unisex-hoodie")!)
                == .product(handle: "unisex-hoodie"))
    }

    // MARK: - parse(_:) — tolerance

    @Test func parse_trailingSlash_collectionsAll_returnsCatalog() {
        #expect(Router.parse(URL(string: "https://shop.reactivapp.com/collections/all/")!) == .catalog)
    }

    @Test func parse_trailingSlash_product_returnsProduct() {
        #expect(Router.parse(URL(string: "https://shop.reactivapp.com/product/foo/")!)
                == .product(handle: "foo"))
    }

    @Test func parse_httpScheme_isAccepted() {
        #expect(Router.parse(URL(string: "http://shop.reactivapp.com/product/foo")!)
                == .product(handle: "foo"))
    }

    @Test func parse_mixedCaseHost_isAccepted() {
        #expect(Router.parse(URL(string: "https://SHOP.ReactivApp.com/product/foo")!)
                == .product(handle: "foo"))
    }

    @Test func parse_queryStringIgnored() {
        #expect(Router.parse(URL(string: "https://shop.reactivapp.com/product/foo?utm=test&ref=abc")!)
                == .product(handle: "foo"))
    }

    @Test func parse_fragmentIgnored() {
        #expect(Router.parse(URL(string: "https://shop.reactivapp.com/collections/all#top")!)
                == .catalog)
    }

    // MARK: - parse(_:) — fallback to catalog

    @Test func parse_wrongHost_fallsBackToCatalog() {
        #expect(Router.parse(URL(string: "https://example.com/product/foo")!) == .catalog)
        #expect(Router.parse(URL(string: "https://shop.example.com/product/foo")!) == .catalog)
    }

    @Test func parse_wrongScheme_fallsBackToCatalog() {
        #expect(Router.parse(URL(string: "ftp://shop.reactivapp.com/product/foo")!) == .catalog)
        #expect(Router.parse(URL(string: "file:///product/foo")!) == .catalog)
    }

    @Test func parse_emptyHandle_fallsBackToCatalog() {
        // /product/ with trailing slash collapses to a single segment after filtering.
        #expect(Router.parse(URL(string: "https://shop.reactivapp.com/product/")!) == .catalog)
    }

    @Test func parse_missingHandle_fallsBackToCatalog() {
        #expect(Router.parse(URL(string: "https://shop.reactivapp.com/product")!) == .catalog)
    }

    @Test func parse_extraSegments_fallsBackToCatalog() {
        #expect(Router.parse(URL(string: "https://shop.reactivapp.com/product/foo/bar")!) == .catalog)
        #expect(Router.parse(URL(string: "https://shop.reactivapp.com/collections/all/extra")!) == .catalog)
    }

    @Test func parse_unknownPath_fallsBackToCatalog() {
        #expect(Router.parse(URL(string: "https://shop.reactivapp.com/")!) == .catalog)
        #expect(Router.parse(URL(string: "https://shop.reactivapp.com/about")!) == .catalog)
        #expect(Router.parse(URL(string: "https://shop.reactivapp.com/cart")!) == .catalog)
    }

    @Test func parse_noSchemeOrHost_fallsBackToCatalog() {
        // Relative URL strings with no scheme/host parse but fail the guards.
        #expect(Router.parse(URL(string: "garbage")!) == .catalog)
        #expect(Router.parse(URL(string: "/product/foo")!) == .catalog)
    }

    @Test func parse_collectionsButNotAll_fallsBackToCatalog() {
        #expect(Router.parse(URL(string: "https://shop.reactivapp.com/collections/featured")!) == .catalog)
    }

    // MARK: - handle(url:) integration

    @MainActor
    @Test func handle_updatesRouteToParsedValue() {
        let router = Router()
        #expect(router.route == .catalog)

        router.handle(url: URL(string: "https://shop.reactivapp.com/product/unisex-hoodie")!)
        #expect(router.route == .product(handle: "unisex-hoodie"))

        router.handle(url: URL(string: "https://shop.reactivapp.com/collections/all")!)
        #expect(router.route == .catalog)
    }

    @MainActor
    @Test func handle_unknownURL_resetsToCatalog() {
        let router = Router()
        router.handle(url: URL(string: "https://shop.reactivapp.com/product/foo")!)
        #expect(router.route == .product(handle: "foo"))

        router.handle(url: URL(string: "https://example.com/anything")!)
        #expect(router.route == .catalog)
    }
}
