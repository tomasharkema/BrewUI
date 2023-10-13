// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
  .enableUpcomingFeature("ConciseMagicFile"),
  .enableUpcomingFeature("BareSlashRegexLiterals"),
  //    .enableUpcomingFeature("ExistentialAny"),
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
  name: "Inject",
  platforms: [.macOS(.v14)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to
    // other packages.
    .library(
      name: "Inject",
      targets: ["Inject"]
    ),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "Inject"
    ),
//        .testTarget(
//            name: "InjectTests",
//            dependencies: ["Inject"]),
  ]
)
