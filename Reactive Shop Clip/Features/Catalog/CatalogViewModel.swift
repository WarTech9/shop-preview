import Foundation
import Observation

@MainActor
@Observable
public final class CatalogViewModel {
    public private(set) var state: LoadState<[Product]> = .idle

    private let repository: ProductsRepository

    public init(repository: ProductsRepository) {
        self.repository = repository
    }

    /// Strictly idle-gated. Only callers that can guarantee `.idle` (initial `.task` on appear)
    /// trigger a fetch. From `.error`, only `retry()` can advance — preventing accidental
    /// auto-retry if `.task` ever re-fires while in error state.
    public func load() async {
        guard case .idle = state else { return }
        state = .loading
        do {
            let products = try await repository.fetchAll()
            state = .loaded(products)
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
}
