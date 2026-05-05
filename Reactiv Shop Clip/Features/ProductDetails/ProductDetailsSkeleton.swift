import SwiftUI

struct ProductDetailsSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Rectangle()
                    .fill(Color(.tertiarySystemFill))
                    .aspectRatio(1, contentMode: .fit)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Product title placeholder")
                        .font(.title2.weight(.semibold))
                    Text("Vendor name")
                        .font(.subheadline)
                    Text("$00.00")
                        .font(.title3)
                    Text(String(repeating: "Lorem ipsum dolor sit amet. ", count: 4))
                        .font(.body)
                }
                .padding(.horizontal, 16)

                optionPlaceholder
                optionPlaceholder
            }
            .padding(.bottom, 24)
        }
        .redacted(reason: .placeholder)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private var optionPlaceholder: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Option")
                .font(.headline)
                .padding(.horizontal, 16)
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(Color(.systemGray6))
                        .frame(width: 60, height: 36)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
