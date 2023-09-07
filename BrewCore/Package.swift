// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BrewCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "BrewCore",
            targets: ["BrewCore"]
        ),
       .executable(name: "BrewImport", targets: ["BrewImport"])
    ],
    dependencies: [
        .package(path: "../BrewShared"),

       .package(url: "https://github.com/realm/SwiftLint.git", from: "0.52.4"),
        .package(url: "https://github.com/tomasharkema/swift-rawjson.git", from: "0.0.26"),
        .package(url: "https://github.com/tomasharkema/swift-tracing.git", from: "0.0.25"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.0.0"),
//        .package(url: "https://github.com/tomasharkema/extract-case-value", branch: "main"),
//        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.1.0"),
//        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
//            .package(url: "https://github.com/ShenghaiWang/SwiftMacros.git", from: "1.0.0"),
//        .package(url: "https://github.com/bannzai/UtilityType", from: "1.0.0"),
//            .package(path: "../../extract-case-value"),
//        .package(path: "../../swift-tracing"),
    ],
    targets: [
        .target(
            name: "BrewCore",
            dependencies: [
                "BrewShared",
                .product(name: "RawJson", package: "swift-rawjson"),
                .product(name: "SwiftTracing", package: "swift-tracing"),
                .product(name: "Algorithms", package: "swift-algorithms"),
//                .product(name: "ExtractCaseValue", package: "extract-case-value"),
//                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
//                .product(name: "Collections", package: "swift-collections"),
//                .product(name: "UtilityType", package: "UtilityType"),
//                .product(name: "SwiftMacros", package: "SwiftMacros"),
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-enable-bare-slash-regex",
                ])
            ],
            plugins: [
               .plugin(name: "SwiftLintPlugin", package: "SwiftLint"),
            ]
        ),
       .executableTarget(
           name: "BrewImport",
           dependencies: ["BrewCore"]),
//        .testTarget(
//            name: "BrewCoreTests",
//            dependencies: ["BrewCore"]),
    ]
)
