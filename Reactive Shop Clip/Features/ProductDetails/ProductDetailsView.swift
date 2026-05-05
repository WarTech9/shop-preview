import SwiftUI
import ReactiveShopKit

struct ProductDetailsView: View {
    @Environment(AppRouter.self) private var appRouter
    @State private var viewModel: ProductDetailsViewModel
    
    init(viewModel: ProductDetailsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProductDetailsSkeleton()
            case .loaded(let product):
                loadedContent(product: product)
            case .error(let error):
                ProductDetailsErrorState(error: error) {
                    Task { await viewModel.retry() }
                } onBackToCatalog: {
                    appRouter.popToRoot()
                }
                
            }
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                CartToolbarButton()
            }
        }
        .task {
            await viewModel.load()
        }
        .sensoryFeedback(.success, trigger: viewModel.lastAddedAt)
    }
    
    private var navTitle: String {
        if case .loaded(let p) = viewModel.state {
            return p.title
        }
        return ""
    }
    
    @ViewBuilder
    private func loadedContent(product: Product) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ImageCarousel(
                    images: product.images,
                    targetImageId: viewModel.selectedVariant?.imageId
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(product.title).font(.title2.weight(.semibold))
                    Text(product.vendor).font(.subheadline).foregroundStyle(.secondary)
                    priceLine(product: product)
                    Text(product.description).font(.body).padding(.top, 4)
                }
                .padding(.horizontal, 16)
                
                ForEach(product.options) { option in
                    VariantPicker(
                        option: option,
                        availableValues: product.availableValues(for: option, given: viewModel.selection),
                        selectedValue: viewModel.selection[option.name],
                        onSelect: { viewModel.selection[option.name] = $0 }
                    )
                }
            }
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom) {
            addToCartBar(product: product)
        }
    }
    
    @ViewBuilder
    private func priceLine(product: Product) -> some View {
        let displayed = viewModel.selectedVariant?.price ?? product.priceRange.min
        HStack(spacing: 8) {
            Text(viewModel.selectedVariant?.price.formatted() ?? product.priceRange.formatted())
                .font(.title3.monospacedDigit())
            if let compareAt = viewModel.selectedVariant?.compareAtPrice, compareAt.amount > displayed.amount {
                Text(compareAt.formatted())
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .strikethrough()
                    .accessibilityLabel("Was \(compareAt.formatted())")
            }
        }
    }
    
    @ViewBuilder
    private func addToCartBar(product: Product) -> some View {
        Button {
            try? viewModel.addToCart()
        } label: {
            Text(buttonLabel(product: product))
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.canAddToCart)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private func buttonLabel(product: Product) -> String {
        if let variant = viewModel.selectedVariant {
            if !variant.isAvailable { return "Out of stock" }
            return "Add to Cart — \(variant.price.formatted())"
        }
        if let missing = product.options.first(where: { viewModel.selection[$0.name] == nil }) {
            return "Select \(missing.name)"
        }
        return "Add to Cart"
    }
}
