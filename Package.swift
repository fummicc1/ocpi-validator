// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "ocpi-validator",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .library(
      name: "OCPIValidator",
      targets: ["OCPIValidator"]
    ),
    .executable(
      name: "ocpi-validator",
      targets: ["OCPIValidatorCLI"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0")
  ],
  targets: [
    .target(
      name: "OCPIValidator",
      dependencies: []
    ),
    .executableTarget(
      name: "OCPIValidatorCLI",
      dependencies: [
        "OCPIValidator",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .testTarget(
      name: "OCPIValidatorTests",
      dependencies: ["OCPIValidator"]
    ),
  ]
)
