// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Cycle",
    platforms: [
        .iOS(.v13),
        .watchOS(.v6),
        .macOS(.v10_15),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "Cycle",
            targets: ["Cycle"]),
        .library(
            name: "CycleTestSupport",
            targets: ["CycleTestSupport"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Cycle",
            dependencies: []),
        .testTarget(
            name: "CycleTests",
            dependencies: ["Cycle"]),
        .target(
            name: "CycleTestSupport",
            dependencies: ["Cycle"]),
    ]
)
