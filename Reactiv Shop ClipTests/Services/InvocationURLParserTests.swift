import Testing
import Foundation
@testable import ReactivShopKit

@Suite struct InvocationURLParserTests {

    // MARK: - happy paths

    @Test func collectionsAll_returnsCatalog() {
        #expect(InvocationURLParser.destination(for: URL(string: "https://shop.reactivapp.com/collections/all")!) == .catalog)
    }

    @Test func productHandle_returnsProductDetails() {
        #expect(InvocationURLParser.destination(for: URL(string: "https://shop.reactivapp.com/product/unisex-hoodie")!)
                == .productDetails(handle: "unisex-hoodie"))
    }

    // MARK: - tolerance

    @Test func trailingSlash_collectionsAll() {
        #expect(InvocationURLParser.destination(for: URL(string: "https://shop.reactivapp.com/collections/all/")!) == .catalog)
    }

    @Test func trailingSlash_product() {
        #expect(InvocationURLParser.destination(for: URL(string: "https://shop.reactivapp.com/product/foo/")!)
                == .productDetails(handle: "foo"))
    }

    @Test func httpScheme_fallsBackToCatalog() {
        // Parser is https-only; http invocations are not honored.
        #expect(InvocationURLParser.destination(for: URL(string: "http://shop.reactivapp.com/product/foo")!) == .catalog)
        #expect(InvocationURLParser.destination(for: URL(string: "http://shop.reactivapp.com/collections/all")!) == .catalog)
    }

    @Test func mixedCaseHost_isAccepted() {
        #expect(InvocationURLParser.destination(for: URL(string: "https://SHOP.ReactivApp.com/product/foo")!)
                == .productDetails(handle: "foo"))
    }

    @Test func queryStringIgnored() {
        #expect(InvocationURLParser.destination(for: URL(string: "https://shop.reactivapp.com/product/foo?utm=test&ref=abc")!)
                == .productDetails(handle: "foo"))
    }

    @Test func fragmentIgnored() {
        #expect(InvocationURLParser.destination(for: URL(string: "https://shop.reactivapp.com/collections/all#top")!)
                == .catalog)
    }

    // MARK: - fallback to catalog

    @Test func wrongHost_fallsBackToCatalog() {
        #expect(InvocationURLParser.destination(for: URL(string: "https://example.com/product/foo")!) == .catalog)
        #expect(InvocationURLParser.destination(for: URL(string: "https://shop.example.com/product/foo")!) == .catalog)
    }

    @Test func wrongScheme_fallsBackToCatalog() {
        #expect(InvocationURLParser.destination(for: URL(string: "ftp://shop.reactivapp.com/product/foo")!) == .catalog)
        #expect(InvocationURLParser.destination(for: URL(string: "file:///product/foo")!) == .catalog)
    }

    @Test func emptyHandle_fallsBackToCatalog() {
        #expect(InvocationURLParser.destination(for: URL(string: "https://shop.reactivapp.com/product/")!) == .catalog)
    }

    @Test func missingHandle_fallsBackToCatalog() {
        #expect(InvocationURLParser.destination(for: URL(string: "https://shop.reactivapp.com/product")!) == .catalog)
    }

    @Test func extraSegments_fallBackToCatalog() {
        #expect(InvocationURLParser.destination(for: URL(string: "https://shop.reactivapp.com/product/foo/bar")!) == .catalog)
        #expect(InvocationURLParser.destination(for: URL(string: "https://shop.reactivapp.com/collections/all/extra")!) == .catalog)
    }

    @Test func unknownPath_fallsBackToCatalog() {
        #expect(InvocationURLParser.destination(for: URL(string: "https://shop.reactivapp.com/")!) == .catalog)
        #expect(InvocationURLParser.destination(for: URL(string: "https://shop.reactivapp.com/about")!) == .catalog)
        #expect(InvocationURLParser.destination(for: URL(string: "https://shop.reactivapp.com/cart")!) == .catalog)
    }

    @Test func noSchemeOrHost_fallsBackToCatalog() {
        #expect(InvocationURLParser.destination(for: URL(string: "garbage")!) == .catalog)
        #expect(InvocationURLParser.destination(for: URL(string: "/product/foo")!) == .catalog)
    }

    @Test func collectionsButNotAll_fallsBackToCatalog() {
        #expect(InvocationURLParser.destination(for: URL(string: "https://shop.reactivapp.com/collections/featured")!) == .catalog)
    }
}
