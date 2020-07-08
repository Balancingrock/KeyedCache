// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "KeyedCache",
    platforms: [.macOS(.v10_10), .iOS(.v8)]
    products: [.library(name: "KeyedCache", targets: ["KeyedCache"])],
    dependencies: [
        .package(url: "https://github.com/Balancingrock/BRUtils", from: "1.1.0")
    ],
    targets: [.target( name: "KeyedCache", dependencies: ["BRUtils"])],
    swiftLanguageVersions: [.v4, .v4_2, .v5]
)
