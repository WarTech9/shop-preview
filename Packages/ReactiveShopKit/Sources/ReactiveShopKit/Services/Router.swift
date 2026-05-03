import Foundation
import Observation

@MainActor
@Observable
public final class Router: URLRouting {
    public private(set) var route: Route = .catalog

    public init() {}

    public func handle(url: URL) {
        route = Self.parse(url)
    }

    /// Pure URL → Route parser. Strict host (`shop.reactivapp.com`), http/https only.
    /// Anything else falls back to `.catalog`. Query strings and fragments are ignored.
    nonisolated public static func parse(_ url: URL) -> Route {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else { return .catalog }
        guard let host = url.host?.lowercased(),
              host == "shop.reactivapp.com" else { return .catalog }

        let segments = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }

        if segments == ["collections", "all"] {
            return .catalog
        }
        if segments.count == 2, segments[0] == "product", !segments[1].isEmpty {
            return .product(handle: segments[1])
        }
        return .catalog
    }
}
