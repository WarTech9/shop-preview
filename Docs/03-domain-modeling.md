# 03 — Domain Modeling

## Principles

- **Value types only** for the domain. Reference types are reserved for observable services (`CartStore`, `Router`).
- **`Sendable` everywhere** so concurrency is free.
- **`Decimal` for money**, never `Double`. Currency is part of the type, not a string parallel to it.
- **`Identifiable` keys come from the wire** (`id` strings) — stable across reloads, suitable for `ForEach`.
- **Make illegal states unrepresentable.** Variant selection is an enum, not a bag of optionals. Cart lines reference a variant that already encodes all its options.
- **DTOs ≠ Domain.** `Data` decodes Shopify wire types into DTOs, then maps to domain. The view layer never sees the wire.

## Types

```swift
// MARK: Money
public struct Money: Hashable, Sendable {
    public let amount: Decimal
    public let currencyCode: String   // ISO 4217, e.g. "CAD"
}

public struct PriceRange: Hashable, Sendable {
    public let min: Money
    public let max: Money
    public var isSingle: Bool { min == max }
}

// MARK: Product
public struct Product: Identifiable, Hashable, Sendable {
    public let id: String              // Shopify GID
    public let handle: String          // routing key
    public let title: String
    public let vendor: String
    public let description: String
    public let isAvailable: Bool
    public let priceRange: PriceRange
    public let compareAtPriceRange: PriceRange?
    public let images: [ProductImage]  // non-empty in practice; we don't crash if empty
    public let options: [ProductOption]
    public let variants: [ProductVariant]
}

public struct ProductImage: Identifiable, Hashable, Sendable {
    public let id: String
    public let url: URL
}

public struct ProductOption: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String            // "Color", "Size"
    public let values: [String]
}

// MARK: Variant
public struct ProductVariant: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let isAvailable: Bool
    public let price: Money
    public let compareAtPrice: Money?
    public let selectedOptions: [SelectedOption]   // [{name:"Color", value:"Black"}, ...]
    public let imageId: String?                    // join key to Product.images
}

public struct SelectedOption: Hashable, Sendable {
    public let name: String
    public let value: String
}

// MARK: Cart
public struct CartLine: Identifiable, Hashable, Sendable {
    public var id: String { variant.id }      // variant uniquely identifies a line
    public let product: Product
    public let variant: ProductVariant
    public var quantity: Int
    public var lineTotal: Money { Money(amount: variant.price.amount * Decimal(quantity),
                                        currencyCode: variant.price.currencyCode) }
}

public struct Cart: Hashable, Sendable {
    public private(set) var lines: [CartLine] = []
    public var itemCount: Int { lines.reduce(0) { $0 + $1.quantity } }
    public var subtotal: Money { /* sum lineTotal, asserting single currency */ }
    public var total: Money { subtotal }   // no taxes/shipping in scope
}
```

## Selection logic

Variant resolution lives on `Product`, not on the VM, so it's testable without UI:

```swift
extension Product {
    /// All option values that, given the current partial selection, can still resolve to an available variant.
    func availableValues(for option: ProductOption,
                         given selection: [String: String]) -> Set<String>

    /// Resolve a complete selection to a variant (or nil if incomplete / unmatched).
    func variant(matching selection: [String: String]) -> ProductVariant?
}
```

This drives both the picker disabled-state (F3.3) and the "Add to Cart" enabled-state (F3.4).

## Mutations

Mutation is concentrated:

- `Cart.add(_ variant: ProductVariant, of product: Product)` — creates a line or increments existing.
- `Cart.setQuantity(_:for:)` — clamps to ≥ 0; quantity 0 removes the line.

`CartStore` (in `Services`) wraps `var cart: Cart` and forwards. This keeps math in pure domain code, tested without the observable wrapper.

## DTO → Domain mapping

`Data/DTOs/ProductDTO.swift` mirrors the Shopify wire shape (snake-cased helpers where needed). A free function `func makeProduct(_ dto: ProductDTO) -> Product?` performs the mapping and returns `nil` for products that fail invariants (no variants, malformed price). The repository skips those and logs a warning — one bad row doesn't take down the catalog.

## Fields intentionally dropped (and why)

| Wire field | Reason |
|---|---|
| `descriptionHtml` | We render plain `description`; HTML rendering is out of scope. |
| `media[]` | `images[]` is sufficient for the carousel; `media` adds video types we don't render. |
| `tags`, `productType` | No filtering / search in scope. |
| `requiresSellingPlan` | No subscription flow. |
| `onlineStoreUrl` | We're not deep-linking out of the Clip. |
| `sku`, `quantityAvailable` | Inventory is reflected via `availableForSale` only. |

## Test surface

- `Money` arithmetic + currency invariants.
- `PriceRange.isSingle`.
- `Product.variant(matching:)` and `availableValues(for:given:)` — table-driven tests across the supplied feed.
- `Cart` add / increment / setQuantity / totals.
- DTO decoding + mapping (fixture = the live gist payload, snapshotted to `Tests/Fixtures/products.json`).
