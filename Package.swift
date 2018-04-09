// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "KeyedCache",
    products: [
        .library(name: "KeyedCache", targets: ["KeyedCache"])
    ],
    dependencies: [
        .package(url: "https://github.com/Balancingrock/BRUtils", from: "0.12.0")
    ],
    targets: [
        .target(
            name: "KeyedCache",
            dependencies: ["BRUtils"]
        )
    ]
)
