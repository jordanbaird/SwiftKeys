// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "SwiftKeys",
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
