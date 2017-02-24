import XCTest
@testable import FluentPostgreSQL
import Fluent

class SchemaTests: XCTestCase {
    static let allTests = [
        ("testBasic", testBasic),
        ("testStringID", testStringID)
    ]

    var database: Fluent.Database!
    var driver: PostgreSQLDriver!

    override func setUp() {
        driver = PostgreSQLDriver.makeTestConnection()
        database = Database(driver)
    }

    final class SchemaTester: Entity {
        var exists: Bool = false
        static var entity = "schema_tests"

        var id: Node?
        var int: Int
        var stringDefault: String
        var string64: String
        var stringOptional: String?
        var double: Double
        var bool: Bool
        var data: [UInt8]

        init(
            int: Int,
            stringDefault: String,
            string64: String,
            stringOptional: String?,
            double: Double,
            bool: Bool,
            data: [UInt8]
        ) {
            self.int = int
            self.stringDefault = stringDefault
            self.string64 = string64
            self.stringOptional = stringOptional
            self.double = double
            self.bool = bool
            self.data = data
        }

        init(node: Node, in context: Context) throws {
            id = try node.extract("id")
            int = try node.extract("int")
            stringDefault = try node.extract("string_default")
            string64 = try node.extract("string_64")
            stringOptional = try node.extract("string_optional")
            double = try node.extract("double")
            bool = try node.extract("bool")
            
            guard let dataNode = node["data"], case .bytes(let dataBytes) = dataNode else {
                throw NodeError.unableToConvert(node: nil, expected: "Node.bytes")
            }
            data = dataBytes
        }

        func makeNode(context: Context) throws -> Node {
            return try Node(node: [
                "id": id,
                "int": int,
                "string_default": stringDefault,
                "string_64": string64,
                "string_optional": stringOptional,
                "double": double,
                "bool": bool,
                "data": Node(bytes: data),
            ])
        }

        static func prepare(_ database: Database) throws {
            try database.create(entity) { builder in
                builder.id()
                builder.int("int")
                builder.string("string_default")
                builder.string("string_64", length: 64)
                builder.string("string_optional", optional: true)
                builder.double("double")
                builder.bool("bool")
                builder.data("data")
            }
        }
        static func revert(_ database: Database) throws {
            try database.delete(entity)
        }
    }

    func testBasic() throws {
        SchemaTester.database = database

        do {
            try SchemaTester.revert(database)
        } catch {
            XCTFail("Could not revert database: \(error)")
        }

        do {
            try SchemaTester.prepare(database)
        } catch {
            XCTFail("Could not prepare database: \(error)")
        }

        var test = SchemaTester(
            int: 42,
            stringDefault: "this is a default",
            string64: "< 64 bytes",
            stringOptional: nil,
            double: 3.14,
            bool: false,
            data: [0x04, 0x02, 0xFF]
        )

        do {
            try test.save()
        } catch {
            XCTFail("Could not save: \(error)")
        }
        
        let test2 = try SchemaTester.query().filter("string_optional", Node.null).first()
        XCTAssertNotNil(test2)
        XCTAssertEqual(test.id, test2!.id)
    }
    
    // given for now the 'id' DataType is interpreted as an int by the PostgreSQL driver,
    // creating a String typed id requires using the custom datat type.
    final class StringIDTester: Entity {
        var exists: Bool = false
        static var entity = "string_id_tests"
        
        var id: Node?
        
        init(id: String) {
            self.id = Node(id)
        }
        
        init(node: Node, in context: Context) throws {
            id = try node.extract("id")
        }
        
        func makeNode(context: Context) throws -> Node {
            return try Node(node: [ "id": id ])
        }
        
        static func prepare(_ database: Database) throws {
            try database.create(entity) { builder in
                builder.custom("id", type: "char(36) primary key")
            }
        }
        static func revert(_ database: Database) throws {
            try database.delete(entity)
        }
    }
    
    func testStringID() throws {
        StringIDTester.database = database
        
        do {
            try StringIDTester.revert(database)
        } catch {
            XCTFail("Could not revert database: \(error)")
        }
        
        do {
            try StringIDTester.prepare(database)
        } catch {
            XCTFail("Could not prepare database: \(error)")
        }
        
        do {
            var test = StringIDTester(id: "derp")
            try test.save()
            XCTAssertNotNil(try StringIDTester.find("derp"))
        }
        catch {
            XCTFail("Could not save to database: \(error)")
        }
        
        do {
            let createdObject = try StringIDTester
                                    .query()
                                    .create(Node(["id": "123456789012345678901234567890123456"]))
            
            print(createdObject)
            
            XCTAssertEqual(createdObject.string, "123456789012345678901234567890123456")

        } catch {
            XCTFail("Could not save: \(error)")
        }
    }
}
