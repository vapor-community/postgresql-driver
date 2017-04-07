import XCTest
@testable import FluentPostgreSQL
import FluentTester

class FluentPostgreSQLTests: XCTestCase {
    static let allTests = [
        ("testFluent", testFluent),
        ("testForeignKey", testForeignKey)
    ]

    func testFluent() throws {
        let driver = FluentPostgreSQL.Driver.makeTestConnection()
        let database = Database(driver)
        let tester = Tester(database: database)

        do {
            try tester.testAll()
        } catch {
            XCTFail("\(error)")
        }
    }

    func testForeignKey() throws {
        let driver = FluentPostgreSQL.Driver.makeTestConnection()
        let database = Database(driver)

        defer {
            try! database.delete(Atom.self)
            try! database.delete(Compound.self)
        }

        try database.create(Compound.self) { compounds in
            compounds.id(for: Compound.self)
            compounds.string("foo")
            compounds.index("foo")
        }

        try database.create(Atom.self) { atoms in
            atoms.id(for: Atom.self)
            atoms.string("name")
            atoms.index("name")
            atoms.foreignKey("name", references: "foo", on: Compound.self)
        }
    }
}
