// swift-tools-version: 5.9

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("BareSlashRegexLiterals"),
//    .enableUpcomingFeature("ExistentialAny"),
]

// .package(url: "https://github.com/ShenghaiWang/SwiftMacros", from: "1.2.0"),
// .package(url: "https://github.com/securevale/swift-confidential", from: "0.3.0"),
// .package(url: "https://github.com/securevale/swift-confidential-plugin", from: "0.3.0"),

let package = Package(
    name: "BrewCore",
    platforms: [.macOS(.v14)],
    products: [
        .executable(
            name: "BrewUIApp",
            targets: ["BrewUIApp"]
        ),
        .library(
            name: "BrewUIKit",
            targets: ["BrewUIKit"]
        ),
        .library(
            name: "BrewCore",
            targets: ["BrewCore"]
        ),
    ],
    dependencies: [        
//        .package(path: "../../ActoolBuildPlugin"),

        .package(url: "https://github.com/tomasharkema/swift-rawjson", from: "0.0.26"),
        .package(url: "https://github.com/tomasharkema/swift-tracing", from: "0.0.25"),
        .package(url: "https://github.com/tomasharkema/SwiftMacros", branch: "main"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
        .package(url: "https://github.com/SwiftyLab/MetaCodable", from: "1.0.0"),
        .package(url: "https://github.com/realm/SwiftLint", from: "0.53.0"),
//        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.52.0"),
        .package(url: "https://github.com/SwiftedMind/Processed", from: "1.0.0"),
        .package(url: "https://github.com/kishikawakatsumi/swift-power-assert", from: "0.12.0"),
    ],
    targets: [
        .executableTarget(
            name: "BrewUIApp",
            dependencies: [
                "BrewUIKit",
                "BrewCore",
                "BrewDesign",
                "BrewShared",
            ],
            resources: [
                .process("Resources"),
            ],
            swiftSettings: swiftSettings,
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Supporting/Info.plist",
                ]),
            ],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLint"),
//                .plugin(name: "ActoolBuildPlugin", package: "ActoolBuildPlugin"),
            ]
        ),
        .target(
            name: "BrewUIKit",
            dependencies: [
                "BrewCore",
                "BrewDesign",
                "BrewShared",

                .product(name: "Processed", package: "Processed"),
            ],
            swiftSettings: swiftSettings,
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLint"),
//                .plugin(name: "ActoolBuildPlugin", package: "ActoolBuildPlugin"),
            ]
        ),
        .target(
            name: "BrewCore",
            dependencies: [
                "BrewShared",
                "BrewHelpers",
                .product(name: "RawJson", package: "swift-rawjson"),
                .product(name: "SwiftTracing", package: "swift-tracing"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "SwiftMacros", package: "SwiftMacros"),
                .product(name: "MetaCodable", package: "MetaCodable"),
                .product(name: "Processed", package: "Processed"),
            ],
            swiftSettings: swiftSettings,
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLint"),
            ]
        ),
        .target(
            name: "BrewDesign",
            dependencies: [
                "BrewCore",
                "BrewShared",

                .product(name: "Processed", package: "Processed"),
            ],
            resources: [
                .process("Resources"),
            ],
            swiftSettings: swiftSettings,
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLint"),
//                .plugin(name: "ActoolBuildPlugin", package: "ActoolBuildPlugin"),
            ]
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
                .product(name: "SwiftMacros", package: "SwiftMacros"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "MetaCodable", package: "MetaCodable"),
            ],
            swiftSettings: swiftSettings,
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLint"),
            ]
        ),
        .testTarget(
            name: "BrewCoreTests",
            dependencies: [
                "BrewCore",
                "BrewShared",
                .product(name: "PowerAssert", package: "swift-power-assert"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)
