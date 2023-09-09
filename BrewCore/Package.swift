// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BrewCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "BrewShared",
            targets: ["BrewShared"]
        ),
        .library(
            name: "BrewCore",
            targets: ["BrewCore", "BrewHelpers"]
        ),
        .library(
            name: "BrewDesign",
            targets: ["BrewDesign"]
        ),
       .executable(name: "BrewImport", targets: ["BrewImport"])
    ],
    dependencies: [
//        .package(url: "https://github.com/realm/SwiftLint.git", from: "0.52.4"),

        .package(url: "https://github.com/tomasharkema/swift-rawjson.git", from: "0.0.26"),
        .package(url: "https://github.com/tomasharkema/swift-tracing.git", from: "0.0.25"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.0.0"),
        .package(url: "https://github.com/tomasharkema/extract-case-value", branch: "main"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.1.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
        .package(url: "https://github.com/ShenghaiWang/SwiftMacros.git", from: "1.0.0"),
        .package(url: "https://github.com/bannzai/UtilityType", from: "1.0.0"),
        .package(url: "https://github.com/kishikawakatsumi/swift-power-assert.git", from: "0.12.0"),
    ],
    targets: [
        .target(
            name: "BrewShared",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ExistentialAny"),
            ],
            plugins: [
//                .plugin(name: "SwiftLintPlugin", package: "SwiftLint"),
            ]
        ),
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
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ExistentialAny"),
            ],
            plugins: [
//               .plugin(name: "SwiftLintPlugin", package: "SwiftLint"),
            ]
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
                swiftSettings: [
                    .enableUpcomingFeature("ConciseMagicFile"),
                    .enableUpcomingFeature("BareSlashRegexLiterals"),
                    .enableUpcomingFeature("ExistentialAny"),
                ],
                plugins: [
//                    .plugin(name: "SwiftLintPlugin", package: "SwiftLint"),
                ]
            ),
        .target(
            name: "BrewHelpers",
            dependencies: [
            ],
            swiftSettings: [
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ExistentialAny"),
            ],
            plugins: [
                //                .plugin(name: "SwiftLintPlugin", package: "SwiftLint"),
            ]
        ),
       .executableTarget(
           name: "BrewImport",
           dependencies: ["BrewCore"]),
        .testTarget(
            name: "BrewCoreTests",
            dependencies: [
                "BrewCore",
                .product(name: "PowerAssert", package: "swift-power-assert"),
            ]
        ),
    ]
)
