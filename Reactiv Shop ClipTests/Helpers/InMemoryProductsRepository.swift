import Foundation
@testable import ReactivShopKit

/// Test double for `ProductsRepository`. Configurable success or error outcome plus a
/// per-method call counter for idempotence assertions.
final class InMemoryProductsRepository: ProductsRepository, @unchecked Sendable {
    enum Outcome: Sendable {
        case success([Product])
        case failure(RepositoryError)
    }

    private let lock = NSLock()
    private var outcome: Outcome
    private var _fetchAllCount: Int = 0
    private var _fetchHandleCount: Int = 0

    var fetchAllCount: Int { lock.withLock { _fetchAllCount } }
    var fetchHandleCount: Int { lock.withLock { _fetchHandleCount } }

    init(outcome: Outcome) {
        self.outcome = outcome
    }

    func setOutcome(_ newOutcome: Outcome) {
        lock.withLock { outcome = newOutcome }
    }

    func fetchAll() async throws -> [Product] {
        let snapshot: Outcome = lock.withLock {
            _fetchAllCount += 1
            return outcome
        }
        switch snapshot {
        case .success(let products): return products
        case .failure(let error): throw error
        }
    }

    func fetch(handle: String) async throws -> Product {
        let snapshot: Outcome = lock.withLock {
            _fetchHandleCount += 1
            return outcome
        }
        switch snapshot {
        case .success(let products):
            guard let p = products.first(where: { $0.handle == handle }) else {
                throw RepositoryError.notFound(handle: handle)
            }
            return p
        case .failure(let error):
            throw error
        }
    }
}
