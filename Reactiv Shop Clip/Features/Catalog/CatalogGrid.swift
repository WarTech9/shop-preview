import SwiftUI
import ReactivShopKit

struct CatalogGrid: View {
    let products: [Product]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
       let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
       return Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
    }
    
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
