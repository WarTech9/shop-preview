import Foundation

nonisolated
public enum AppDestination: Hashable, Sendable {
    case catalog
    case productDetails(handle: String)
}

@MainActor
public protocol AppRouting: AnyObject {
    var path: [AppDestination] { get }
    func push(_ destination: AppDestination)
    func pop()
    func popToRoot()
}
