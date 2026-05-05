import SwiftUI

struct CatalogSkeleton: View {
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonTile()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private struct SkeletonTile: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color(.tertiarySystemFill))
                    .aspectRatio(1, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text("Placeholder title")
                    .font(.subheadline.weight(.medium))
                Text("$00.00")
                    .font(.headline)
            }
            .redacted(reason: .placeholder)
        }
    }
}
