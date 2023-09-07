// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BrewDesign",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "BrewDesign",
            targets: ["BrewDesign"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint.git", from: "0.52.4"),

        .package(path: "../BrewCore"),
        .package(path: "../BrewShared"),
    ],
    targets: [
        .target(
            name: "BrewDesign",
            dependencies: [
                "BrewCore",
                "BrewShared",
            ],
            resources: [
                .process("Resources"),
            ],
            plugins: [
               .plugin(name: "SwiftLintPlugin", package: "SwiftLint"),
            ]
        ),
//        .testTarget(
//            name: "BrewDesignTests",
//            dependencies: ["BrewDesign"]
//        ),
    ]
)
