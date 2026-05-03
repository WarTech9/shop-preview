import Testing
import Foundation
@testable import ReactiveShopKit

@Suite struct ProductMappingTests {
    private func loadAllMapped() throws -> [Product] {
        let data = try FixtureLoader.loadProductsJSON()
        let dtos = try JSONDecoder().decode([ProductDTO].self, from: data)
        return dtos.compactMap(makeProduct)
    }

    @Test func happyPath_mapsEveryFixtureProduct() throws {
        let products = try loadAllMapped()
        #expect(products.count == 4)
    }

    @Test func happyPath_priceRangeRoundTripsAsDecimal() throws {
        let products = try loadAllMapped()
        let hoodie = try #require(products.first { $0.handle == "unisex-hoodie" })
        #expect(hoodie.priceRange.min == Money(amount: Decimal(string: "28.52")!, currencyCode: "CAD"))
        #expect(hoodie.priceRange.max == Money(amount: Decimal(string: "32.09")!, currencyCode: "CAD"))
    }

    @Test func happyPath_optionsAndVariantsAndImagesPopulated() throws {
        let products = try loadAllMapped()
        let hoodie = try #require(products.first { $0.handle == "unisex-hoodie" })
        #expect(hoodie.options.count == 2)
        #expect(hoodie.variants.count > 0)
        #expect(hoodie.images.count > 0)
    }

    @Test func failure_invalidPriceRangeAmount_returnsNil() {
        let bad = MoneyDTO(amount: "not-a-number", currencyCode: "CAD")
        let dto = ProductDTO(
            id: "p1", handle: "p", title: "P", vendor: "V", description: "",
            availableForSale: true,
            priceRange: PriceRangeDTO(minVariantPrice: bad, maxVariantPrice: bad),
            compareAtPriceRange: nil,
            images: [], options: [],
            variants: [VariantDTO(
                id: "v1", title: "V", availableForSale: true,
                price: bad, compareAtPrice: nil, selectedOptions: [], image: nil
            )]
        )
        #expect(makeProduct(dto) == nil)
    }

    @Test func failure_emptyVariants_returnsNil() {
        let m = MoneyDTO(amount: "10.00", currencyCode: "CAD")
        let dto = ProductDTO(
            id: "p1", handle: "p", title: "P", vendor: "V", description: "",
            availableForSale: true,
            priceRange: PriceRangeDTO(minVariantPrice: m, maxVariantPrice: m),
            compareAtPriceRange: nil,
            images: [], options: [], variants: []
        )
        #expect(makeProduct(dto) == nil)
    }

    @Test func failure_allVariantsHaveBadPrices_returnsNil() {
        let good = MoneyDTO(amount: "10.00", currencyCode: "CAD")
        let bad = MoneyDTO(amount: "wat", currencyCode: "CAD")
        let dto = ProductDTO(
            id: "p1", handle: "p", title: "P", vendor: "V", description: "",
            availableForSale: true,
            priceRange: PriceRangeDTO(minVariantPrice: good, maxVariantPrice: good),
            compareAtPriceRange: nil,
            images: [], options: [],
            variants: [VariantDTO(
                id: "v1", title: "V", availableForSale: true,
                price: bad, compareAtPrice: nil, selectedOptions: [], image: nil
            )]
        )
        #expect(makeProduct(dto) == nil)
    }

    @Test func malformedImageURL_isDroppedSilently_productSurvives() throws {
        let m = MoneyDTO(amount: "10.00", currencyCode: "CAD")
        let dto = ProductDTO(
            id: "p1", handle: "p", title: "P", vendor: "V", description: "",
            availableForSale: true,
            priceRange: PriceRangeDTO(minVariantPrice: m, maxVariantPrice: m),
            compareAtPriceRange: nil,
            images: [
                ImageDTO(id: "i1", url: ""),  // malformed → dropped
                ImageDTO(id: "i2", url: "https://example.com/x.jpg"),
            ],
            options: [],
            variants: [VariantDTO(
                id: "v1", title: "V", availableForSale: true,
                price: m, compareAtPrice: nil, selectedOptions: [], image: nil
            )]
        )
        let product = try #require(makeProduct(dto))
        #expect(product.images.count == 1)
        #expect(product.images.first?.id == "i2")
    }
}
