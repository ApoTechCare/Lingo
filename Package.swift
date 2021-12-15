// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Lingo",
    products: [
        .library(name: "Lingo", targets: ["Lingo"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
    targets: [
        .target(name: "Lingo", dependencies: [
            .product(name: "Logging", package: "swift-log")
        ]),
        .testTarget(name: "LingoTests", dependencies: ["Lingo"])
    ]
)
