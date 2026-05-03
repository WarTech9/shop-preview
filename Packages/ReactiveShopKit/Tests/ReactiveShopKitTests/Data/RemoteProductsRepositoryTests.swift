import Testing
import Foundation
@testable import ReactiveShopKit

@Suite struct RemoteProductsRepositoryTests {
    private let testURL = URL(string: "https://test.local/feed.json")!

    @Test func fetchAll_success_returnsMappedProducts() async throws {
        let client = FakeHTTPClient()
        client.enqueueSuccess(try FixtureLoader.loadProductsJSON())
        let repo = RemoteProductsRepository(http: client, feedURL: testURL)
        let products = try await repo.fetchAll()
        #expect(products.count == 4)
    }

    @Test func fetchAll_serverError_throwsServer() async throws {
        let client = FakeHTTPClient()
        client.enqueueSuccess(Data(), status: 500)
        let repo = RemoteProductsRepository(http: client, feedURL: testURL)
        await #expect(throws: RepositoryError.server(500)) {
            try await repo.fetchAll()
        }
    }

    @Test func fetchAll_offline_throwsOffline() async throws {
        let client = FakeHTTPClient()
        client.enqueueFailure(URLError(.notConnectedToInternet))
        let repo = RemoteProductsRepository(http: client, feedURL: testURL)
        await #expect(throws: RepositoryError.offline) {
            try await repo.fetchAll()
        }
    }

    @Test func fetchAll_garbageBody_throwsDecoding() async throws {
        let client = FakeHTTPClient()
        client.enqueueSuccess(Data("not json".utf8))
        let repo = RemoteProductsRepository(http: client, feedURL: testURL)
        await #expect(throws: RepositoryError.decoding) {
            try await repo.fetchAll()
        }
    }

    @Test func fetchHandle_known_returnsMatchingProduct() async throws {
        let client = FakeHTTPClient()
        client.enqueueSuccess(try FixtureLoader.loadProductsJSON())
        let repo = RemoteProductsRepository(http: client, feedURL: testURL)
        let product = try await repo.fetch(handle: "unisex-hoodie")
        #expect(product.handle == "unisex-hoodie")
    }

    @Test func fetchHandle_unknown_throwsNotFoundWithHandle() async throws {
        let client = FakeHTTPClient()
        client.enqueueSuccess(try FixtureLoader.loadProductsJSON())
        let repo = RemoteProductsRepository(http: client, feedURL: testURL)
        await #expect(throws: RepositoryError.notFound(handle: "does-not-exist")) {
            try await repo.fetch(handle: "does-not-exist")
        }
    }

    @Test func fetchAll_concurrentCalls_shareOneHTTPRequest() async throws {
        let client = FakeHTTPClient()
        client.enqueueSuccess(try FixtureLoader.loadProductsJSON())
        let repo = RemoteProductsRepository(http: client, feedURL: testURL)

        async let a = repo.fetchAll()
        async let b = repo.fetchAll()
        async let c = repo.fetchAll()
        _ = try await (a, b, c)

        #expect(client.callCount == 1)
    }

    @Test func fetchAll_secondCallAfterSuccess_servesFromCache() async throws {
        let client = FakeHTTPClient()
        client.enqueueSuccess(try FixtureLoader.loadProductsJSON())
        let repo = RemoteProductsRepository(http: client, feedURL: testURL)

        _ = try await repo.fetchAll()
        _ = try await repo.fetchAll()

        #expect(client.callCount == 1)
    }

    @Test func fetchAll_retryAfterFailure_attemptsFreshRequest() async throws {
        let client = FakeHTTPClient()
        client.enqueueFailure(URLError(.notConnectedToInternet))
        client.enqueueSuccess(try FixtureLoader.loadProductsJSON())
        let repo = RemoteProductsRepository(http: client, feedURL: testURL)

        await #expect(throws: RepositoryError.offline) {
            try await repo.fetchAll()
        }
        let products = try await repo.fetchAll()
        #expect(products.count == 4)
        #expect(client.callCount == 2)
    }
}
