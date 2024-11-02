// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "fsrs",
    platforms: [
        .macOS(.v12), .iOS(.v15),
    ],
    products: [
        .library(name: "FSRS", targets: ["FSRS"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "FSRS",
            dependencies: [
                .product(name: "Numerics", package: "swift-numerics"),
            ]
        ),
        .testTarget(
            name: "FSRSTests",
            dependencies: [
                "FSRS"
            ]
        ),
    ]
)
