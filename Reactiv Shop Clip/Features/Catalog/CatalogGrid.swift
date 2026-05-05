import SwiftUI
import ReactivShopKit

struct CatalogGrid: View {
    let products: [Product]

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(products) { product in
                    NavigationLink(value: AppDestination.productDetails(handle: product.handle)) {
                        CatalogTile(product: product)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens product details")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
    }
}
