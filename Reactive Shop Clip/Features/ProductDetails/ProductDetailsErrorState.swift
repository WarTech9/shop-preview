import SwiftUI
import ReactiveShopKit

struct ProductDetailsErrorState: View {
    let error: RepositoryError
    let onRetry: () -> Void
    let onBackToCatalog: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            primaryAction
        }
    }

    @ViewBuilder
    private var primaryAction: some View {
        switch error {
        case .notFound:
            // Retry won't change the result; offer the way out instead.
            Button("Browse catalog", action: onBackToCatalog)
                .buttonStyle(.borderedProminent)
        default:
            Button("Try again", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
    }

    private var title: String {
        switch error {
        case .offline: return "You're offline"
        case .notFound: return "We couldn't find that product"
        case .server, .decoding, .unknown: return "Something went wrong"
        }
    }

    private var message: String {
        switch error {
        case .offline:
            return "Check your connection and try again."
        case .notFound(let handle):
            return "We couldn't find a product matching \(handle)."
        case .server, .decoding, .unknown:
            return "Please try again."
        }
    }

    private var systemImage: String {
        switch error {
        case .offline: return "wifi.slash"
        case .notFound: return "questionmark.circle"
        case .server, .decoding, .unknown: return "exclamationmark.triangle"
        }
    }
}
