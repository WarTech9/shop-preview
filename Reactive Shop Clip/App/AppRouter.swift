import Foundation
import Observation

@MainActor
@Observable
public final class AppRouter: AppRouting {
    /// Public `var` (not `private(set)`) so SwiftUI's `@Bindable` can write through this
    /// when the user back-gestures `NavigationStack`. The canonical mutation API remains
    /// `push` / `pop` / `popToRoot` — direct path assignment is the SwiftUI escape hatch.
    public var path: [AppDestination] = []

    public init() {}

    public func push(_ destination: AppDestination) {
        if case .catalog = destination {
            path.removeAll()
        } else {
            path.append(destination)
        }
    }

    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    public func popToRoot() {
        path.removeAll()
    }
}
