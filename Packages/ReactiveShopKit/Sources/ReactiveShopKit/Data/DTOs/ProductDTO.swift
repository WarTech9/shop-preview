import Foundation

struct ProductDTO: Codable, Sendable {
    let id: String
    let handle: String
    let title: String
    let vendor: String
    let description: String
    let availableForSale: Bool
    let priceRange: PriceRangeDTO
    let compareAtPriceRange: PriceRangeDTO?
    let images: [ImageDTO]
    let options: [OptionDTO]
    let variants: [VariantDTO]
}

struct VariantDTO: Codable, Sendable {
    let id: String
    let title: String
    let availableForSale: Bool
    let price: MoneyDTO
    let compareAtPrice: MoneyDTO?
    let selectedOptions: [SelectedOptionDTO]
    let image: VariantImageRefDTO?
}

struct OptionDTO: Codable, Sendable {
    let id: String
    let name: String
    let values: [String]
}

struct ImageDTO: Codable, Sendable {
    let id: String
    let url: String
}

struct MoneyDTO: Codable, Sendable {
    let amount: String
    let currencyCode: String
}

struct PriceRangeDTO: Codable, Sendable {
    let minVariantPrice: MoneyDTO
    let maxVariantPrice: MoneyDTO
}

struct SelectedOptionDTO: Codable, Sendable {
    let name: String
    let value: String
}

struct VariantImageRefDTO: Codable, Sendable {
    let id: String
}
