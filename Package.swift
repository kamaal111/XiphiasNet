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
    dependencies: [
        .package(url: "https://github.com/Quick/Quick.git", "4.0.0"..<"5.0.0"),
        .package(url: "https://github.com/Quick/Nimble.git", "9.0.0"..<"10.0.0"),
    ],
    targets: [
        .target(
            name: "XiphiasNet",
            dependencies: []),
        .testTarget(
            name: "XiphiasNetTests",
            dependencies: [
                "XiphiasNet",
                "Quick",
                "Nimble",
            ]),
    ]
)
