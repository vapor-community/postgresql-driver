import XCTest

import FluentPostgreSQL
import PostgreSQL
import Fluent

extension PostgreSQLDriver {
    static func makeTestConnection() -> PostgreSQLDriver {
        do {
            let postgresql = PostgreSQL.Database(
                host: "127.0.0.1",
                port: "5432",
                dbname: "test",
                user: "postgres",
                password: ""
            )
            let driver = PostgreSQLDriver(postgresql)
            try driver.raw("SELECT version()")
            return driver
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
            print("    host: '127.0.0.1'")
            print("    database: 'test'")
            print()
            print()

            XCTFail("Configure PostgreSQL")
            fatalError("Configure PostgreSQL")
        }
    }
}
