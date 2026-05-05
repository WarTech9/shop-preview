import Foundation

public protocol ProductsRepository: Sendable {
    func fetchAll() async throws -> [Product]
    func fetch(handle: String) async throws -> Product
}
