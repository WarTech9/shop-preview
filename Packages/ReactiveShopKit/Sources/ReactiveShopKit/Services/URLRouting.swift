import Foundation

public enum Route: Equatable, Sendable {
    case catalog
    case product(handle: String)
}

@MainActor
public protocol URLRouting: AnyObject {
    var route: Route { get }
    func handle(url: URL)
}
