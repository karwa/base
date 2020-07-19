// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Base",
  products: [
    .library(name: "Base", targets: ["Base"]),
  ],
  dependencies: [
    .package(url: "https://github.com/karwa/swift-url.git", from: "0.0.1"),
  ],
  targets: [
    .target(name: "Concurrency"),
    .testTarget(name: "ConcurrencyTests", dependencies: ["Concurrency"]),

    .target(name: "Base", dependencies: [
      "Concurrency",
//      .product(name: "Algorithms", package: "swift-url"),
      .product(name: "WebURL", package: "swift-url"),
    ]),
    .testTarget(name: "BaseTests", dependencies: ["Base"]),
  ]
)
