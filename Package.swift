import PackageDescription

let package = Package(
    name: "KeyedCache",
    dependencies: [
        .Package(url: "https://github.com/Balancingrock/BRUtils", Version(0, 2, 0))
    ]
)
