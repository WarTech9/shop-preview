import SwiftUI

/// Replacement for `AsyncImage` that survives view re-appearance via a URL-keyed
/// `ImageCache`. `.task(id: url)` ensures the load only restarts when the URL itself
/// changes; `@State loaded` is preserved across re-appears under the same view identity,
/// so a cache hit returns synchronously with no flash of empty.
struct CachedAsyncImage<Content: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image?) -> Content

    @State private var loaded: UIImage?

    var body: some View {
        content(loaded.map { Image(uiImage: $0) })
            .task(id: url) {
                guard let url else { return }
                if let cached = ImageCache.shared.image(for: url) {
                    loaded = cached
                    return
                }
                guard let (data, _) = try? await URLSession.shared.data(from: url),
                      let image = UIImage(data: data) else { return }
                ImageCache.shared.store(image, for: url)
                loaded = image
            }
    }
}
