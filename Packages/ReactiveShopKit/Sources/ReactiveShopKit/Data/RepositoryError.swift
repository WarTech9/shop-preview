import Foundation

public enum RepositoryError: Error, Equatable {
    case offline
    case server(Int)
    case decoding
    case notFound(handle: String)
    case unknown
}
