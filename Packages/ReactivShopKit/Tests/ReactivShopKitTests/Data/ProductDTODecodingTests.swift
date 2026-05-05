import Testing
import Foundation
@testable import ReactivShopKit

@Suite struct ProductDTODecodingTests {
    @Test func decodesAllFixtureProducts() throws {
        let data = try FixtureLoader.loadProductsJSON()
        let dtos = try JSONDecoder().decode([ProductDTO].self, from: data)
        #expect(dtos.count == 4)
    }

    @Test func decodesRepresentativeWireFields() throws {
        let data = try FixtureLoader.loadProductsJSON()
        let dtos = try JSONDecoder().decode([ProductDTO].self, from: data)
        let hoodie = try #require(dtos.first { $0.handle == "unisex-hoodie" })
        #expect(hoodie.title == "Unisex Hoodie")
        #expect(hoodie.priceRange.minVariantPrice.currencyCode == "CAD")
        #expect(hoodie.priceRange.minVariantPrice.amount == "28.52")
        #expect(hoodie.options.count == 2)
        #expect(hoodie.variants.count > 0)
    }

    @Test func decodesIgnoresUnknownWireKeys() throws {
        // descriptionHtml, tags, productType, requiresSellingPlan, onlineStoreUrl, media
        // all live in the wire format but aren't declared on ProductDTO. JSONDecoder should
        // ignore them silently — verifying the fixture decodes proves this.
        let data = try FixtureLoader.loadProductsJSON()
        _ = try JSONDecoder().decode([ProductDTO].self, from: data)
    }
}
