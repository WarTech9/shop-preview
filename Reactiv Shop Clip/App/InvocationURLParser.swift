import Foundation

/// Pure URL → AppDestination translation for App Clip invocation URLs.
/// Strict host (`shop.reactivapp.com`), http/https only. Anything else falls back to `.catalog`.
/// Query strings and fragments are ignored. Trailing slashes are tolerated.
public enum InvocationURLParser {
    public static func destination(for url: URL) -> AppDestination {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "https" else { return .catalog }
        guard let host = url.host?.lowercased(),
              host == "shop.reactivapp.com" else { return .catalog }

        let segments = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }

        if segments == ["collections", "all"] {
            return .catalog
        }
        if segments.count == 2, segments[0] == "product", !segments[1].isEmpty {
            return .productDetails(handle: segments[1])
        }
        return .catalog
    }
}
