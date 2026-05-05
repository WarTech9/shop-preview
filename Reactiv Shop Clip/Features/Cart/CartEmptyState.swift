import SwiftUI

struct CartEmptyState: View {
    let onBrowse: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Your cart is empty", systemImage: "bag")
        } actions: {
            Button("Browse products", action: onBrowse)
                .buttonStyle(.borderedProminent)
        }
    }
}
