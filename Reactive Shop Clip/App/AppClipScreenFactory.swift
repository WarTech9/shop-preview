import SwiftUI

/// Erased-view factory injected via `@Environment(\.screenFactory)`. Each closure builds a
/// screen with its dependencies captured at composition time, so views never see repositories
/// or stores directly. `AnyView` is the storage tax for closures returning generic `some View` —
/// paid once at the closure boundary, not at call sites.
///
/// This is a struct (no observable state, just stored closures), so the classic `EnvironmentKey`
/// pattern is used instead of the `@Observable`-class flavor of `@Environment`.
struct AppClipScreenFactory: Sendable {
    let makeCatalog: @MainActor () -> AnyView
    let makeDetails: @MainActor (String) -> AnyView
    let makeCart: @MainActor () -> AnyView
}

// MARK: - Environment integration

private struct AppClipScreenFactoryKey: EnvironmentKey {
    /// Defaults to empty views so SwiftUI Previews can render without a CompositionRoot.
    static let defaultValue = AppClipScreenFactory(
        makeCatalog: { AnyView(EmptyView()) },
        makeDetails: { _ in AnyView(EmptyView()) },
        makeCart:    { AnyView(EmptyView()) }
    )
}

extension EnvironmentValues {
    var screenFactory: AppClipScreenFactory {
        get { self[AppClipScreenFactoryKey.self] }
        set { self[AppClipScreenFactoryKey.self] = newValue }
    }
}
