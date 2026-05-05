import Foundation
import Observation

@MainActor
@Observable
public final class ProductDetailsViewModel {
    public private(set) var state: LoadState<Product> = .idle
    public var selection: [String: String] = [:]
    public private(set) var lastAddedAt: Date?

    private let handle: String
    private let repository: ProductsRepository
    private let cart: CartStoring

    public init(handle: String, repository: ProductsRepository, cart: CartStoring) {
        self.handle = handle
        self.repository = repository
        self.cart = cart
    }

    /// Strictly idle-gated. From `.error`, only `retry()` can advance.
    public func load() async {
        guard case .idle = state else { return }
        state = .loading
        do {
            let product = try await repository.fetch(handle: handle)
            state = .loaded(product)
        } catch let err as RepositoryError {
            state = .error(err)
        } catch {
            state = .error(.unknown)
        }
    }

    public func retry() async {
        state = .idle
        await load()
    }

    /// nil when product isn't loaded, selection is incomplete, or no variant matches.
    public var selectedVariant: ProductVariant? {
        guard case .loaded(let product) = state else { return nil }
        return product.variant(matching: selection)
    }

    public var canAddToCart: Bool {
        selectedVariant?.isAvailable == true
    }

    /// No-op if selection is incomplete or the resolved variant is unavailable.
    /// Throws `CartError.currencyMismatch` if the cart already holds another currency.
    public func addToCart() throws {
        guard
            case .loaded(let product) = state,
            let variant = selectedVariant,
            variant.isAvailable
        else { return }
        try cart.add(variant, of: product)
        lastAddedAt = Date()
    }
}
