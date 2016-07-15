import FluentPostgreSQL
import PostgreSQL
import Fluent

import XCTest

extension PostgreSQLDriver {
    static func makeTestConnection() -> PostgreSQLDriver {
        do {
            let postgresql = PostgreSQL.Database(
                host: "127.0.0.1",
                dbname: "test",
                user: "pugwuh",
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
            print("    user: 'travis'")
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

struct User: Model {
    var id: Fluent.Value?
    var name: String
    var email: String

    init(id: Fluent.Value?, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }

    func serialize() -> [String : Fluent.Value?] {
        return [
            "id": id,
            "name": name,
            "email" :email
        ]
    }

    init(serialized: [String : Fluent.Value]) {
        id = serialized["id"]
        name = serialized["name"]?.string ?? ""
        email = serialized["email"]?.string ?? ""
    }
}

