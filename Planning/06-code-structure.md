# 06 — Code Structure

## Repository layout

```
Reactive Shop/                          # repo root
├── Reactive Shop.xcodeproj
├── Reactive Shop/                      # main app target (thin shell)
│   ├── Reactive_ShopApp.swift          # @main, builds RootView from package
│   └── Assets.xcassets
├── Reactive Shop Clip/                 # App Clip target (thin shell)
│   ├── Reactive_Shop_ClipApp.swift     # @main, _XCAppClipURL + onContinueUserActivity
│   ├── Info.plist                      # NSAppClip
│   ├── Reactive_Shop_Clip.entitlements
│   └── Assets.xcassets
├── Reactive ShopTests/                 # Swift Testing host for the package
├── Reactive ShopUITests/               # (kept; brief doesn't require UI tests)
├── Reactive Shop ClipTests/
├── Reactive Shop ClipUITests/
├── Packages/
│   └── ReactiveShopKit/                # local SPM package — all real code lives here
│       ├── Package.swift
│       ├── Sources/ReactiveShopKit/
│       │   ├── Domain/
│       │   ├── Data/
│       │   ├── Services/
│       │   ├── Features/
│       │   │   ├── Catalog/
│       │   │   ├── ProductDetails/
│       │   │   └── Cart/
│       │   └── App/
│       └── Tests/ReactiveShopKitTests/
│           ├── Fixtures/
│           ├── Domain/
│           ├── Data/
│           ├── Services/
│           └── Features/
├── Docs/                               # this folder
├── README.md
└── DECISION_LOG.md
```

## Package contents (file-per-type)

```
Sources/ReactiveShopKit/
├── Domain/
│   ├── Money.swift
│   ├── PriceRange.swift
│   ├── Product.swift                   # Product, ProductImage, ProductOption
│   ├── ProductVariant.swift            # ProductVariant, SelectedOption
│   ├── Cart.swift                      # Cart, CartLine
│   └── Product+Selection.swift         # extension on Product: variant matching helpers
├── Data/
│   ├── HTTPClient.swift                # protocol + URLSessionHTTPClient
│   ├── ProductsRepository.swift        # protocol
│   ├── RemoteProductsRepository.swift
│   ├── RepositoryError.swift
│   └── DTOs/
│       ├── ProductDTO.swift            # mirrors wire shape
│       └── ProductDTO+Mapping.swift    # DTO → Domain
├── Services/
│   ├── CartStoring.swift               # protocol
│   ├── CartStore.swift                 # @Observable, mutations
│   ├── URLRouting.swift                # protocol
│   └── Router.swift                    # Route enum + URL parsing
├── Features/
│   ├── Catalog/
│   │   ├── CatalogView.swift
│   │   ├── CatalogViewModel.swift
│   │   └── CatalogRow.swift
│   ├── ProductDetails/
│   │   ├── ProductDetailsView.swift
│   │   ├── ProductDetailsViewModel.swift
│   │   ├── VariantPicker.swift
│   │   └── ImageCarousel.swift
│   └── Cart/
│       ├── CartView.swift
│       ├── CartViewModel.swift
│       └── CartLineRow.swift
├── App/
│   ├── RootView.swift                  # switches on Router.route
│   ├── CompositionRoot.swift           # makeRoot() factory
│   ├── ScreenFactory.swift             # makeCatalog / makeDetails / makeCart closures
│   └── LoadState.swift                 # generic .idle | .loading | .loaded | .error
└── Resources/                          # (none expected)
```

## Naming & file conventions

- One primary type per file. Tightly-coupled helpers live in the same file.
- Files named after the primary type (`CatalogViewModel.swift`).
- Extensions get their own file when **either** (a) they cross a layer boundary (e.g. `Data/DTOs/ProductDTO+Mapping.swift`), **or** (b) the topic is substantial enough to deserve a dedicated file and `<Type>+<Topic>.swift` reads more honestly than a topic-named alternative (e.g. `Domain/Product+Selection.swift`). Avoid splitting trivial conformances or one-method helpers — those stay in the primary file.
- View files end in `View`; row/cell views end in `Row`; pickers/components keep their concrete names.
- View models end in `ViewModel`. They're `@MainActor @Observable final class`.
- Protocols are noun-based (`ProductsRepository`, not `ProductsRepositoryProtocol`).

## Target memberships

| Source | Main app | Clip | Tests |
|---|---|---|---|
| `ReactiveShopKit` package | imports | imports | imports |
| `Reactive_ShopApp.swift` | ✓ | — | — |
| `Reactive_Shop_ClipApp.swift` | — | ✓ | — |
| App icons / accent colours | per-target asset catalog | per-target asset catalog | — |

Both app entry points construct the same `RootView` from `CompositionRoot.makeRoot()`. The Clip's entry point additionally:

```swift
.onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
    if let url = activity.webpageURL { router.handle(url: url) }
}
.task {
    if let raw = ProcessInfo.processInfo.environment["_XCAppClipURL"],
       let url = URL(string: raw) { router.handle(url: url) }
}
```

## Tests

- `Tests/ReactiveShopKitTests/` mirrors `Sources/` one-to-one.
- `Fixtures/products.json` is a captured snapshot of the live gist (committed) so tests are deterministic and offline.
- `Data/RemoteProductsRepositoryTests.swift` uses `URLProtocol` stubs — no network in CI.
- The host targets (`Reactive ShopTests`, `Reactive Shop ClipTests`) re-export the package tests via `@testable import ReactiveShopKit`. A single test file in each host calls into the package suite, so `xcodebuild ... test` runs everything from either scheme.
