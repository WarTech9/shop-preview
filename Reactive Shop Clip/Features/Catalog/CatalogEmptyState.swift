import SwiftUI

struct CatalogEmptyState: View {
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No products available right now.", systemImage: "bag")
        } actions: {
            Button("Try again", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
    }
}
