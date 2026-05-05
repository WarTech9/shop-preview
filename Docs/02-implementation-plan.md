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
- **Feed URL wiring (deferred from Step 3):**
  - Add a small helper inside the package (e.g. `App/Configuration.swift`) that reads `Bundle.main.object(forInfoDictionaryKey: "ProductFeedURL") as? String`, converts to `URL`, and `preconditionFailure`s with a clear message if missing/malformed (config bug, not a runtime error).
  - In Xcode, on **both** `Reactive Shop` and `Reactive Shop Clip` targets, add a build setting `INFOPLIST_KEY_ProductFeedURL` set to the pinned gist URL: `https://gist.githubusercontent.com/tsopin/22b7b6b32cef24dbf3dd98ffcfb63b1a/raw/6f379a4730ceb3c625afbcb0427ca9db7f7f3b8b/testProducts.json`. Xcode 13+ auto-merges `INFOPLIST_KEY_*` build settings into each target's generated Info.plist — no explicit Info.plist file needed for the main app.
  - `CompositionRoot.makeRoot()` calls the helper and passes the `URL` to `RemoteProductsRepository(http:feedURL:)`.
- **Cleanup:** delete `Sources/ReactiveShopKit/ReactiveShopKit.swift` (the `placeholder` enum from Step 1) once both `@main` files no longer reference it.

At this step, `CatalogView`/`ProductDetailsView`/`CartView` exist as **placeholder Text views** so `RootView` compiles. The next three steps fill them in.

The `@main` entry point for the app clip target becomes:

```swift
@main struct Reactive_ShopApp: App {
    var body: some Scene { WindowGroup { CompositionRoot.makeRoot() } }
}
```

The Clip variant additionally:
- `.task { ... ProcessInfo ... _XCAppClipURL ... router.handle(url:) }`
- `.onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in ... }`

**Done when:** both apps launch, show three navigable placeholder screens, and routing works for `_XCAppClipURL=…/collections/all` and `_XCAppClipURL=…/product/unisex-hoodie` (verified by Xcode scheme arg).

### ✅ Completed (2026-05-03)

75 tests across 11 suites passing. Both Xcode schemes build clean.

Files:
- **Package created:** `Services/AppRouting.swift` (`AppDestination` enum + `AppRouting` protocol), `Services/AppRouter.swift` (`@Observable @MainActor final class`, `public var path` with `push`/`pop`/`popToRoot`, `push(.catalog)` clears to root), `Services/InvocationURLParser.swift` (pure URL → `AppDestination`, https-only after user tightening), `LoadState.swift` (generic 4-state enum at package root).
- **Package tests created:** `Services/InvocationURLParserTests.swift` (16 tests), `Services/AppRouterTests.swift` (9 tests).
- **Package deleted:** `Services/URLRouting.swift`, `Services/URLRouter.swift`, `Tests/Services/RouterTests.swift` (replaced by parser collapse).
- **App Clip target created:** `App/Configuration.swift` (Bundle.main lookup, `preconditionFailure` on miss), `App/AppClipScreenFactory.swift` (struct + `EnvironmentKey` extension — env API requires non-`@Observable` value-types via classic key), `App/CompositionRoot.swift` (`live()` factory; Step 5 doesn't yet call `Configuration.productFeedURL()` because placeholder views take no deps), `App/RootView.swift` (`NavigationStack(path: $router.path)`, `navigationDestination(for: AppDestination.self)`, toolbar cart button, `.sheet`), three placeholder feature views.
- **App Clip @main rewritten:** `Reactive_Shop_ClipApp.swift` — `@State private var root = CompositionRoot.live()`, env injection (`AppRouter`, `CartStore`, `\.screenFactory`), `.task` reads `_XCAppClipURL`, `.onContinueUserActivity` for runtime invocations.

Deviations / refinements during implementation:
- **`URLRouter` collapsed to `InvocationURLParser`** — original Step 5 had it as a stored observable; nobody read it. Replaced with a pure parser; AppRouter is now the single navigation source of truth.
- **Package boundary tightened (Option B):** SwiftUI stays out of the package; all SwiftUI/composition code moved to the App Clip target. Package still imports zero SwiftUI (verified via grep).
- **`AppRouter.path` is `public var`** (not `private(set)`) so SwiftUI's `@Bindable` can write through during back-gestures; `push`/`pop`/`popToRoot` remain the canonical mutation API.
- **`AppClipScreenFactory` uses `EnvironmentKey`** pattern, not `@Environment(SomeType.self)` — it's a value-type struct, not an `@Observable` class.
- **Configuration not yet called in `CompositionRoot.live()`** — placeholder views take no dependencies, so `repo` isn't constructed until Step 6. Info.plist read deferred along with it.
- **Parser is https-only** (user tightening from initial http+https design).
- **Main app left as-is** per the App-Clip-only narrowing of scope.

## Step 6 — Catalog screen

- `CatalogViewModel(repository:)` — `state: LoadState<[Product]>`, `func load() async`, `func retry() async`.
- `CatalogView` — `.task { await vm.load() }`, switches on `vm.state`: skeleton list, list of `CatalogRow`, empty state, error state with retry.
- `CatalogRow` — image (AsyncImage), title, price, out-of-stock badge. Whole row is one accessibility element.

Tests:

- `CatalogViewModelTests` — happy path (loaded → array), error path (loaded → error), retry path (error → loading → loaded).

**Done when:** Catalog screen renders the fixture's products end-to-end in the running app; tests pass.

### ✅ Completed (2026-05-04)

83 tests across 12 suites passing. Both Xcode schemes build. Manual: Clip launches into a 4-tile grid of fixture products, tap pushes Details placeholder, offline error renders correctly with manual retry.

Files:
- **Package created:** `Domain/Money+Formatting.swift` (`Money.formatted()` + `PriceRange.formatted()` with en-dash range — added to avoid duplication across Tile/Details/Cart), `Features/Catalog/CatalogViewModel.swift` (`@Observable @MainActor`, `state: LoadState<[Product]>`, strict-idle-gated `load()`, `retry()`).
- **Package tests created:** `Helpers/InMemoryProductsRepository.swift` (call-counting stub), `Features/Catalog/CatalogViewModelTests.swift` (8 tests including idle-only-load guard and retry-from-error).
- **App Clip target created:** `Features/Catalog/CatalogTile.swift` (square `AsyncImage` with `.easeOut(0.15)` transaction, out-of-stock saturation+capsule, combined accessibility element), `Features/Catalog/CatalogGrid.swift` (2-col `LazyVGrid` in `ScrollView`, tiles wrapped in `NavigationLink(value: AppDestination.productDetails(handle:))`), `Features/Catalog/CatalogSkeleton.swift` (4 redacted placeholder tiles, `.accessibilityHidden`), `Features/Catalog/CatalogEmptyState.swift` (`ContentUnavailableView`), `Features/Catalog/CatalogErrorState.swift` (`ContentUnavailableView` with per-case `Docs/05` copy).
- **App Clip target replaced:** `Features/Catalog/CatalogView.swift` (orchestrator: switches on VM state, owns `.task`, owns `init(viewModel:)`).
- **App Clip target modified:** `App/CompositionRoot.swift` — `URLSessionHTTPClient` + `RemoteProductsRepository(http:feedURL: Configuration.productFeedURL())` introduced; `makeCatalog` closure constructs `CatalogViewModel(repository: repo)` and `CatalogView(viewModel:)`; other factory closures unchanged.
- **Xcode (User):** added `INFOPLIST_KEY_ProductFeedURL` build setting on Clip target; added the five new App-Clip files to target membership.

Deviations / refinements during implementation:
- **`Money+Formatting` added to package** (not in original Step 6 plan) — small extension, justified by avoiding duplicated currency formatting across three feature screens. `Decimal.formatted(.currency(code:))` keeps it locale-aware.
- **`load()` is strictly idle-gated.** Originally allowed `.error → .loading` — tightened so `.task` re-firing while in error state can never auto-retry. `retry()` is the only path from `.error` back into a fetch (it explicitly resets to `.idle` first). Caught during review of the retry/backoff design discussion.
- **Naming: `CatalogTile` not `CatalogRow`** — original Step 6 text said `CatalogRow`. Renamed to `CatalogTile` because the layout is a 2-col grid, not a list of rows. Layout decision was made in the Step 6 planning ("2-column LazyVGrid + borderless tiles" over single-column list).
- **No auto-retry behavior.** Considered (auto-retry-once-on-transient, decorator-pattern `RetryingHTTPClient`). Decided against for take-home scope. Documented the decorator approach for future reference but did not implement.
- **Empty-state retry button** is wired but won't fire on the supplied fixture (4 products always present). It exists for defensive completeness.

## Step 7 — Product Details screen

- `ProductDetailsViewModel(handle:repository:cart:)` — `state: LoadState<Product>`; `selection: [String: String]`; computed `selectedVariant: ProductVariant?`; `addToCart()`.
- `ProductDetailsView` — image carousel, title/vendor/price block, `VariantPicker` per option, "Add to Cart" button bound to `selectedVariant != nil && selectedVariant.isAvailable`.
- `VariantPicker` — chips for each option value; uses `Product.availableValues(for:given:)` to dim unavailable values.
- `ImageCarousel` — `TabView(.page)` with `accessibilityLabel("Image i of n")`.

Tests:

- `ProductDetailsViewModelTests` — load, select complete variant, select incomplete variant (button disabled), select unavailable variant (button disabled), add to cart increments cart store.

**Done when:** selecting Color=Black + Size=S on Unisex Hoodie disables Add-to-Cart (variant is `availableForSale=false`); selecting an available pair adds 1 to the cart.

### ✅ Completed (2026-05-04)

96 tests across 13 suites passing. Both Xcode schemes build. Manual: Catalog tap pushes Details for the chosen handle; carousel + info + chips render; F3 acceptance verified (Black/S → "Out of stock" disabled, available combos enable with price label); Add to Cart fires haptic; `_XCAppClipURL=…/product/does-not-exist` lands on the not-found error state with a Browse-catalog action.

Files:
- **Package created:** `Features/ProductDetails/ProductDetailsViewModel.swift` (`@Observable @MainActor`, `state: LoadState<Product>`, `selection: [String: String]`, computed `selectedVariant` via `Product.variant(matching:)`, `canAddToCart`, `addToCart() throws`, `lastAddedAt` for haptic trigger; strict-idle-gated `load()`).
- **Package tests created:** `Helpers/InMemoryCartStore.swift` (call-counting `CartStoring` stub), `Features/ProductDetails/ProductDetailsViewModelTests.swift` (13 tests including F3 acceptance — Black/S resolves with `isAvailable == false`, `canAddToCart == false`, `addToCart` is no-op).
- **App Clip target created:** `Features/ProductDetails/ImageCarousel.swift` (`TabView(.page)`, scrolls to `targetImageId` on change, reduce-motion fallback to instant set), `Features/ProductDetails/VariantPicker.swift` (capsule chip row, 44pt hit targets, accessibility labels with selection/out-of-stock state), `Features/ProductDetails/ProductDetailsSkeleton.swift` (shape-matching loading placeholder), `Features/ProductDetails/ProductDetailsErrorState.swift` (`.notFound` shows "Browse catalog"; others show "Try again").
- **App Clip target replaced:** `Features/ProductDetails/ProductDetailsView.swift` (orchestrator: state switch, image carousel + info block + per-option `VariantPicker` + sticky bottom Add-to-Cart bar via `safeAreaInset`; reads `AppRouter` from env to wire the not-found "Browse catalog" action; `.sensoryFeedback(.success, trigger: viewModel.lastAddedAt)`).
- **App Clip target modified:** `App/CompositionRoot.swift` — `makeDetails` closure now constructs `ProductDetailsViewModel(handle:repository:cart:)` capturing both `repo` and `cart`.
- **Xcode (User):** added the four new App-Clip files to target membership.

Deviations / refinements during implementation:
- **`addToCart()` is no-op when variant is unavailable** — added an `isAvailable` guard inside the VM in addition to the view's `disabled(!canAddToCart)`. Defense in depth: VM never adds an unavailable variant even if a future caller bypasses the disabled state.
- **`InMemoryCartStore` is a separate test stub** (not just `CartStore` directly) — keeps VM tests independent of the `@Observable` runtime; mirrors the `InMemoryProductsRepository` pattern.
- **`ProductDetailsErrorState` takes both `onRetry` and `onBackToCatalog` closures** — keeps the state component dumb (no env access); orchestrator wires `popToRoot()` from `appRouter`.
- **Carousel reduce-motion behavior** — falls back to instant page set instead of animated scroll when `accessibilityReduceMotion` is on (per `Docs/05`).

## Step 8 — Cart screen

- `CartViewModel(cart:)` — exposes `lines`, `subtotal`, `total`, `itemCount`; `increment(_:)`, `decrement(_:)`, `remove(_:)`.
- `CartView` — list of `CartLineRow`, totals footer; empty state with CTA back to Catalog.
- `CartLineRow` — combined accessibility element + native `Stepper` for quantity.

Tests:

- `CartViewModelTests` — totals reflect store; increment/decrement/remove forward to store correctly.

**Done when:** add 2 variants from Details, open Cart, see correct subtotal/count; stepping quantity updates totals live.

### ✅ Completed (2026-05-04)

103 tests across 14 suites passing. Both Xcode schemes build clean. Manual verification by user — cart functional end-to-end (empty state, add/edit/remove, totals, swipe-delete, badge, dismiss).

Files:
- **Package created:** `Features/Cart/CartViewModel.swift` (`@Observable @MainActor`, thin facade over `CartStoring`: computed `lines`/`subtotal`/`total`/`itemCount`/`isEmpty`; `setQuantity(_:for:)` and `remove(_:)` forwarding — `remove` calls `setQuantity(0, for:)`).
- **Package tests created:** `Features/Cart/CartViewModelTests.swift` (7 tests covering initial state, line/totals propagation, setQuantity forwarding, setQuantity(0) removes, remove() routes through setQuantity).
- **App Clip target created:** `Features/Cart/CartLineRow.swift` (60pt thumbnail, title/variant/unit/line-total stack, native `Stepper` 0–99 with binding-callback hookup, combined accessibility label on info block, stepper interactive), `Features/Cart/CartTotalsFooter.swift` (items/subtotal/total in `.regularMaterial` with top divider, total in `.title3.bold().monospacedDigit()`, combined accessibility), `Features/Cart/CartEmptyState.swift` (`ContentUnavailableView` with "Browse products" callback).
- **App Clip target replaced:** `Features/Cart/CartView.swift` (orchestrator: `NavigationStack` wrap, `@Environment(\.dismiss)`, empty/list branch, `.onDelete` for swipe-delete, `safeAreaInset(edge: .bottom)` for totals, "Done" toolbar button).
- **App Clip target modified:** `App/CompositionRoot.swift` — `makeCart` closure now constructs `CartView(viewModel: CartViewModel(cart: cart))`. `App/RootView.swift` — toolbar cart button extracted into `cartToolbarButton` computed view with red-capsule count badge overlay (visible when `itemCount > 0`); accessibility label includes count.

Deviations / refinements during implementation:
- **All-Claude implementation** per user direction ("Go ahead and implement all the code this time"). Previous steps had user owning orchestrator views; Step 8 broke from that pattern.
- **Stepper minimum is 0**, not 1 — pressing `−` at quantity 1 removes the line via `setQuantity(0, for:)`. Single canonical mutation path; swipe-to-delete remains as a secondary affordance.
- **Cart sheet wraps in its own `NavigationStack`** so the cart screen has its own toolbar context independent of the outer catalog/details stack.
- **No new Money formatting** — reused `Money.formatted()` from Step 6 throughout (totals, line prices, line totals).
- **Xcode auto-target-membership:** Xcode 16's synchronized folder behavior auto-included the new App Clip files without manual target-add. No user action needed beyond review.

## Step 9 — Accessibility & UX pass

Run the manual QA checklist from `Docs/05`:

1. VoiceOver across all three screens.
2. Dynamic Type at XXL.
3. Reduce Motion.
4. Increase Contrast.
5. Tap-target audit.

Fix anything that fails. Add missing `.accessibilityLabel` / `.accessibilityHint` / combined elements as identified.

**Done when:** all five checks pass without obvious issues.

### ✅ Completed (2026-05-04)

Both Xcode schemes build clean. 103 package tests still green (no package changes). Manual verification by user — badge fully visible at all counts, cart button reachable from Details, Catalog cards have card styling, accessibility sweep clean.

Files:
- **App Clip target created:** `App/CartPresenter.swift` (`@Observable @MainActor` with `isShowingCart: Bool` — global sheet trigger so any screen can present cart), `App/CartToolbarButton.swift` (reusable toolbar button reading `CartStore` + `CartPresenter` from env; badge sits in fixed 28×28 frame with system-background ring; `99+` cap).
- **App Clip target modified:** `App/CompositionRoot.swift` (owns `cartPresenter` handle), `Reactive_Shop_ClipApp.swift` (injects presenter into env), `App/RootView.swift` (replaced local `@State showingCart` with presenter binding; uses `CartToolbarButton`), `Features/ProductDetails/ProductDetailsView.swift` (adds `.toolbar { CartToolbarButton() }` so the cart is reachable from Details), `Features/Catalog/CatalogTile.swift` (card styling: `secondarySystemGroupedBackground`, 16pt corner radius, subtle shadow, image clipped to top half of card via outer `clipShape`).

Deviations / refinements during implementation:
- **Scope intentionally narrowed.** Per user direction — "minor cleanup and voiceover and normal accessibility, don't go overboard." Skipped Increase Contrast pass and exhaustive Dynamic Type matrix; kept VoiceOver sweep, XXL Dynamic Type spot-check, tap-target audit, Reduce Motion (already done in Step 7).
- **Badge clipping fix** — root cause was `.offset(x:10, y:-8)` pushing the badge outside the toolbar item's clipping bounds. Replaced with a fixed-size container so the badge anchors inside the icon's frame; added a 1.5pt system-background ring for visual separation against the badge's red.
- **Cart on Details via `CartPresenter`, not callback drilling** — user-chosen approach. One small `@Observable` env type beats threading bindings through ProductDetailsView. Scales if a future global sheet is added.
- **No accessibility regressions found** — combined labels from Steps 6/7/8 already covered the screens; no new `.accessibilityLabel`/`.accessibilityHint` work needed beyond what the toolbar button now exposes ("Cart" / "Cart, N items").

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
