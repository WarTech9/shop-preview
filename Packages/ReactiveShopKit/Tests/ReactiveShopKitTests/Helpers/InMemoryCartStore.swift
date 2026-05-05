import Foundation
@testable import ReactiveShopKit

/// Test double for `CartStoring`. Pure value-type cart wrapped in a class so we can
/// observe interaction counts without standing up the real `@Observable` runtime.
@MainActor
final class InMemoryCartStore: CartStoring {
    private(set) var cart: Cart = Cart()
    private(set) var addCallCount: Int = 0
    private(set) var setQuantityCallCount: Int = 0

    func add(_ variant: ProductVariant, of product: Product) throws {
        addCallCount += 1
        try cart.add(variant, of: product)
    }

    func setQuantity(_ quantity: Int, for lineId: String) {
        setQuantityCallCount += 1
        cart.setQuantity(quantity, for: lineId)
    }
}
