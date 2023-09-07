// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BrewShared",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "BrewShared",
            targets: ["BrewShared"]
        ),
    ],
    dependencies: [
       .package(url: "https://github.com/realm/SwiftLint", from: "0.52.4"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "BrewShared",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-enable-bare-slash-regex",
                ])
            ],
            plugins: [
//               .plugin(name: "SwiftLintPlugin", package: "SwiftLint"),
            ]
        ),
//        .testTarget(
//            name: "BrewSharedTests",
//            dependencies: ["BrewShared"]),
    ]
)
