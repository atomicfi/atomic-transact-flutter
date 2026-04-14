// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "atomic_transact_flutter",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "atomic-transact-flutter", targets: ["atomic_transact_flutter"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/atomicfi/atomic-transact-ios.git", from: "3.28.0")
    ],
    targets: [
        .target(
            name: "atomic_transact_flutter",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "AtomicTransact", package: "atomic-transact-ios")
            ],
            cSettings: [
                .headerSearchPath("include/atomic_transact_flutter")
            ]
        )
    ]
)
