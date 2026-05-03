# 08 — Implementation Plan

**Status (2026-05-03):** Steps 0–3 complete. Next: **Step 4 — Services**.

Sequenced build order. Each step has a clear **Done when** so progress is unambiguous. Steps are ordered so every step lands on top of a green build, with tests where the code under test is non-trivial.

The order is bottom-up (Domain → Data → Services → Features → App) so each layer is fully testable before its consumer is built. UI lands last, on top of a tested core.

When a step completes, append a `✅ Completed (<date>)` block under it noting what landed and any deviations from the original step text. Future sessions read these blocks to resume cleanly.

## Step 0 — Repository scaffolding

- Capture the live JSON gist as `Packages/ReactiveShopKit/Tests/ReactiveShopKitTests/Fixtures/products.json` (committed, used by all decoding/mapping tests).
- Add `.gitignore` entries for Xcode user state if missing.

**Done when:** fixture file exists; `git status` is clean apart from intentional changes.

### ✅ Completed (2026-05-03)

- `.gitignore` written at repo root (macOS, Xcode, SwiftPM, IDE, plus `Instructions.pdf` since the brief stays local).
- Fixture pinned to a specific gist commit URL (so it can't drift) and saved to `Packages/ReactiveShopKit/Tests/ReactiveShopKitTests/Fixtures/products.json` (4 products: `unisex-hoodie`, `reactiv-hoodie`, `unisex-heavy-blend-full-zip-hooded-sweatshirt-white`, `unisex-heavy-blend-full-zip-hooded-sweatshirt-black`).
- Sibling `Fixtures/README.md` documents source URL + capture date.
- Existing committed `xcuserdata/` files **not** removed — flagged as a separate destructive change pending explicit approval.

## Step 1 — Local SPM package + Xcode wiring

- Create `Packages/ReactiveShopKit/Package.swift` (single product, single target, single test target). iOS platform set to match the project's deployment target.
- Add the package to `Reactive Shop.xcodeproj` as a local package reference; link `ReactiveShopKit` to both app targets (`Reactive Shop`, `Reactive Shop Clip`) and to both unit test hosts.
- Replace both `@main` files with the smallest possible body that imports `ReactiveShopKit` and shows a placeholder `Text("ReactiveShopKit linked")`.

**Done when:** both schemes build; both apps launch in the simulator and display the placeholder; `xcodebuild ... test` runs (with zero tests) green from each scheme.

### ✅ Completed (2026-05-03)

- `Packages/ReactiveShopKit/Package.swift` declares `swift-tools-version: 6.0`, platforms `[.iOS(.v17), .macOS(.v14)]` (macOS minimum is required because `swift test` runs on the host and `Task` needs macOS 10.15+; was added later when Step 3's actor failed to compile without it).
- One library product, one source target, one test target. Fixtures wired via `.copy("Fixtures")` so `Bundle.module` exposes them in tests.
- Placeholder `Sources/ReactiveShopKit/ReactiveShopKit.swift` defines `public enum ReactiveShopKit { public static let placeholder = "ReactiveShopKit linked" }`. **Still present** — both `@main` files reference it; will be removed in Step 5 when `CompositionRoot.makeRoot()` lands.
- Local package added to `Reactive Shop.xcodeproj` via Xcode's `Add Local…` flow (user); linked to all four targets (`Reactive Shop`, `Reactive Shop Clip`, `Reactive ShopTests`, `Reactive Shop ClipTests`).
- Both `@main` files (`Reactive Shop/Reactive_ShopApp.swift`, `Reactive Shop Clip/Reactive_Shop_ClipApp.swift`) replaced; both schemes build clean.
- **Note:** simulator name in build commands is **iPhone 17** (not iPhone 16 — only iPhone 17 family is installed). CLAUDE.md updated to match.

## Step 2 — Domain layer

Files under `Sources/ReactiveShopKit/Domain/`: `Money`, `PriceRange`, `Product`, `ProductImage`, `ProductOption`, `ProductVariant`, `SelectedOption`, `CartLine`, `Cart`, `ProductSelection` (extension on `Product`).

Tests under `Tests/ReactiveShopKitTests/Domain/` (Swift Testing):

- `MoneyTests` — equality, currency mismatch trap, `Decimal` arithmetic correctness.
- `PriceRangeTests` — `isSingle`.
- `ProductSelectionTests` — table-driven over the fixture: every product, every partial selection, expected `availableValues` and `variant(matching:)`.
- `CartTests` — add new line, increment existing, set quantity (including 0 → remove), totals, item count.

**Done when:** all domain types compile, all domain tests pass, no domain code imports anything outside `Foundation`.

### ✅ Completed (2026-05-03)

20 tests across 4 suites passing. Files under `Packages/ReactiveShopKit/Sources/ReactiveShopKit/Domain/`: `Money.swift`, `PriceRange.swift`, `Product.swift` (Product + ProductImage + ProductOption), `ProductVariant.swift` (ProductVariant + SelectedOption), `Cart.swift` (Cart + CartLine + CartError), `Product+Selection.swift`. Tests: `MoneyTests`, `PriceRangeTests`, `ProductSelectionTests`, `CartTests`. `PlaceholderTests.swift` deleted.

Deviations from `Docs/03`:

- **`Cart.subtotal` and `Cart.total` are `Money?`** — nil when the cart is empty (no inherent currency for a zero amount). Originally specified as non-optional. Cart screen will render the empty state instead of "$0.00" when nil.
- **`Cart.add(_:of:)` is `throws`** — throws `CartError.currencyMismatch` rather than using `precondition`. User chose the throwing path during Step 2 planning (over precondition or silent skip). Failed adds leave the cart unchanged.
- **Filename `Product+Selection.swift`** (was `ProductSelection.swift` in `Docs/06`). Rule in `Docs/06` was relaxed — extensions can use `<Type>+<Topic>` within a layer when it reads more honestly than a topic-named alternative.
- **DTO ↔ Domain mapping uses free functions, not extension methods on DTOs** (and definitely not failable inits on Domain types) — keeps both types as pure data carriers; the relationship lives in the mapping file alone.
- Test data is hand-rolled domain instances (no fixture dependency in Step 2). Fixture-backed selection tests landed in Step 3.

## Step 3 — Data layer (no network)

- `RepositoryError` enum.
- `HTTPClient` protocol + `URLSessionHTTPClient` (thin wrapper exposing one `data(for:)` method).
- DTOs: `ProductDTO`, `VariantDTO`, etc. — exactly the wire shape, `Codable`.
- `ProductDTO+Mapping.swift` — pure `dto -> Product?` functions.
- `ProductsRepository` protocol with `fetchAll() async throws -> [Product]` and `fetch(handle:) async throws -> Product`.
- `RemoteProductsRepository` implementation: holds an `HTTPClient`, the gist `URL`, and a one-shot in-memory cache (`Task<[Product], Error>?`) so concurrent callers share one fetch. `fetch(handle:)` reads from `fetchAll()` and throws `.notFound` if absent.

Tests:

- `ProductDTODecodingTests` — decode `Fixtures/products.json`; assert N products decoded.
- `ProductMappingTests` — spot-check critical fields (price `Decimal`, options/variants count, image URLs valid).
- `RemoteProductsRepositoryTests` — inject a fake `HTTPClient` returning the fixture bytes; assert: success path, `.offline` mapping (throw `URLError(.notConnectedToInternet)`), `.server(500)` mapping, `.decoding` mapping, `.notFound` for unknown handle, *and* that two concurrent `fetchAll()` calls produce **one** HTTP call (cache assertion).

**Done when:** all Data tests pass; no Data code touches `URLSession.shared` directly (only via `HTTPClient`).

### ✅ Completed (2026-05-03)

43 tests across 8 suites passing (20 from Step 2 + 23 new).

Files under `Packages/ReactiveShopKit/Sources/ReactiveShopKit/Data/`: `RepositoryError.swift`, `HTTPClient.swift` (protocol + `URLSessionHTTPClient`), `ProductsRepository.swift` (protocol), `RemoteProductsRepository.swift`, `DTOs/ProductDTO.swift`, `DTOs/ProductDTO+Mapping.swift`. Test helpers: `Tests/ReactiveShopKitTests/Helpers/FixtureLoader.swift`, `Helpers/FakeHTTPClient.swift`. Test files: `Data/ProductDTODecodingTests.swift` (3), `Data/ProductMappingTests.swift` (7), `Data/RemoteProductsRepositoryTests.swift` (9), `Domain/ProductSelectionFixtureTests.swift` (4 — fixture-backed selection tests deferred from Step 2).

Deviations from `Docs/02` and the original Step 3 text:

- **`RemoteProductsRepository` is an `actor`**, not a class with locks. Gives Sendable conformance for free, serializes cache mutation correctly, and lets concurrent callers share one inflight `Task<[Product], Error>?`.
- **Cache invalidates on failure** — a failed fetch clears the inflight task so retry attempts trigger a fresh request (verified by `fetchAll_retryAfterFailure_attemptsFreshRequest`). On success, the result is stored and subsequent `fetchAll()` calls return it without hitting the network.
- **DTO types are `internal` visibility** (no `public`). Apps see only `Product`, `ProductVariant`, etc. — the wire format stays an implementation detail of the Data layer.
- **DTO → Domain mapping is free functions**, not extension methods. `makeProduct(_:)` is the only entry point; helpers (`makeVariant`, `makeMoney`, `makePriceRange`, `makeImage`, `makeOption`) are `private`.
- **Feed URL is injected** via `RemoteProductsRepository(http:feedURL:)`. Build setting + `Bundle.main` lookup deferred to Step 5 (see Step 5 forward note).
- **`HTTPClient` returns `(Data, HTTPURLResponse)`**; status-code mapping (200…299 OK, 400…599 → `.server(code)`, `URLError(.notConnectedToInternet)` → `.offline`, `DecodingError` → `.decoding`, else → `.unknown`) lives in `RemoteProductsRepository.performFetch`.
- **`RepositoryError.notFound` carries the missing handle** (`case notFound(handle: String)`) for the "couldn't find product X" UI in Step 7.
- **`FakeHTTPClient` uses `NSLock.withLock`** (not `lock()`/`unlock()` directly) because Swift 6 strict concurrency forbids `unlock()` in async contexts.
- **Mapping tolerates bad images**: a malformed image URL drops that image but doesn't fail the product. Bad variant prices fail the variant; if no variants survive, the product is dropped.

## Step 4 — Services layer

- `URLRouting` protocol + `Router` (`@Observable @MainActor`) with `Route` enum and `handle(url:)`. Pure parsing helper extracted as a static method for direct testing.
- `CartStoring` protocol + `CartStore` (`@Observable @MainActor`) wrapping `var cart: Cart`. Exposes `add(_:of:)`, `setQuantity(_:for:)`, and read-only `cart`.

Tests:

- `RouterTests` — parametrised matrix over `/collections/all`, `/product/{handle}`, malformed paths, query strings, fragments, http vs https, trailing slashes. Each input maps to the expected `Route`; unknown → `.catalog`.
- `CartStoreTests` — happy paths, idempotence (adding same variant twice = quantity 2), set-to-zero removes line, observable change is emitted (`withObservationTracking`).

**Done when:** all Services tests pass; no Services code imports `SwiftUI`.

## Step 5 — Composition Root + ScreenFactory + RootView

- `LoadState<T>` enum.
- `ScreenFactory` struct of closures.
- `CompositionRoot.makeRoot()` — builds `URLSessionHTTPClient`, `RemoteProductsRepository`, `CartStore`, `Router`, `ScreenFactory`, returns a `RootView` with `.environment` for the three keys.
- `RootView` — `NavigationStack`, switches on `router.route` to push `ProductDetailsView` for `.product(handle:)`, otherwise shows `CatalogView`. A toolbar cart button calls `factory.makeCart()`.

At this step, `CatalogView`/`ProductDetailsView`/`CartView` exist as **placeholder Text views** so `RootView` compiles. The next three steps fill them in.

Both `@main` entry points become:

```swift
@main struct Reactive_ShopApp: App {
    var body: some Scene { WindowGroup { CompositionRoot.makeRoot() } }
}
```

The Clip variant additionally:
- `.task { ... ProcessInfo ... _XCAppClipURL ... router.handle(url:) }`
- `.onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in ... }`

**Done when:** both apps launch, show three navigable placeholder screens, and routing works for `_XCAppClipURL=…/collections/all` and `_XCAppClipURL=…/product/unisex-hoodie` (verified by Xcode scheme arg).

## Step 6 — Catalog screen

- `CatalogViewModel(repository:)` — `state: LoadState<[Product]>`, `func load() async`, `func retry() async`.
- `CatalogView` — `.task { await vm.load() }`, switches on `vm.state`: skeleton list, list of `CatalogRow`, empty state, error state with retry.
- `CatalogRow` — image (AsyncImage), title, price, out-of-stock badge. Whole row is one accessibility element.

Tests:

- `CatalogViewModelTests` — happy path (loaded → array), error path (loaded → error), retry path (error → loading → loaded).

**Done when:** Catalog screen renders the fixture's products end-to-end in the running app; tests pass.

## Step 7 — Product Details screen

- `ProductDetailsViewModel(handle:repository:cart:)` — `state: LoadState<Product>`; `selection: [String: String]`; computed `selectedVariant: ProductVariant?`; `addToCart()`.
- `ProductDetailsView` — image carousel, title/vendor/price block, `VariantPicker` per option, "Add to Cart" button bound to `selectedVariant != nil && selectedVariant.isAvailable`.
- `VariantPicker` — chips for each option value; uses `Product.availableValues(for:given:)` to dim unavailable values.
- `ImageCarousel` — `TabView(.page)` with `accessibilityLabel("Image i of n")`.

Tests:

- `ProductDetailsViewModelTests` — load, select complete variant, select incomplete variant (button disabled), select unavailable variant (button disabled), add to cart increments cart store.

**Done when:** selecting Color=Black + Size=S on Unisex Hoodie disables Add-to-Cart (variant is `availableForSale=false`); selecting an available pair adds 1 to the cart.

## Step 8 — Cart screen

- `CartViewModel(cart:)` — exposes `lines`, `subtotal`, `total`, `itemCount`; `increment(_:)`, `decrement(_:)`, `remove(_:)`.
- `CartView` — list of `CartLineRow`, totals footer; empty state with CTA back to Catalog.
- `CartLineRow` — combined accessibility element + native `Stepper` for quantity.

Tests:

- `CartViewModelTests` — totals reflect store; increment/decrement/remove forward to store correctly.

**Done when:** add 2 variants from Details, open Cart, see correct subtotal/count; stepping quantity updates totals live.

## Step 9 — Accessibility & UX pass

Run the manual QA checklist from `Docs/05`:

1. VoiceOver across all three screens.
2. Dynamic Type at XXL.
3. Reduce Motion.
4. Increase Contrast.
5. Tap-target audit.

Fix anything that fails. Add missing `.accessibilityLabel` / `.accessibilityHint` / combined elements as identified.

**Done when:** all five checks pass without obvious issues.

## Step 10 — Documentation

- Populate `README.md` per the outline in `Docs/07` (what it is, architecture diagram, setup, run, env vars, testing, tradeoffs link, non-goals).
- Finalize `DECISION_LOG.md` from `Docs/07` plus any new decisions made during implementation.
- Verify the README's architecture diagram matches the shipped layer map in `Docs/02`.

**Done when:** a fresh reader could clone, open, run, and test without questions.

## Step 11 — Final verification

- `xcodebuild ... -scheme "Reactive Shop" ... test` — green.
- `xcodebuild ... -scheme "Reactive Shop Clip" ... build` — green; note Clip `.appex` size in README.
- Manual matrix:
  - Cold launch with no URL → Catalog.
  - `_XCAppClipURL=…/collections/all` → Catalog.
  - `_XCAppClipURL=…/product/unisex-hoodie` → Details for that product.
  - `_XCAppClipURL=…/product/does-not-exist` → Details with `.notFound` error UI.
  - Airplane mode launch → Catalog with offline error + retry.
  - Add 2 variants → Cart shows correct totals.

**Done when:** every row in the matrix passes; the branch is ready for submission.

## Out of scope (explicit, do not build)

Anything not listed here. The brief says: *"Please do not add extra features beyond the requirements above. We intentionally reserve extension work for the live session."* Polishing creep is the enemy.

## Risks & checkpoints

- **Step 1 (SPM wiring):** if the `pbxproj` edit is fiddly, fall back to adding the package via the Xcode UI rather than hand-editing — this is the only step where Xcode-the-app may be needed alongside Claude.
- **Step 5 (Clip routing):** `_XCAppClipURL` only works when the scheme env var is set; verify in scheme editor before claiming Step 5 done.
- **Step 7 (variant matching):** the `availableValues(for:given:)` algorithm is the trickiest piece — heavy table-driven tests in Step 2 catch issues before they reach the UI.
