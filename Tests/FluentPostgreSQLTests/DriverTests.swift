import XCTest
@testable import FluentPostgreSQL
import Fluent

class DriverTests: XCTestCase {
    static let allTests = [
        ("testSaveAndFind", testSaveAndFind),
        ("testPresetID", testPresetID),
    ]

    var database: Fluent.Database!
    var driver: PostgreSQLDriver!

    override func setUp() {
        driver = PostgreSQLDriver.makeTestConnection()
        database = Database(driver)
    }

    func testSaveAndFind() throws {
        try driver.raw("DROP TABLE IF EXISTS users")
        try driver.raw("CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(16), email VARCHAR(100))")

        var user = User(id: nil, name: "Vapor", email: "vapor@qutheory.io")
        User.database = database

        do {
            try user.save()
            print("Save Successful")
        } catch {
            XCTFail("Could not save: \(error)")
        }

        do {
            let found = try User.find(1)
            XCTAssertEqual(found?.id!, 1)
            XCTAssertEqual(found?.name, user.name)
            XCTAssertEqual(found?.email, user.email)
        } catch {
            XCTFail("Could not find user: \(error)")
        }

        do {
            let user = try User.find(2)
            XCTAssertNil(user)
        } catch {
            XCTFail("User should not exist: \(error)")
        }
    }
    
    func testPresetID() throws {
        try driver.raw("DROP TABLE IF EXISTS users")
        try driver.raw("CREATE TABLE users (id INTEGER PRIMARY KEY, name VARCHAR(16), email VARCHAR(100))")
        
        var user = User(id: .number(.int(1)), name: "Vapor", email: "vapor@qutheory.io")
        User.database = database
        
        try user.save()
        
        let found = try User.find(1)
        XCTAssertEqual(found?.id!, 1)
        XCTAssertEqual(found?.name, user.name)
        XCTAssertEqual(found?.email, user.email)
    }
}
