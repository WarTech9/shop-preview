import Foundation

/// Reads app-shell configuration from the consuming target's Info.plist. A missing or malformed
/// value is treated as a build-configuration bug, not a runtime error — fail fast and loud.
enum Configuration {
    static func productFeedURL(bundle: Bundle = .main) -> URL {
        guard let raw = bundle.object(forInfoDictionaryKey: "ProductFeedURL") as? String else {
            preconditionFailure("Missing 'ProductFeedURL' in Info.plist. Add INFOPLIST_KEY_ProductFeedURL build setting on the App Clip target.")
        }
        guard let url = URL(string: raw) else {
            preconditionFailure("Malformed 'ProductFeedURL' in Info.plist: \(raw)")
        }
        return url
    }
}
