import PackageDescription

let package = Package(
    name: "PostgreSQLDriver",
    dependencies: [
        // PostgreSQL interface for Swift.
        .Package(url: "https://github.com/vapor-community/postgresql.git", Version(2,0,0, prereleaseIdentifiers: ["beta"])),

        // Swift models, relationships, and querying for NoSQL and SQL databases.
        .Package(url: "https://github.com/vapor/fluent.git", majorVersion: 2),

        // Random number generation
        .Package(url: "https://github.com/vapor/random.git", majorVersion: 1)
    ]
)
