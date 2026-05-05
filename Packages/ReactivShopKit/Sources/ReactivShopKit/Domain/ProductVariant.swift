import Foundation

public struct ProductVariant: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let isAvailable: Bool
    public let price: Money
    public let compareAtPrice: Money?
    public let selectedOptions: [SelectedOption]
    public let imageId: String?

    public init(
        id: String,
        title: String,
        isAvailable: Bool,
        price: Money,
        compareAtPrice: Money?,
        selectedOptions: [SelectedOption],
        imageId: String?
    ) {
        self.id = id
        self.title = title
        self.isAvailable = isAvailable
        self.price = price
        self.compareAtPrice = compareAtPrice
        self.selectedOptions = selectedOptions
        self.imageId = imageId
    }
}

public struct SelectedOption: Hashable, Sendable {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}
