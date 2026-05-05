import Foundation

public struct Product: Identifiable, Hashable, Sendable {
    public let id: String
    public let handle: String
    public let title: String
    public let vendor: String
    public let description: String
    public let isAvailable: Bool
    public let priceRange: PriceRange
    public let compareAtPriceRange: PriceRange?
    public let images: [ProductImage]
    public let options: [ProductOption]
    public let variants: [ProductVariant]

    public init(
        id: String,
        handle: String,
        title: String,
        vendor: String,
        description: String,
        isAvailable: Bool,
        priceRange: PriceRange,
        compareAtPriceRange: PriceRange?,
        images: [ProductImage],
        options: [ProductOption],
        variants: [ProductVariant]
    ) {
        self.id = id
        self.handle = handle
        self.title = title
        self.vendor = vendor
        self.description = description
        self.isAvailable = isAvailable
        self.priceRange = priceRange
        self.compareAtPriceRange = compareAtPriceRange
        self.images = images
        self.options = options
        self.variants = variants
    }
}

public struct ProductImage: Identifiable, Hashable, Sendable {
    public let id: String
    public let url: URL

    public init(id: String, url: URL) {
        self.id = id
        self.url = url
    }
}

public struct ProductOption: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let values: [String]

    public init(id: String, name: String, values: [String]) {
        self.id = id
        self.name = name
        self.values = values
    }
}
