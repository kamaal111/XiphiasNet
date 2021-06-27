// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XiphiasNet",
    platforms: [.iOS(.v9), .macOS(.v10_10), .tvOS(.v9), .watchOS(.v2)],
    products: [
        .library(
            name: "XiphiasNet",
            targets: ["XiphiasNet"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "XiphiasNet",
            dependencies: []),
        .testTarget(
            name: "XiphiasNetTests",
            dependencies: ["XiphiasNet"]),
    ]
)
