import SwiftUI
import ReactiveShopKit

struct CatalogView: View {
    @State private var viewModel: CatalogViewModel
    
    init(viewModel: CatalogViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                CatalogSkeleton()
            case .loaded(let products) where products.isEmpty:
                CatalogEmptyState {
                    Task {
                        await viewModel.retry()
                    }
                }
            case .loaded(let products):
                CatalogGrid(products: products)
            case .error(let error):
                CatalogErrorState(error: error) {
                    Task {
                        await viewModel.retry()
                    }
                }
            }
        }
        .navigationTitle("Reactive Shop")
        .task {
            await  viewModel.load()
        }
    }
}
