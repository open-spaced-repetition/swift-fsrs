// swift-tools-version: 5.10.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FSRS",
    platforms: [
        .macOS(.v10_13), .iOS(.v14),
    ],
    products: [
        .library(
            name: "FSRS",
            targets: ["FSRS"]),
    ],
    targets: [
        .target(
            name: "FSRS",
            path: "Sources/FSRS/"
        ),
        .testTarget(
            name: "FSRSTests",
            dependencies: ["FSRS"],
            path: "./Tests/FSRSTests"
        ),
    ]
)
