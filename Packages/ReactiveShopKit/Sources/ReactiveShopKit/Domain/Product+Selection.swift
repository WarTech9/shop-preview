import Foundation

extension Product {
    /// Values the user can still pick for `option` without dead-ending in an unavailable variant,
    /// given everything they've already chosen. Picks for `option` itself are ignored so the user
    /// can change their selection on the same option without it filtering itself.
    public func availableValues(for option: ProductOption,
                                given selection: [String: String]) -> Set<String> {
        var partial = selection
        partial[option.name] = nil

        var available = Set<String>()
        for variant in variants where variant.isAvailable {
            let satisfies = partial.allSatisfy { name, value in
                variant.selectedOptions.contains { $0.name == name && $0.value == value }
            }
            guard satisfies else { continue }
            if let v = variant.selectedOptions.first(where: { $0.name == option.name })?.value {
                available.insert(v)
            }
        }
        return available
    }

    /// Resolves a complete selection (every option name present) to the matching variant.
    /// Returns nil if the selection is incomplete or no variant matches. Availability of the
    /// resolved variant is the caller's concern (drives the Add-to-Cart enabled state).
    public func variant(matching selection: [String: String]) -> ProductVariant? {
        guard selection.count == options.count else { return nil }
        for option in options where selection[option.name] == nil { return nil }
        return variants.first { variant in
            selection.allSatisfy { name, value in
                variant.selectedOptions.contains { $0.name == name && $0.value == value }
            }
        }
    }
}
