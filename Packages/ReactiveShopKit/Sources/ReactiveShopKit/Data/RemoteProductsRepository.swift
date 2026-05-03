import Foundation

public actor RemoteProductsRepository: ProductsRepository {
    private let http: HTTPClient
    private let feedURL: URL
    private var cachedProducts: [Product]?
    private var inflight: Task<[Product], Error>?

    public init(http: HTTPClient, feedURL: URL) {
        self.http = http
        self.feedURL = feedURL
    }

    public func fetchAll() async throws -> [Product] {
        if let cached = cachedProducts { return cached }
        if let existing = inflight { return try await existing.value }

        let task = Task { [http, feedURL] in
            try await Self.performFetch(http: http, url: feedURL)
        }
        inflight = task

        do {
            let products = try await task.value
            cachedProducts = products
            inflight = nil
            return products
        } catch {
            // Drop the failed task so a retry triggers a fresh request.
            inflight = nil
            throw error
        }
    }

    public func fetch(handle: String) async throws -> Product {
        let products = try await fetchAll()
        guard let product = products.first(where: { $0.handle == handle }) else {
            throw RepositoryError.notFound(handle: handle)
        }
        return product
    }

    private static func performFetch(http: HTTPClient, url: URL) async throws -> [Product] {
        let request = URLRequest(url: url)

        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await http.data(for: request)
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            throw RepositoryError.offline
        } catch {
            throw RepositoryError.unknown
        }

        guard (200..<300).contains(response.statusCode) else {
            throw RepositoryError.server(response.statusCode)
        }

        do {
            let dtos = try JSONDecoder().decode([ProductDTO].self, from: data)
            return dtos.compactMap(makeProduct)
        } catch {
            throw RepositoryError.decoding
        }
    }
}
