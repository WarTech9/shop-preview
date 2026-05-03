# 02 — Architecture & State

## Pattern

MVVM with a thin Composition Root. Views are declarative + dumb; view models own state and orchestrate; services and repositories hold business logic and I/O.

```
SwiftUI View ──reads──▶ @Observable ViewModel ──calls──▶ Service / Repository
     ▲                          │                              │
     └─── @Environment(CartStore) ◀── injected at root ────────┘
```

## Module / layer map

All production code lives in a local SPM package `ReactiveShopKit` (one product, multiple internal targets if needed; start as one). The two app targets (`Reactive Shop`, `Reactive Shop Clip`) are thin entry points that import the package.

| Layer | Owns | Depends on |
|---|---|---|
| `Domain` | Pure value types, business rules (`Cart.add`, totals) | nothing |
| `Data` | `ProductsRepository` protocol + `RemoteProductsRepository`, DTOs | `Domain`, `Foundation` |
| `Services` | `CartStore` (observable), `Router` (URL → `Route`) | `Domain` |
| `Features` | One folder per screen: View + ViewModel | `Domain`, `Services`, protocols from `Data` |
| `App` | `RootView`, composition root, entry-point factories | all of the above |

Dependency direction is one-way (`App → Features → Services/Data → Domain`). Lower layers never import upward — enforced by file/folder discipline (no compile-time module split needed for a project this size; documented as a rule).

## SOLID application

- **S** — each VM serves exactly one screen. `CartStore` is the only place mutating cart state. `Router` is the only place parsing URLs.
- **O** — features depend on `ProductsRepository` (protocol); swap the remote impl for an in-memory one in tests without touching the VM.
- **L** — `RemoteProductsRepository` and a hypothetical `MockProductsRepository` honour the same async contract and the same error vocabulary.
- **I** — `ProductsRepository` exposes only what features call (`fetchAll()`, `fetch(handle:)`); no fat "everything" interface.
- **D** — VMs receive their dependencies via `init`. No service locators, no `@EnvironmentObject` for repositories. `CartStore` is the *one* exception — it's app-wide observable state, idiomatic to inject via `@Environment`.

## State ownership

| State | Owner | Lifetime | Sharing |
|---|---|---|---|
| Catalog list (loading/loaded/error) | `CatalogViewModel` | Catalog screen | local |
| Selected variant + detail load state | `ProductDetailsViewModel` | Details screen | local |
| Cart contents | `CartStore` | App process | injected via `@Environment` |
| Current route | `Router` (top-level `@Observable`) | App process | read by `RootView` |

Each VM is `@MainActor @Observable` and exposes a single `state` property modelled as an enum (`.idle | .loading | .loaded(T) | .error(RepositoryError)`) so views render with a single `switch`.

## Routing model

```swift
enum Route: Equatable {
    case catalog
    case product(handle: String)
}

@Observable @MainActor
final class Router {
    private(set) var route: Route = .catalog
    func handle(url: URL) { /* parse → set route, fallback to .catalog */ }
}
```

- `RootView` switches on `router.route` to decide which screen to show. NavigationStack handles the push for `product(handle:)`.
- The Clip's `App` calls `router.handle(url:)` from `_XCAppClipURL` (read once at launch via `ProcessInfo`) and from `onContinueUserActivity`. The main app calls it from the same hook.
- URL parsing is pure and synchronous — fully unit-tested with a parametrised matrix.

## Protocol-oriented boundaries

Program to protocols at every seam where a fake, alternative implementation, or test stub adds real value. *Do not* protocolize types that have only one meaningful implementation (domain values, enums, view models constructed by their own view). Over-protocolizing produces ceremony without testability.

| Boundary | Protocol | Concrete | Why a protocol |
|---|---|---|---|
| HTTP transport | `HTTPClient` (`func data(for: URLRequest) async throws -> (Data, HTTPURLResponse)`) | `URLSessionHTTPClient` wrapping `URLSession` | Lets repository tests stub responses with a 5-line in-memory client instead of `URLProtocol` plumbing. Also documents exactly what we use from `URLSession` (one method). |
| Product fetching | `ProductsRepository` | `RemoteProductsRepository` | VM tests inject an in-memory repo; never hit the network. |
| Cart state | `CartStoring` | `CartStore` | VM tests verify their interaction with the cart without depending on the `@Observable` runtime. Previews can swap in a pre-populated store. |
| URL routing | `URLRouting` | `Router` | Unit-test parsing without observing the live `Router`; preview launches with a fixed route. |
| Logging *(optional, only if added)* | `Logger` (`func log(_:level:)`) | `OSLogLogger` | If we need diagnostics, this stays out of `print`-spaghetti and silent in tests. |

Things that are deliberately **not** protocols:

- **Domain types** (`Product`, `Cart`, `Money`) — they're values; protocols here would be cargo-cult.
- **View models** — each is owned by exactly one view that constructs it; a `CatalogViewModeling` protocol would only exist to satisfy a rule, not a test (we test the concrete VM directly).
- **`JSONDecoder`** — it's already a stable boundary; wrapping it adds nothing.

Rule of thumb: *if the only test for a protocol would be a tautological "the mock returned what we told it to," the protocol shouldn't exist.*

## Dependency injection

The Composition Root builds the dependency graph once at app launch. The interesting question is *how those dependencies reach the things that need them.* Three patterns considered:

### A. Single `Container` injected via `@Environment`

```swift
@Observable final class AppContainer {
    let repository: ProductsRepository
    let cart: CartStoring
    let router: URLRouting
    let http: HTTPClient
}
```

- ✅ One environment key. Easy to swap the whole stack in previews.
- ❌ **Service locator anti-pattern.** Any view in the tree can pull *any* dependency, defeating dependency *inversion* — VMs no longer declare what they need, they reach for it.
- ❌ Test setup grows: even a VM that needs only `ProductsRepository` ends up taking a whole container, or a partial mock of one.
- ❌ Couples unrelated concerns (cart and routing don't need to ship together).

### B. Per-property `@Environment` for everything

- ✅ Explicit at each call site.
- ❌ Bloats the env chain at the root (`.environment(repo).environment(cart).environment(router).environment(http)…`).
- ❌ Tempts views to read services they shouldn't (e.g. a row reaching for `HTTPClient`).
- ❌ Hides the dependency graph: which screen needs what is no longer obvious from any single file.

### C. Init injection for VMs + `@Environment` only for app-wide observable state *(Recommended)*

- VMs declare their dependencies explicitly in `init`. Plumbing is one level deep because each screen view constructs its own VM in its initializer or `.task`.
- `@Environment` carries **only** the two things that are genuinely app-wide observable state: `CartStoring` and `URLRouting`. Two keys, both observable, both legitimately read from many screens.
- Repositories, `HTTPClient`, and any other I/O service are *not* in the environment — they reach VMs via the screen factories below.
- ✅ Honest dependency graph: open any VM file, see exactly what it depends on.
- ✅ Trivial to test: `CatalogViewModel(repository: InMemoryProductsRepository(…))`.
- ✅ Honest preview: each preview supplies its own minimal stack.
- ❌ Slightly more constructor code than option A — but that code is documentation, not noise.

### Screen factories — keeping `RootView` thin without a god container

Rather than `RootView` knowing how to build every VM, the Composition Root produces a small `ScreenFactory` value injected via env:

```swift
struct ScreenFactory {
    let makeCatalog: () -> CatalogView
    let makeDetails: (_ handle: String) -> ProductDetailsView
    let makeCart: () -> CartView
}
```

- Each `make*` closure captures the protocols it needs (e.g. `repository`) and constructs the VM + view.
- Views read `@Environment(ScreenFactory.self)` and call `factory.makeDetails(handle)` — they don't see repositories at all.
- Not a service locator: the factory exposes only *outputs* (built screens), not raw services. Adding a new service doesn't widen the factory.
- Tests bypass the factory entirely and construct VMs directly.

### Final injection map

| Mechanism | Carries | Read by |
|---|---|---|
| `init` | repositories, HTTP client, `CartStoring`, `URLRouting` (when a VM needs to mutate routing) | VMs only |
| `@Environment(CartStoring.self)` | the live cart | any view that displays cart count, the Cart screen |
| `@Environment(URLRouting.self)` | the live router | `RootView`, anywhere needing to navigate |
| `@Environment(ScreenFactory.self)` | screen builders | parents pushing children (`RootView`, `CatalogView`) |
| Composition Root (`makeRoot()`) | constructs everything once at app launch | the two `@main` entry points |

Result: the environment has exactly **three keys**, no service locator, every VM's dependencies are visible at its declaration, and the two `@main` entry points (Clip + main app) each end with a single `RootView()` call.

## Concurrency

- VMs: `@MainActor`. They `await` repository calls and update `state`.
- Repositories: `Sendable`, not main-bound. Decoding happens off the main actor.
- `CartStore`: `@MainActor` (mutated from VMs which are also main-actor) — no need for actor isolation beyond that.
- All async work is structured: `.task` modifiers tie network calls to view lifetime; cancellations are honoured.

## Error taxonomy

```swift
enum RepositoryError: Error, Equatable {
    case offline          // URLError.notConnectedToInternet etc.
    case server(Int)      // non-2xx
    case decoding         // JSONDecoder threw
    case notFound         // handle missing in feed
    case unknown
}
```

Views map each case to copy + a retry button (or a "Browse catalog" CTA for `.notFound`). No raw `Error` ever reaches the view.
