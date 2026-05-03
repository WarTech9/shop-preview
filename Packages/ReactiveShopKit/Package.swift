// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ReactiveShopKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ReactiveShopKit", targets: ["ReactiveShopKit"]),
    ],
    targets: [
        .target(name: "ReactiveShopKit"),
        .testTarget(
            name: "ReactiveShopKitTests",
            dependencies: ["ReactiveShopKit"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
