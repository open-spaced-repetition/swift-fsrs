// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "fsrs",
    platforms: [
        .macOS(.v10_13), .iOS(.v14),
    ],
    products: [
        .library(name: "FSRS", targets: ["FSRS"]),
    ],
    targets: [
      .target(name: "FSRS"),
      .testTarget(
        name: "FSRSTests",
        dependencies: [ "FSRS" ]
      ),
    ]
)
