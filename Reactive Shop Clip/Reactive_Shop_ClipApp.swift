//
//  Reactive_Shop_ClipApp.swift
//  Reactive Shop Clip
//
//  Created by John Warmann on 2026-05-03.
//

import SwiftUI
import ReactiveShopKit

@main
struct Reactive_Shop_ClipApp: App {
    @State private var root = CompositionRoot.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(root.appRouter)
                .environment(root.cart)
                .environment(root.cartPresenter)
                .environment(\.screenFactory, root.factory)
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
