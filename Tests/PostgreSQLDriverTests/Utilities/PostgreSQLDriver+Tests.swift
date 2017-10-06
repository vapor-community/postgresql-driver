import PostgreSQLDriver
import PostgreSQL
import Fluent
import XCTest

extension PostgreSQLDriver.Driver {
    static func makeTest() -> PostgreSQLDriver.Driver {
        do {
            let postgresql = try PostgreSQL.Database(
                hostname: "127.0.0.1",
                port: 5432,
                database: "postgres",
                user: "postgres",
                password: ""
            )
            return PostgreSQLDriver.Driver(master: postgresql)
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
