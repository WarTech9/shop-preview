import SwiftUI
import ReactivShopKit

struct CartToolbarButton: View {
    @Environment(CartStore.self) private var cart
    @Environment(CartPresenter.self) private var presenter

    var body: some View {
        Button {
            presenter.isShowingCart = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "cart")
                    .font(.body)
                    .frame(width: 28, height: 28)

                if cart.cart.itemCount > 0 {
                    Text(badgeText)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.red, in: Capsule())
                        .overlay(
                            Capsule().stroke(Color(.systemBackground), lineWidth: 1.5)
                        )
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityLabel(cart.cart.itemCount > 0
                            ? "Cart, \(cart.cart.itemCount) items"
                            : "Cart")
    }

    private var badgeText: String {
        cart.cart.itemCount > 99 ? "99+" : "\(cart.cart.itemCount)"
    }
}
