import PackageDescription

let package = Package(
    name: "KeyedCache",
    dependencies: [
        .Package(url: "../BRUtils", Version(0, 3, 0))
    ]
)
