// swift-tools-version: 5.9

import PackageDescription

let swiftSettings: [SwiftSetting] = [
  .enableUpcomingFeature("ConciseMagicFile"),
  .enableUpcomingFeature("BareSlashRegexLiterals"),
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("DisableOutwardActorInference"),
  .enableExperimentalFeature("AccessLevelOnImport"),
  .enableExperimentalFeature("VariadicGenerics"),
  .unsafeFlags(["-warn-concurrency"], .when(configuration: .debug)),
]

// .package(url: "https://github.com/ShenghaiWang/SwiftMacros", from: "1.2.0"),
// .package(url: "https://github.com/securevale/swift-confidential", from: "0.3.0"),
// .package(url: "https://github.com/securevale/swift-confidential-plugin", from: "0.3.0"),

let swiftUiDependency: [Package.Dependency] = [
  .package(url: "https://github.com/realm/SwiftLint", from: "0.53.0"),
]

let swiftUiPlugin: [Target.PluginUsage] = [
  .plugin(name: "SwiftLintPlugin", package: "SwiftLint"),
]

let package = Package(
  name: "BrewCore",
  platforms: [.macOS(.v14)],
  products: [
    .executable(
      name: "BrewUIApp",
      targets: ["BrewUIApp"]
    ),
    .executable(
      name: "BrewUIHelper",
      targets: ["BrewUIHelper"]
    ),
    .library(
      name: "BrewUIKit",
      targets: ["BrewUIKit"]
    ),
    .library(
      name: "BrewCore",
      targets: ["BrewCore"]
    ),
    .library(
      name: "BrewUIHelperKit", targets: ["BrewUIHelperKit"]
    ),
  ],
  dependencies: [
//    .package(path: "../../ActoolBuildPlugin"),

.package(url: "https://github.com/tomasharkema/Injected", from: "0.0.1"),

    .package(url: "https://github.com/tomasharkema/swift-rawjson", from: "0.0.26"),
//    .package(url: "https://github.com/tomasharkema/swift-tracing", from: "0.0.25"),
    .package(url: "https://github.com/tomasharkema/SwiftMacros", branch: "main"),
    .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
    .package(url: "https://github.com/tomasharkema/MetaCodable", from: "0.0.1"),
//    .package(url: "https://github.com/SwiftyLab/MetaCodable", from: "1.0.0"),
    .package(url: "https://github.com/SwiftedMind/Processed", from: "1.0.0"),
    .package(url: "https://github.com/kishikawakatsumi/swift-power-assert", from: "0.12.0"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.3"),
//    .package(url: "https://github.com/Alkenso/SwiftConvenience", from: "0.2.0"),
    .package(url: "https://github.com/Alkenso/sXPC", from: "0.2.2"),
    .package(url: "https://github.com/sersoft-gmbh/semver", from: "5.0.0"),
    .package(url: "https://github.com/p-x9/RunScriptPlugin", from: "0.3.0"),
    .package(url: "https://github.com/1024jp/GzipSwift", from: "6.0.0"),

  ] + swiftUiDependency,
  targets: [
    .executableTarget(
      name: "BrewUIApp",
      dependencies: [
        "BrewUIKit",
        "BrewCore",
        "BrewDesign",
        "BrewShared",
        "Injected",
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
//                .plugin(name: "ActoolBuildPlugin", package: "ActoolBuildPlugin"),
      ] + swiftUiPlugin
    ),
    .target(
      name: "BrewUIHelperKit",
      dependencies: [
        "BrewShared",
        "BrewCore",
        "sXPC",
      ],
      swiftSettings: swiftSettings,
      plugins: [
//        .plugin(name: "ActoolBuildPlugin", package: "ActoolBuildPlugin"),
      ] + swiftUiPlugin
    ),
    .executableTarget(
      name: "BrewUIHelper",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),

        "BrewUIHelperKit",
      ],
      swiftSettings: swiftSettings,
      plugins: [
//        .plugin(name: "ActoolBuildPlugin", package: "ActoolBuildPlugin"),
      ] + swiftUiPlugin
    ),
    .target(
      name: "BrewUIKit",
      dependencies: [
        "BrewCore",
        "BrewDesign",
        "BrewShared",
        "Injected",

        .product(name: "Processed", package: "Processed"),
      ],
      resources: [
        .process("Resources"),
      ],
      swiftSettings: swiftSettings,
      plugins: [
//        .plugin(name: "ActoolBuildPlugin", package: "ActoolBuildPlugin"),
      ] + swiftUiPlugin
    ),
    .target(
      name: "BrewCore",
      dependencies: [
        "BrewShared",
        "BrewHelpers",
        "Injected",
        "BrewHelperXPC",

        .product(name: "RawJson", package: "swift-rawjson"),
//        .product(name: "SwiftTracing", package: "swift-tracing"),
        .product(name: "Algorithms", package: "swift-algorithms"),
        .product(name: "Collections", package: "swift-collections"),
        .product(name: "SwiftMacros", package: "SwiftMacros"),
        .product(name: "MetaCodable", package: "MetaCodable"),
        .product(name: "Processed", package: "Processed"),
        .product(name: "Gzip", package: "GzipSwift"),
      ],
      resources: [
        .process("Resources"),
      ],
      swiftSettings: swiftSettings,
      plugins: [
        .plugin(name: "RunScriptPlugin", package: "RunScriptPlugin"),
      ] + swiftUiPlugin
    ),
    .target(
      name: "BrewDesign",
      dependencies: [
        "BrewCore",
        "BrewShared",
        "Injected",

        .product(name: "Processed", package: "Processed"),
      ],
      resources: [
        .process("Resources"),
      ],
      swiftSettings: swiftSettings,
      plugins: [
//        .plugin(name: "ActoolBuildPlugin", package: "ActoolBuildPlugin"),
      ] + swiftUiPlugin
    ),
    .target(
      name: "BrewHelpers",
      dependencies: [
        "Injected",
      ],
      swiftSettings: swiftSettings,
      plugins: [
//        .plugin(name: "ActoolBuildPlugin", package: "ActoolBuildPlugin"),
      ] + swiftUiPlugin
    ),
    .target(
      name: "BrewShared",
      dependencies: [
        "Injected",

        .product(name: "SwiftMacros", package: "SwiftMacros"),
        .product(name: "Algorithms", package: "swift-algorithms"),
        .product(name: "MetaCodable", package: "MetaCodable"),
        .product(name: "SemVer", package: "semver"),
      ],
      swiftSettings: swiftSettings,
      plugins: [
      ] + swiftUiPlugin
    ),
    .target(
      name: "BrewHelperXPC",
      dependencies: [
        "BrewShared",

        "sXPC",
      ],
      swiftSettings: swiftSettings,
      plugins: [
      ] + swiftUiPlugin
    ),
    .testTarget(
      name: "BrewCoreTests",
      dependencies: [
        "BrewCore",
        "BrewShared",
        "Injected",

        .product(name: "PowerAssert", package: "swift-power-assert"),
      ],
      swiftSettings: swiftSettings,
      plugins: [
      ] + swiftUiPlugin
    ),
  ]
)
