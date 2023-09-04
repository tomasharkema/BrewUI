// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BrewCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "BrewCore",
            targets: ["BrewCore"]),
        .executable(name: "BrewImport", targets: ["BrewImport"])
    ],
    dependencies: [
        .package(url: "https://github.com/tomasharkema/swift-rawjson.git", from: "0.0.21"),
//        .package(url: "https://github.com/tomasharkema/swift-tracing.git", from: "0.0.22"),
        .package(url: "https://github.com/tomasharkema/swift-tracing.git", branch: "feature/fatalerror"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.1.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/tomasharkema/extract-case-value", branch: "main"),
//            .package(url: "https://github.com/ShenghaiWang/SwiftMacros.git", from: "1.0.0"),
//        .package(url: "https://github.com/bannzai/UtilityType", from: "1.0.0"),

//            .package(path: "../../extract-case-value"),
//        .package(path: "../../swift-tracing"),
    ],
    targets: [
        .target(
            name: "BrewCore",
            dependencies: [
                .product(name: "RawJson", package: "swift-rawjson"),
                .product(name: "SwiftTracing", package: "swift-tracing"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "ExtractCaseValue", package: "extract-case-value"),
//                .product(name: "UtilityType", package: "UtilityType"),
//                .product(name: "SwiftMacros", package: "SwiftMacros"),
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-enable-bare-slash-regex",
                ])
            ]
        ),
        .executableTarget(
            name: "BrewImport",
            dependencies: ["BrewCore"]),
        .testTarget(
            name: "BrewCoreTests",
            dependencies: ["BrewCore"]),
    ]
)
