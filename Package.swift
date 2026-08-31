// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "GameModeTray",
  platforms: [.macOS(.v15)],
  products: [
    .library(name: "GameModeCore", targets: ["GameModeCore"]),
    .executable(name: "GameModeTray", targets: ["GameModeTray"]),
  ],
  targets: [
    .target(name: "GameModeCore"),
    .executableTarget(
      name: "GameModeTray",
      dependencies: ["GameModeCore"]
    ),
    .testTarget(
      name: "GameModeCoreTests",
      dependencies: ["GameModeCore"]
    ),
  ]
)
