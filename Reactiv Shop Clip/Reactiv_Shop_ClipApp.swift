import SwiftUI
import ReactivShopKit

@main
struct Reactiv_Shop_ClipApp: App {
    @State private var root = CompositionRoot.live()

    var body: some Scene {
        WindowGroup {
            RootView(factory: root.factory)
                .environment(root.appRouter)
                .environment(root.cart)
                .environment(root.cartPresenter)
                .task {
                    if let raw = ProcessInfo.processInfo.environment["_XCAppClipURL"],
                       let url = URL(string: raw) {
                        root.appRouter.push(InvocationURLParser.destination(for: url))
                    }
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    if let url = activity.webpageURL {
                        root.appRouter.push(InvocationURLParser.destination(for: url))
                    }
                }
        }
    }
}
