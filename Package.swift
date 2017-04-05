import PackageDescription

let package = Package(
    name: "FluentPostgreSQL",
    dependencies: [
        // PostgreSQL interface for Swift.
        .Package(url: "https://github.com/vapor/postgresql.git", Version(2,0,0, prereleaseIdentifiers: ["beta"])),

        // Swift models, relationships, and querying for NoSQL and SQL databases.
        .Package(url: "https://github.com/vapor/fluent.git", Version(2,0,0, prereleaseIdentifiers: ["beta"]))
    ]
)
