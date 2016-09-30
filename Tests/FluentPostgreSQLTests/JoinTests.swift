import XCTest
@testable import FluentPostgreSQL
import Fluent

class JoinTests: XCTestCase {
    static let allTests = [
        ("testBasic", testBasic)
    ]

    var database: Fluent.Database!
    var driver: PostgreSQLDriver!

    override func setUp() {
        driver = PostgreSQLDriver.makeTestConnection()
        database = Database(driver)
    }

    func testBasic() throws {
        try Atom.revert(database)
        try Compound.revert(database)
        try Pivot<Atom, Compound>.revert(database)

        try Atom.prepare(database)
        try Compound.prepare(database)
        try Pivot<Atom, Compound>.prepare(database)

        Atom.database = database
        Compound.database = database
        Pivot<Atom, Compound>.database = database

        var hydrogen = Atom(name: "Hydrogen", protons: 1)
        try hydrogen.save()
        try hydrogen = Atom.find(1)!

        var water = Compound(name: "Water")
        try water.save()
        try water = Compound.find(1)!

        var hydrogenWater = Pivot<Atom, Compound>(hydrogen, water)
        try hydrogenWater.save()

        var sugar = Compound(name: "Sugar")
        try sugar.save()
        try sugar = Compound.find(2)!

        var hydrogenSugar = Pivot<Atom, Compound>(hydrogen, sugar)
        try hydrogenSugar.save()

        let compounds = try hydrogen.compounds().all()
        XCTAssertEqual(compounds.count, 2)
        XCTAssertEqual(compounds.first?.id?.int, water.id?.int)
        XCTAssertEqual(compounds.last?.id?.int, sugar.id?.int)
    }
}
