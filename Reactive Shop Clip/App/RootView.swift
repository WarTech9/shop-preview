import SwiftUI
import ReactiveShopKit

struct RootView: View {
    @Environment(AppRouter.self) private var appRouter
    @Environment(CartPresenter.self) private var presenter
    @Environment(\.screenFactory) private var factory

    var body: some View {
        @Bindable var router = appRouter
        @Bindable var presenter = presenter

        NavigationStack(path: $router.path) {
            factory.makeCatalog()
                .navigationDestination(for: AppDestination.self) { destination in
                    switch destination {
                    case .productDetails(let handle):
                        factory.makeDetails(handle)
                    case .catalog:
                        // Catalog is the navigation root; never pushed onto the stack.
                        EmptyView()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        CartToolbarButton()
                    }
                }
        }
        .sheet(isPresented: $presenter.isShowingCart) {
            factory.makeCart()
        }
    }
}
