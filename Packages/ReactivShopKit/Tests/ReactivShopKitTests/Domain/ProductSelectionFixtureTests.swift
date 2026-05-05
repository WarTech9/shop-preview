import Testing
import Foundation
@testable import ReactivShopKit

@Suite struct ProductSelectionFixtureTests {
    private func loadHoodie() throws -> Product {
        let data = try FixtureLoader.loadProductsJSON()
        let dtos = try JSONDecoder().decode([ProductDTO].self, from: data)
        return try #require(dtos.compactMap(makeProduct).first { $0.handle == "unisex-hoodie" })
    }

    @Test func availableValues_noSelection_returnsValuesBackedByAvailableVariants() throws {
        let hoodie = try loadHoodie()
        let colorOpt = try #require(hoodie.options.first { $0.name == "Color" })
        let sizeOpt = try #require(hoodie.options.first { $0.name == "Size" })
        #expect(!hoodie.availableValues(for: colorOpt, given: [:]).isEmpty)
        #expect(!hoodie.availableValues(for: sizeOpt, given: [:]).isEmpty)
    }

    @Test func availableValues_withColorBlack_excludesUnavailableSizes() throws {
        let hoodie = try loadHoodie()
        let sizeOpt = try #require(hoodie.options.first { $0.name == "Size" })
        let sizes = hoodie.availableValues(for: sizeOpt, given: ["Color": "Black"])
        // Acceptance check (Docs/01 F3): Black/S is the unavailable combination on this product.
        #expect(!sizes.contains("S"))
    }

    @Test func variantMatching_resolvesAcceptanceCheckCase_isUnavailable() throws {
        let hoodie = try loadHoodie()
        // Per Docs/01 F3: selecting Color=Black, Size=S on Unisex Hoodie resolves to a variant
        // whose isAvailable is false (drives the disabled Add-to-Cart state).
        let variant = try #require(hoodie.variant(matching: ["Color": "Black", "Size": "S"]))
        #expect(variant.isAvailable == false)
    }

    @Test func variantMatching_returnsNilForCombinationNotInFeed() throws {
        let hoodie = try loadHoodie()
        #expect(hoodie.variant(matching: ["Color": "Magenta", "Size": "S"]) == nil)
    }
}
