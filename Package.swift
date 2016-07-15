import PackageDescription

let package = Package(
    name: "FluentPostgreSQL",
    dependencies: [
        .Package(url: "https://github.com/qutheory/postgresql.git", majorVersion: 0, minor: 1),
        .Package(url: "https://github.com/qutheory/fluent.git", majorVersion: 0, minor: 7)
    ]
)
