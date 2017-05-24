import XCTest
@testable import PostgreSQLDriver
import FluentTester

class FluentPostgreSQLTests: XCTestCase {
    func testAll() throws {
        let driver = PostgreSQLDriver.Driver.makeTest()
        let database = Database(driver)
        let tester = Tester(database: database)

        do {
            try tester.testAll()
        } catch {
            XCTFail("\(error)")
        }
    }

    func testForeignKey() throws {
        let driver = PostgreSQLDriver.Driver.makeTest()
        let database = Database(driver)

        defer {
            try! database.delete(Atom.self)
            try! database.delete(Compound.self)
        }

        try database.create(Compound.self) { compounds in
            compounds.id()
            compounds.string("foo", unique: true)
        }
        try database.index("foo", for: Compound.self)

        try database.create(Atom.self) { atoms in
            atoms.id()
            atoms.string("name")
            atoms.foreignKey("name", references: "foo", on: Compound.self)
        }
        try database.index("name", for: Atom.self)
    }
    
    func testInsertWithId() throws {
        let driver = PostgreSQLDriver.Driver.makeTest()
        let database = Database(driver)
        
        defer {
            try! database.delete(Atom.self)
        }
        
        let id = UUID()
        try Atom.prepare(database)
        let atom = Atom(id: Identifier(id.uuidString), name: "Test", protons: 3, weight: 1.5)
        try atom.save()
        
        XCTAssertNotNil(try Atom.makeQuery().find(id))
    }

    static let allTests = [
        ("testAll", testAll),
        ("testForeignKey", testForeignKey),
        ("testInsertWithId", testInsertWithId)
    ]
}
