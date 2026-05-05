import SwiftUI

/// Screen factory built once by `CompositionRoot` and passed directly to `RootView`.
/// Each closure builds a screen with its dependencies captured at composition time,
/// so views never see repositories or stores directly.
struct AppClipScreenFactory: Sendable {
    let makeCatalog: @MainActor () -> CatalogView
    let makeDetails: @MainActor (String) -> ProductDetailsView
    let makeCart:    @MainActor () -> CartView
}
