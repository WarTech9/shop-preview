# Decision Log

## How I used AI

- **Planning**: turning the brief into a layered implementation plan; sequencing steps so each lands on a green build.
- **Architectural brainstorming**: weighing options (env vs init injection, `AnyView` vs concrete types, VMs in package vs app target) and surfacing drawbacks of each path.
- **Boilerplate generation**: domain models, DTOs, network stack, view models, view scaffolding.
- **Test authoring**: Swift Testing suites for domain, repository, view models.
- **Documentation**: README, this decision log, architecture diagram (mermaid).
- **Verification**: catching subtle issues (closure `@MainActor` isolation, `EnvironmentKey` defaults, env propagation across sheet boundaries).

## What I changed or rejected

- **Network retry**: AI initially gated `LoadState.error → .loading` so `.task` re-fires would auto-retry. Rejected — chose explicit manual retry; failures stay in `.error` until the user taps "Try again".
- **`URLRouter`**: AI proposed an `@Observable URLRouter` for handling URLs and navigating in app clip. Collapsed to a pure `InvocationURLParser` after noting nothing actually consumed the observable form.
- **SwiftUI in package**: AI initially placed SwiftUI types inside the package. Moved out — package is Foundation/Observation only.
- **`AnyView` in screen factory**: AI's first cut returned type-erased views from `AppClipScreenFactory`. Replaced with concrete return types.
- **`EnvironmentKey` for screen factory**: AI wired the factory through `@Environment(\.screenFactory)`. Only `RootView` reads it — switched to init injection.
- **View models in the package**: AI placed VMs alongside Domain/Data/Services. Moved into the App Clip target — VMs are 1:1 with views.
- **Repositories under Domain**: AI grouped `ProductsRepository` + `RemoteProductsRepository` inside Domain. Split into a dedicated `Repositories/` layer; Domain is value types only.
- **`Cart.add(_:of:)` failure mode**: AI suggested `precondition`. Chose `throws CartError.currencyMismatch` so failed adds leave the cart unchanged.

## Key technical tradeoffs

- **Local SPM package over a single target.** More setup, but cleanly separates Domain / Repositories / Data / Services and is easy to share with a future main app.
- **No DI framework.** `CompositionRoot` + closure factories. Easy to read for three views; a larger app might require a dedicated DI container.
- **`@Observable` over Combine.** iOS 17+ deployment target unlocks the Observation framework — less boilerplate, no `@Published` chains.
- **Cart is in-memory only.** Matches App Clip lifetime; no persistence layer.
- **Single-currency cart.** `Cart.add(_:of:)` throws on mismatch rather than silently coercing.
- **No auto-retry on network failures.** Manual retry only; auto-retry-with-backoff would naturally fit as a decorator over `HTTPClient`.
- **Tolerant DTO mapping.** Bad image URLs drop the image; bad variants drop the variant; products survive if any variant does. Feed assumed mostly clean.
- **Repository is an `actor` with inflight `Task` cache.** Concurrent callers share one HTTP request; cache invalidates on failure.

## What I'd improve with more time

- Cart persistence across app sessions (e.g. lightweight `UserDefaults` snapshot).
- Variant picker UX for products with many option values per axis (current chip row may overflow).
- Internationalization using strings catalog for all UI copy.
- More polished UI on iPad, skeleton states and UI transitions.
- Pull-to-refresh on the catalog.
