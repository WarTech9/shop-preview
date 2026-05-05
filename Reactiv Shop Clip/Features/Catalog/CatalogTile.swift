import SwiftUI
import ReactivShopKit

struct CatalogTile: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            productImage
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(3)
                    .foregroundStyle(.primary)
                Text(product.priceRange.formatted())
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var productImage: some View {
        AsyncImage(url: product.images.first?.url, transaction: Transaction(animation: .easeOut(duration: 0.15))) { phase in
            switch phase {
            case .empty:
                Rectangle().fill(Color(.tertiarySystemFill))
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                Rectangle().fill(Color(.tertiarySystemFill))
                    .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
            @unknown default:
                Rectangle().fill(Color(.tertiarySystemFill))
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .frame(maxWidth: .infinity)
        .clipped()
        .saturation(product.isAvailable ? 1 : 0)
        .overlay(alignment: .topTrailing) {
            if !product.isAvailable {
                Text("Out of stock")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.regularMaterial, in: Capsule())
                    .padding(8)
            }
        }
    }

    private var accessibilityLabel: String {
        var parts = [product.title, product.priceRange.formatted()]
        if !product.isAvailable { parts.append("out of stock") }
        return parts.joined(separator: ", ")
    }
}
