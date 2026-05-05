import Foundation
import Observation

@MainActor
@Observable
public final class CartStore: CartStoring {
    public private(set) var cart: Cart = Cart()

    public init() {}

    public func add(_ variant: ProductVariant, of product: Product) throws {
        try cart.add(variant, of: product)
    }

    public func setQuantity(_ quantity: Int, for lineId: String) {
        cart.setQuantity(quantity, for: lineId)
    }
}
