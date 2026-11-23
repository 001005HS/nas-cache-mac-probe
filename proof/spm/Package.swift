// swift-tools-version:5.9
import PackageDescription
let package = Package(
  name: "NasProof",
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.3.0"),
    .package(url: "https://github.com/apple/swift-log", exact: "1.6.1"),
    .package(url: "https://github.com/apple/swift-collections", exact: "1.1.4"),
  ],
  targets: [
    .target(name: "NasProof", dependencies: [
      .product(name: "ArgumentParser", package: "swift-argument-parser"),
      .product(name: "Logging", package: "swift-log"),
      .product(name: "Collections", package: "swift-collections"),
    ]),
  ]
)
