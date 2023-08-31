// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BrewCore",
    platforms: [.iOS(.v16), .macOS(.v14)],
    products: [
        .library(
            name: "BrewCore",
            targets: ["BrewCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tomasharkema/swift-rawjson.git", from: "0.0.21"),
        //    .package(url: "https://github.com/tomasharkema/swift-tracing.git", from: "0.0.22"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.1.0"),
        //        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
        //        .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "BrewCore",
            dependencies: [
                .product(name: "RawJson", package: "swift-rawjson"),
                //        .product(name: "SwiftTracing", package: "swift-tracing"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                //                .product(name: "Collections", package: "swift-collections"),
                //                .product(name: "Algorithms", package: "swift-algorithms"),
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-enable-bare-slash-regex",
                ])
            ]
        ),
        .testTarget(
            name: "BrewCoreTests",
            dependencies: ["BrewCore"]),
    ]
)
