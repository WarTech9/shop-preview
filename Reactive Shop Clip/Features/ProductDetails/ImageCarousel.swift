import SwiftUI
import ReactiveShopKit

struct ImageCarousel: View {
    let images: [ProductImage]
    /// When non-nil and the id matches one of `images`, the carousel scrolls to that page.
    let targetImageId: String?

    @State private var page: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if images.isEmpty {
                Rectangle()
                    .fill(Color(.tertiarySystemFill))
                    .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                    .accessibilityHidden(true)
            } else {
                TabView(selection: $page) {
                    ForEach(Array(images.enumerated()), id: \.element.id) { index, image in
                        AsyncImage(
                            url: image.url,
                            transaction: Transaction(animation: .easeOut(duration: 0.15))
                        ) { phase in
                            switch phase {
                            case .empty:
                                Rectangle().fill(Color(.tertiarySystemFill))
                            case .success(let img):
                                img.resizable().scaledToFill()
                            case .failure:
                                Rectangle().fill(Color(.tertiarySystemFill))
                                    .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                            @unknown default:
                                Rectangle().fill(Color(.tertiarySystemFill))
                            }
                        }
                        .clipped()
                        .tag(index)
                        .accessibilityLabel("Image \(index + 1) of \(images.count)")
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onChange(of: targetImageId) { _, newId in
            guard let id = newId,
                  let idx = images.firstIndex(where: { $0.id == id }) else { return }
            if reduceMotion {
                page = idx
            } else {
                withAnimation(.easeInOut(duration: 0.25)) { page = idx }
            }
        }
    }
}
