// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "SwiftKeys",
    platforms: [
        .macOS(.v10_13),
    ],
    products: [
        .library(
            name: "SwiftKeys",
            targets: ["SwiftKeys"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftKeys",
            dependencies: []
        ),
        .testTarget(
            name: "SwiftKeysTests",
            dependencies: ["SwiftKeys"]
        ),
    ]
)
