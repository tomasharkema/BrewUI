// swift-tools-version: 5.9

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("BareSlashRegexLiterals"),
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "BrewCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "BrewCore",
            targets: ["BrewCore"]
        ),
        .library(
            name: "BrewDesign",
            targets: ["BrewDesign"]
        ),        
        .library(
            name: "BrewShared",
            targets: ["BrewShared"]
        ),
//       .executable(name: "BrewImport", targets: ["BrewImport"])
    ],
    dependencies: [
        .package(url: "https://github.com/tomasharkema/swift-rawjson.git", from: "0.0.26"),
        .package(url: "https://github.com/tomasharkema/swift-tracing.git", from: "0.0.25"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.1.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
        .package(url: "https://github.com/ShenghaiWang/SwiftMacros.git", from: "1.2.0"),
//        .package(url: "https://github.com/bannzai/UtilityType", from: "1.0.0"),
        .package(url: "https://github.com/kishikawakatsumi/swift-power-assert.git", from: "0.12.0"),
    ],
    targets: [
        .target(
            name: "BrewCore",
            dependencies: [
                "BrewShared",
                "BrewHelpers",
                .product(name: "RawJson", package: "swift-rawjson"),
                .product(name: "SwiftTracing", package: "swift-tracing"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "SwiftMacros", package: "SwiftMacros"),
//                .product(name: "UtilityType", package: "UtilityType"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "BrewDesign",
            dependencies: [
                "BrewCore",
                "BrewShared",
            ],
            resources: [
                .process("Resources"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "BrewHelpers",
            dependencies: [
            ],
            swiftSettings: swiftSettings
        ),   
        .target(
            name: "BrewShared",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "SwiftMacros", package: "SwiftMacros"),
            ],
            swiftSettings: swiftSettings
        ),
//        .executableTarget(
//            name: "BrewImport",
//            dependencies: ["BrewCore"]
//        ),
        .testTarget(
            name: "BrewCoreTests",
            dependencies: [
                "BrewCore",
                "BrewShared",
                .product(name: "PowerAssert", package: "swift-power-assert"),
            ]
        ),
    ]
)
