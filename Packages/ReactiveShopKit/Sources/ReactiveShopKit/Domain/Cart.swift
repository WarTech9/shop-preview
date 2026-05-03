import Foundation

public enum CartError: Error, Equatable {
    case currencyMismatch
}

public struct CartLine: Identifiable, Hashable, Sendable {
    public let product: Product
    public let variant: ProductVariant
    public var quantity: Int

    public init(product: Product, variant: ProductVariant, quantity: Int) {
        self.product = product
        self.variant = variant
        self.quantity = quantity
    }

    public var id: String { variant.id }

    public var lineTotal: Money {
        Money(
            amount: variant.price.amount * Decimal(quantity),
            currencyCode: variant.price.currencyCode
        )
    }
}

public struct Cart: Hashable, Sendable {
    public private(set) var lines: [CartLine]

    public init(lines: [CartLine] = []) {
        self.lines = lines
    }

    public var itemCount: Int { lines.reduce(0) { $0 + $1.quantity } }

    public var subtotal: Money? {
        guard let first = lines.first else { return nil }
        let amount = lines.reduce(Decimal(0)) { $0 + $1.lineTotal.amount }
        return Money(amount: amount, currencyCode: first.variant.price.currencyCode)
    }

    public var total: Money? { subtotal }

    public mutating func add(_ variant: ProductVariant, of product: Product) throws {
        if let first = lines.first,
           first.variant.price.currencyCode != variant.price.currencyCode {
            throw CartError.currencyMismatch
        }
        if let idx = lines.firstIndex(where: { $0.variant.id == variant.id }) {
            lines[idx].quantity += 1
        } else {
            lines.append(CartLine(product: product, variant: variant, quantity: 1))
        }
    }

    public mutating func setQuantity(_ quantity: Int, for lineId: String) {
        guard let idx = lines.firstIndex(where: { $0.id == lineId }) else { return }
        let clamped = Swift.max(0, quantity)
        if clamped == 0 {
            lines.remove(at: idx)
        } else {
            lines[idx].quantity = clamped
        }
    }
}
