// swift-tools-version: 5.5

import PackageDescription

let package = Package(
    name: "SwiftKeys",
    products: [
        .library(
            name: "SwiftKeys",
            targets: ["SwiftKeys"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-docc-plugin",
            from: "1.0.0"
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
