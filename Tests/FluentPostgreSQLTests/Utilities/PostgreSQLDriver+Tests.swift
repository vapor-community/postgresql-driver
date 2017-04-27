import FluentPostgreSQL
import PostgreSQL
import Fluent
import XCTest

extension FluentPostgreSQL.Driver {
    static func makeTestConnection() -> FluentPostgreSQL.Driver {
        do {
            let postgresql = try PostgreSQL.Database(
                hostname: "127.0.0.1",
                port: 5432,
                database: "test",
                user: "postgres",
                password: ""
            )
            return FluentPostgreSQL.Driver(master: postgresql)
        } catch {
            print()
            print()
            print("⚠️ PostgreSQL Not Configured ⚠️")
            print()
            print("Error: \(error)")
            print()
            print("You must configure PostgreSQL to run with the following configuration: ")
            print("    user: 'postgres'")
            print("    password: '' // (empty)")
            print("    hostname: '127.0.0.1'")
            print("    database: 'test'")
            print()

            print()

            XCTFail("Configure PostgreSQL")
            fatalError("Configure PostgreSQL")
        }
    }
}
