import PackageDescription

let package = Package(
    name: "PostgreSQLDriver",
    dependencies: [
   		.Package(url: "https://github.com/Prince2k3/cpostgresql.git", majorVersion: 0),
      .Package(url: "https://github.com/tannernelson/fluent.git", majorVersion: 0)
    ]
)
