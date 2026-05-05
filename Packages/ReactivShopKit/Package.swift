// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ReactivShopKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ReactivShopKit", targets: ["ReactivShopKit"]),
    ],
    targets: [
        .target(name: "ReactivShopKit"),
        .testTarget(
            name: "ReactivShopKitTests",
            dependencies: ["ReactivShopKit"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
