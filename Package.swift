import PackageDescription

let package = Package(
    name: "FluentPostgreSQL",
    dependencies: [
        .Package(url: "https://github.com/vapor/postgresql.git", majorVersion: 0, minor: 3),
        .Package(url: "https://github.com/vapor/fluent.git", majorVersion: 0, minor: 11)
    ]
)
