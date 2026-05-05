# 04 — Performance

App Clips have hard constraints (10MB uncompressed binary for default experiences, 50MB for advanced) and a UX expectation of "instant." This doc covers what we do, and what we deliberately don't.

## Binary size

- **Zero third-party dependencies.** Every kilobyte we don't ship is a kilobyte under the limit.
- **Shared SPM package, not duplicated sources** — same code compiled into both targets via SPM, no doubled object code in the Clip.
- **No asset bloat.** Asset catalog holds only AppIcon and AccentColor (already there). All product imagery is remote.
- **No Combine, no XCTest in shipping code.** Swift Testing is a test-only dependency.
- Verification: after build, `du -sh` the `.appex` payload and call it out in the README if it climbs above ~5MB.

## Cold-start path (what runs before first paint)

1. `App.body` builds the Composition Root (cheap value/struct creation).
2. `Router` reads `_XCAppClipURL` from `ProcessInfo` — synchronous, ~µs.
3. `RootView` decides `Catalog` or `Details(handle:)`.
4. The chosen screen's `.task` kicks off the network fetch.

We do **not** preload anything else, do not warm caches, do not run analytics, and do not block UI on configuration. First useful paint = a loading skeleton, not a blank screen.

## Networking

- One `URLSession.shared` across the app. 15s timeout. `cachePolicy = .useProtocolCachePolicy` so the gist's HTTP caching is honoured.
- Single endpoint: the gist URL. We fetch the **full feed** once; both Catalog and Details read from the same in-memory cache held by `RemoteProductsRepository` (so navigating Catalog → Details does not refetch).
- Decoding runs on a background task (`Task.detached(priority: .userInitiated)`); the main actor only sees the finished `[Product]`.

## Image loading

- `AsyncImage` with explicit `transaction: .init(animation: .easeOut(duration: 0.15))` so the placeholder→image swap doesn't flash.
- `.aspectRatio(contentMode: .fill)` inside a clipping frame — sized images don't trigger layout passes when they arrive.
- **No prefetching.** Apple's URL cache + image cache handle reuse; rolling our own would add code without clear win for a feed this small.
- Detail screen carousel uses `TabView(.page)` so only the visible page decodes its image at full size.

## List rendering

- Catalog uses `List` (not `ScrollView { ForEach }`) so cells are reused and laid out lazily. Each row is a small composition (image + 2 labels) with stable `Identifiable` IDs — no re-diffing churn.
- Cart uses `List` with `.onDelete` semantics on lines (deferred — see Decision Log) for the same reason.

## Re-render discipline

- VMs are `@Observable` (Observation framework, not `ObservableObject`) — SwiftUI tracks reads at property granularity, not whole-object granularity.
- Catalog VM exposes `state: LoadState<[Product]>`; the row view only reads its own product, so adding a product re-diffs one row, not the whole list.
- `CartStore.cart` is a value type; views that read `cart.itemCount` re-render only when that derived value changes.
- No `@State` mirror of view-model data in views (a common source of double-truth).

## Concurrency hygiene

- All `await` calls live inside `.task` so they cancel automatically when the view disappears (e.g. the user backs out of Details mid-fetch).
- No `Task { ... }` fired from `init` or `body` — those leak past view lifetime.
- `CartStore` mutations are synchronous; no spinners on add-to-cart.

## What we explicitly skip (and why)

| Skipped | Why |
|---|---|
| Custom image cache (Kingfisher etc.) | `AsyncImage` + `URLCache` is enough for a single-screen feed; adding a dep costs binary size and review time. |
| Pagination | Feed is small and static; pagination is solving a problem that doesn't exist. |
| GraphQL / Shopify SDK | We're hitting a static gist; a hand-rolled `URLSession` call is 10 lines. |
| Background prefetch on launch | App Clips are short-lived; prefetching imagery the user may not view is wasteful. |
