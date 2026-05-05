import Foundation

enum FixtureLoader {
    /// Returns the raw bytes of `Fixtures/products.json`. Crashes loudly with a clear message
    /// if the resource isn't bundled — that's a build configuration bug, not a runtime concern.
    static func loadProductsJSON() throws -> Data {
        guard let url = Bundle.module.url(
            forResource: "products",
            withExtension: "json",
            subdirectory: "Fixtures"
        ) else {
            fatalError("Missing Fixtures/products.json in test bundle. Check Package.swift resources declaration.")
        }
        return try Data(contentsOf: url)
    }
}
