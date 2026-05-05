import Foundation
import Observation
import ReactiveShopKit

@MainActor
@Observable
public final class CartViewModel {
    private let cart: CartStoring

    public init(cart: CartStoring) {
        self.cart = cart
    }

    // Computed forwards — observation tracking propagates through the chain to the
    // underlying `@Observable CartStore`, so SwiftUI re-renders on cart mutations.
    public var lines: [CartLine] { cart.cart.lines }
    public var subtotal: Money? { cart.cart.subtotal }
    public var total: Money? { cart.cart.total }
    public var itemCount: Int { cart.cart.itemCount }
    public var isEmpty: Bool { cart.cart.lines.isEmpty }

    public func setQuantity(_ quantity: Int, for lineId: String) {
        cart.setQuantity(quantity, for: lineId)
    }

    /// Convenience for swipe-to-delete; reduces to the canonical `setQuantity(0, ...)` path.
    public func remove(_ lineId: String) {
        cart.setQuantity(0, for: lineId)
    }
}
