import SwiftUI
import ReactivShopKit

/// Single place where the live dependency graph is assembled. Owned by `@main` via
/// `@State` so the graph survives the app's lifetime.
///
/// Only the handles needed by views (`appRouter`, `cart`, `factory`) are exposed.
/// Repositories and HTTP clients are captured by the factory closures and never leak.
@MainActor
struct CompositionRoot {
    let appRouter: AppRouter
    let cart: CartStore
    let cartPresenter: CartPresenter
    let factory: AppClipScreenFactory

    static func live() -> CompositionRoot {
        let http = URLSessionHTTPClient()
        let repo = RemoteProductsRepository(http: http, feedURL: Configuration.productFeedURL())
        let cart = CartStore()
        let appRouter = AppRouter()
        let cartPresenter = CartPresenter()

        let factory = AppClipScreenFactory(
            makeCatalog: {
                CatalogView(viewModel: CatalogViewModel(repository: repo))
            },
            makeDetails: { handle in
                ProductDetailsView(
                    viewModel: ProductDetailsViewModel(handle: handle, repository: repo, cart: cart)
                )
            },
            makeCart: {
                CartView(viewModel: CartViewModel(cart: cart))
            }
        )

        return CompositionRoot(appRouter: appRouter, cart: cart, cartPresenter: cartPresenter, factory: factory)
    }
}
