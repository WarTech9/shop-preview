# 01 — Requirements → Technical Spec

Source: `Instructions.pdf` (Take Home Challenge — iOS V2). This doc translates the brief into numbered, testable requirements.

## Scope

A SwiftUI **App Clip** for a Shopify-like storefront. Users browse products, view a product, pick a variant, add it to a cart, and manage the cart — all without installing the parent app. Parent app exists as a thin shell hosting the same screens (so the work is reusable, not duplicated).

## Functional requirements

### F1. Invocation

| # | Invocation URL | Behavior |
|---|---|---|
| F1.1 | `https://shop.reactivapp.com/collections/all` | Open Catalog, load product feed |
| F1.2 | `https://shop.reactivapp.com/product/{handle}` | Open Product Details for the matching `handle` |
| F1.3 | Any other URL or no URL | Fall back to Catalog |

- URLs arrive via `_XCAppClipURL` (development) and `onContinueUserActivity(NSUserActivityTypeBrowsingWeb)` (runtime).
- External Associated-Domains setup is **out of scope** (per brief).
- Routing must be deterministic and unit-testable (no view-layer URL parsing).

### F2. Catalog

- F2.1 Fetch product list from the hosted JSON feed (gist URL provided in brief).
- F2.2 Render every product with: primary image, title, price (formatted with currency), availability indicator when `availableForSale == false`.
- F2.3 Tapping a product pushes Product Details for that product.
- F2.4 Loading, empty, and error states are distinct, with a retry affordance on error.

### F3. Product Details

- F3.1 Show: image carousel (all `images[]`), title, vendor, description, price (or price range when variants differ), compare-at price when present.
- F3.2 Render a picker per `option` (e.g. Color, Size). Selecting a value resolves to a single `variant` via `variant.selectedOptions`.
- F3.3 Disable option values whose resulting variant has `availableForSale == false`.
- F3.4 "Add to Cart" enabled only when a fully-resolved, available variant is selected. Tapping adds 1 of that variant to the cart.
- F3.5 Reflect the currently selected variant's price and image in the header.

### F4. Cart

- F4.1 List each `CartLine` with product title, variant title, unit price, quantity, line total.
- F4.2 Quantity stepper: increment must work; decrement + remove are not in the brief but are added because a stepper without a decrement is hostile UX (called out in Decision Log).
- F4.3 Display: subtotal, total price, total item count.
- F4.4 Empty state when cart is empty, with a CTA back to the Catalog.

## Data contract

Source: live JSON gist (Shopify Storefront shape). Fields the app **consumes**:

- `Product`: `id`, `handle`, `title`, `vendor`, `description`, `availableForSale`, `priceRange.{min,max}VariantPrice.{amount,currencyCode}`, `compareAtPriceRange.*`, `images[].{id,url}`, `options[].{id,name,values[]}`, `variants[]`.
- `Variant`: `id`, `title`, `availableForSale`, `quantityAvailable`, `price.{amount,currencyCode}`, `compareAtPrice.{amount,currencyCode}?`, `selectedOptions[].{name,value}`, `image.{id,url}?`.

Fields ignored: `descriptionHtml`, `media[]` (we use `images[]`), `tags`, `productType`, `requiresSellingPlan`, `onlineStoreUrl`, `sku`, GIDs beyond use as identifiers.

`amount` strings are parsed as `Decimal`. `currencyCode` is required; mixing currencies in one cart is treated as a programming error (asserted; will not occur in the supplied dataset).

### TBD
- `description` vs `descriptionHtml`. Will review  which looks better. If html we can use NSAttributedString with `options: [.documentType: NSAttributedString.DocumentType.html]`.

## Non-functional requirements

- **Performance:** first product visible within 1s on a warm cache; image scrolling at 60fps on iPhone 12+.
- **Accessibility:** every interactive control reachable by VoiceOver with a meaningful label; Dynamic Type up to XXL doesn't truncate critical text; hit targets ≥ 44pt.
- **Resilience:** network failure shows a retryable error; malformed JSON surfaces a clear message and does not crash.
- **Predictable state:** cart and routing state are observable, single-sourced, and unit-testable.

## Explicit non-goals

Checkout, payment, authentication, search, filtering, sorting, persistence across launches, push notifications, analytics, localization beyond `Locale.current` price formatting, accounts/wishlist, parent-app feature parity beyond hosting the same screens.

## Acceptance checks (mapped to F#)

- F1: launch with `_XCAppClipURL=…/product/unisex-hoodie` opens Details for that handle; with `…/collections/all` opens Catalog; with junk URL opens Catalog.
- F2: with the supplied feed, the catalog shows N rows where N == products in the feed; tap row N opens Details for product N.
- F3: selecting Color=Black, Size=S on "Unisex Hoodie" resolves to the variant with that pair; "Add to Cart" disabled when that variant is `availableForSale == false`.
- F4: adding the same variant twice yields one line with quantity 2; subtotal = unit × 2; item count = 2.
