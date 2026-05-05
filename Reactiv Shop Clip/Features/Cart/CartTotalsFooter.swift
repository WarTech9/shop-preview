import SwiftUI
import ReactivShopKit

struct CartTotalsFooter: View {
    let itemCount: Int
    let subtotal: Money?
    let total: Money?

    var body: some View {
        VStack(spacing: 6) {
            row("Items", value: "\(itemCount)")
            row("Subtotal", value: subtotal?.formatted() ?? "—")
            Divider()
            row("Total", value: total?.formatted() ?? "—", emphasize: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(combinedAccessibilityLabel)
    }

    private func row(_ label: String, value: String, emphasize: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(emphasize ? .title3.weight(.semibold) : .subheadline)
                .foregroundStyle(emphasize ? .primary : .secondary)
            Spacer()
            Text(value)
                .font(emphasize ? .title3.bold().monospacedDigit() : .subheadline.monospacedDigit())
        }
    }

    private var combinedAccessibilityLabel: String {
        let sub = subtotal?.formatted() ?? "zero"
        let tot = total?.formatted() ?? "zero"
        return "\(itemCount) items, subtotal \(sub), total \(tot)"
    }
}
