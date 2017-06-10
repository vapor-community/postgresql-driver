import XCTest
@testable import PostgreSQLDriver
import FluentTester
import Random

class SubsetTests: XCTestCase {
    let database: Database = {
        let driver = PostgreSQLDriver.Driver.makeTest()
        return Database(driver)
    }()

    override func setUp() {
        try! Atom.prepare(database)

        let testAtoms = [
            Atom(id: nil, name: "A", protons: 1, weight: 1),
            Atom(id: nil, name: "B", protons: 2, weight: 1),
            Atom(id: nil, name: "C", protons: 3, weight: 1),
            Atom(id: nil, name: "D", protons: 4, weight: 1),
            Atom(id: nil, name: "E", protons: 5, weight: 1)
        ]
        
        let query = try! Atom.makeQuery(database)
        testAtoms.forEach {
            try! query.save($0)
        }
    }
    
    override func tearDown() {
        try? database.delete(Atom.self)
    }

    func testSubsetIn() throws {
        XCTAssertEqual(3, try Atom.makeQuery(database).filter(Filter.Method.subset("protons", .in, [1,3,5,7])).count())
        XCTAssertEqual(0, try Atom.makeQuery(database).filter(Filter.Method.subset("protons", .in, [7,8,9])).count())
    }
    
    func testSubsetNotIn() throws {
        XCTAssertEqual(2, try Atom.makeQuery(database).filter(Filter.Method.subset("protons", .notIn, [1,3,5,7])).count())
        XCTAssertEqual(5, try Atom.makeQuery(database).filter(Filter.Method.subset("protons", .notIn, [7,8,9])).count())
    }
    
    func testSubsetInEmpty() throws {
        XCTAssertEqual(0, try Atom.makeQuery(database).filter(Filter.Method.subset("protons", .in, [])).count())
    }
    
    func testSubsetNotInEmpty() throws {
        XCTAssertEqual(5, try Atom.makeQuery(database).filter(Filter.Method.subset("protons", .notIn, [])).count())
    }
    
    static let allTests = [
        ("testSubsetIn", testSubsetIn),
        ("testSubsetNotIn", testSubsetNotIn),
        ("testSubsetInEmpty", testSubsetInEmpty),
        ("testSubsetNotInEmpty", testSubsetNotInEmpty)
    ]
}
