# 07 — Decisions & Communication

This is the seed of the deliverable Decision Log. It tracks what was chosen, what was rejected, and what we'd do with more time. The final `DECISION_LOG.md` at the repo root is generated from this file plus any decisions made during implementation.

## AI usage

- **Used for:** generating boilerplate (DTO types matching the Shopify wire shape), spec-translation scaffolding, and routine SwiftUI plumbing. Reviewed every line; nothing was committed unread.
- **Not used for:** architectural decisions, domain modelling, accessibility judgements, error copy. Those are mine.
- **Workflow:** discuss → plan → write phase docs → only then code. AI accelerates execution within an already-decided design; it does not get to decide the design.

## Decisions locked in planning

| # | Decision | Rationale | Rejected alternative |
|---|---|---|---|
| D1 | All real code in a local SPM package (`ReactiveShopKit`); both targets are thin shells | DRY across Clip + main app, isolates testable surface, keeps Clip binary lean by avoiding source duplication | Clip-only build (wastes the existing main-app target); duplicated target memberships (DRY violation, fragile) |
| D2 | Cart is in-memory only | App Clips are ephemeral by design; persistence adds migration/staleness surface area for no spec-backed gain | Persisting to UserDefaults / file (would need invalidation rules; out of scope) |
| D3 | Zero third-party dependencies | Strongest signal for a take-home, smallest binary, nothing to justify | Kingfisher (image cache) — `AsyncImage` + `URLCache` is enough; swift-snapshot-testing — overkill for the test scope |
| D4 | Swift Testing for unit tests, no UI/snapshot tests | Best ROI: proves architecture is testable without flake-prone end-to-end coverage | XCUITest happy-paths (real value but flaky in CI for a take-home) |
| D5 | MVVM + `@Observable` (Observation framework), not `ObservableObject`/Combine | Property-level change tracking → fewer redundant re-renders; smaller binary; Apple's current direction | Combine/`ObservableObject` (whole-object invalidation); TCA / Redux (over-engineered for this scope) |
| D6 | `Decimal` for money, currency in the type | Floating-point money is a bug waiting to happen; currency-as-string parallel to amount invites mismatches | `Double` + parallel `currencyCode: String` |
| D7 | `Router` is a separate `@Observable`, not a property of a screen VM | URL parsing is testable in isolation; routing is a cross-cutting concern, not Catalog's job | Routing logic embedded in `RootView` (untestable) |
| D8 | One full-feed fetch, in-memory cache in `RemoteProductsRepository`, shared by Catalog + Details | Feed is small and static; refetching on Details would be wasteful | Per-handle endpoint (doesn't exist for a static gist); refetch every screen (slow, pointless) |
| D9 | Cart stepper supports decrement + remove even though brief only requires increment | A stepper that only increments is hostile UX; cost is one line in `CartStore` | Strict literal compliance with brief (worse product) |
| D10 | Fall back to Catalog on unknown invocation URLs | Better UX than an error screen; matches "just open the store" mental model | Showing an error for unparseable URLs |

## What we'd improve with more time

- **iPad two-column layout** for Catalog → Details master-detail.
- **Cart persistence** with a TTL (e.g. 24h) so a Clip relaunched soon doesn't lose state.
- **Snapshot tests** on key screens to catch unintended visual regressions.
- **Localized currency formatting** beyond `Locale.current` — explicit handling of locale/currency mismatches.
- **Image prefetch** for the next 2 catalog rows once scrolling momentum is detected.
- **Real Associated Domains** wiring + provisioning so the App Clip Card and Smart Banner work end-to-end.
- **Telemetry** for time-to-first-paint and add-to-cart funnel — App Clips live or die by perceived speed.

## Risks acknowledged

- The hosted JSON gist is a single point of failure; the app handles 4xx/5xx but if the gist disappears the app is empty by design.
- App Clip 10MB binary budget is generous for this scope but worth measuring after first build.
- `_XCAppClipURL` is a development-only injection; production invocation depends on Associated Domains we're not configuring.

## README outline (to be written at end of implementation)

1. **What this is** — one-paragraph product description + screenshot.
2. **Architecture diagram** — ASCII module/layer diagram from `Docs/02`.
3. **Setup** — Xcode 16+, iOS 18+ simulator, no extra steps.
4. **How to run** — open project, pick a scheme, ⌘R. App Clip scheme arg for invocation testing.
5. **Environment variables** — `_XCAppClipURL` only.
6. **Testing** — `xcodebuild ... test` one-liner; what's covered.
7. **Tradeoffs & assumptions** — link to `DECISION_LOG.md`.
8. **What's not here** — the explicit non-goals from `Docs/01`.
