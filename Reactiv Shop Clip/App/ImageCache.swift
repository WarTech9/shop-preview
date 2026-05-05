import UIKit

/// In-memory image cache keyed by URL. No eviction policy — App Clip lifetime is short
/// and the catalog has a small number of images. Swap to `NSCache` if memory pressure
/// becomes a concern.
@MainActor
final class ImageCache {
    static let shared = ImageCache()
    private init() {}

    private var cache: [URL: UIImage] = [:]

    func image(for url: URL) -> UIImage? { cache[url] }
    func store(_ image: UIImage, for url: URL) { cache[url] = image }
}
