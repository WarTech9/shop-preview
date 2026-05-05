import SwiftUI
import ReactivShopKit

struct CartLineRow: View {
    let line: CartLine
    let onQuantityChange: (Int) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(line.product.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                Text(line.variant.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(line.variant.price.formatted())
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(infoAccessibilityLabel)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                Text(line.lineTotal.formatted())
                    .font(.headline)
                    .monospacedDigit()
                    .accessibilityLabel("Line total \(line.lineTotal.formatted())")

                Stepper(
                    value: Binding(
                        get: { line.quantity },
                        set: { onQuantityChange($0) }
                    ),
                    in: 0...99
                ) {
                    Text("Quantity")   // labelsHidden(); used by VoiceOver
                }
                .labelsHidden()
                .accessibilityValue("\(line.quantity)")
            }
        }
        .padding(.vertical, 4)
    }

    private var thumbnail: some View {
        AsyncImage(
            url: line.product.images.first?.url,
            transaction: Transaction(animation: .easeOut(duration: 0.15))
        ) { phase in
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
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityHidden(true)   // info text already names the product
    }

    private var infoAccessibilityLabel: String {
        "\(line.product.title), \(line.variant.title), unit price \(line.variant.price.formatted())"
    }
}
