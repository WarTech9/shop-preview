import Foundation

/// Generic four-state container used by view models to drive views with a single `switch`.
public enum LoadState<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case error(RepositoryError)
}

extension LoadState: Equatable where Value: Equatable {}
