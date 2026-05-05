import SwiftUI
import ReactiveShopKit

struct CatalogErrorState: View {
    let error: RepositoryError
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            Button("Try again", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
    }

    private var title: String {
        switch error {
        case .offline: return "You're offline"
        case .server, .decoding, .unknown, .notFound: return "Something went wrong"
        }
    }

    private var message: String {
        switch error {
        case .offline:
            return "Check your connection and try again."
        case .server, .decoding, .unknown:
            return "Please try again."
        case .notFound:
            // Not reachable on Catalog, but covered for completeness.
            return "We couldn't find what you were looking for."
        }
    }

    private var systemImage: String {
        switch error {
        case .offline: return "wifi.slash"
        case .server, .decoding, .unknown, .notFound: return "exclamationmark.triangle"
        }
    }
}
