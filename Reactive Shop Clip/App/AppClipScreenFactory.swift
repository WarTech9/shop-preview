import SwiftUI

/// Screen factory built once by `CompositionRoot` and passed directly to `RootView`.
/// Each closure builds a screen with its dependencies captured at composition time,
/// so views never see repositories or stores directly. Concrete return types preserve
/// SwiftUI's opaque view diffing — no `AnyView` erasure tax.
///
/// Not injected via `@Environment` because `RootView` is the only consumer; routed
/// destinations and modal sheets are all built at the `RootView` layer. If a future
/// screen needs to construct another screen inline, reconsider — but the convention
/// here is that screens emit `AppDestination` values, not view instances.
struct AppClipScreenFactory: Sendable {
    let makeCatalog: @MainActor () -> CatalogView
    let makeDetails: @MainActor (String) -> ProductDetailsView
    let makeCart:    @MainActor () -> CartView
}
