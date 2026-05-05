import Foundation
@testable import ReactivShopKit

/// Test double for `HTTPClient`. Responses are queued; the last queued response is repeated
/// for any extra calls so a single-response setup serves any number of fetches.
final class FakeHTTPClient: HTTPClient, @unchecked Sendable {
    private let lock = NSLock()
    private var queue: [Result<(Data, HTTPURLResponse), Error>] = []
    private var _callCount: Int = 0

    var callCount: Int {
        lock.withLock { _callCount }
    }

    init() {}

    func enqueue(_ result: Result<(Data, HTTPURLResponse), Error>) {
        lock.withLock { queue.append(result) }
    }

    func enqueueSuccess(_ data: Data, status: Int = 200) {
        let url = URL(string: "https://test.local")!
        let response = HTTPURLResponse(
            url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil
        )!
        enqueue(.success((data, response)))
    }

    func enqueueFailure(_ error: Error) {
        enqueue(.failure(error))
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let next: Result<(Data, HTTPURLResponse), Error>? = lock.withLock {
            _callCount += 1
            guard !queue.isEmpty else { return nil }
            return queue.count > 1 ? queue.removeFirst() : queue[0]
        }
        guard let next else { throw URLError(.unknown) }
        return try next.get()
    }
}
