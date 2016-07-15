import Fluent
import PostgreSQL


public class PostgreSQLDriver: Fluent.Driver {
    public var idKey: String = "id"
    public var database: PostgreSQL.Database
    
    /**
     Attempts to establish a connection to a PostgreSQL database
     engine running on host.
     - parameter host: May be either a host name or an IP address.
     If host is the string "localhost", a connection to the local host is assumed.
     - parameter port: If port is not 0, the value is used as
     the port number for the TCP/IP connection. default 5432
     - parameter database: Database name.
     - parameter user: The user's PostgreSQL login ID.
     - parameter password: Password for user.
     - throws: `Error.cannotEstablishConnection` if the call to connection fails
     */
    public init(
        host: String = "localhost",
        port: UInt = 5432,
        user: String,
        password: String,
        dbname: String
        ) {
        
        self.database = PostgreSQL.Database(
            host: host,
            port: "\(port)",
            dbname: dbname,
            user: user,
            password: password
        )
    }
    
    /**
     Creates the driver from an already
     initialized database.
     */
    public init(_ database: PostgreSQL.Database) {
        self.database = database
    }
    
    /**
     Queries the database.
     */
    @discardableResult
    public func query<T: Model>(_ query: Query<T>) throws -> [[String: Fluent.Value]] {
        let serializer = PostgreSQLSerializer(sql: query.sql)
        let (statement, values) = serializer.serialize()
        let connection = try database.makeConnection()
        
        return try raw(statement, values, connection)
    }
    
    /**
     Creates the desired schema.
     */
    public func schema(_ schema: Schema) throws {
        let serializer = PostgreSQLSerializer(sql: schema.sql)
        let (statement, values) = serializer.serialize()
        
        try raw(statement, values)
    }
    
    /**
     Provides access to the underlying PostgreSQL database
     for running raw queries.
     */
    @discardableResult
    public func raw(_ query: String, _ values: [Fluent.Value] = [], _ connection: PostgreSQL.Connection? = nil) throws -> [[String: Fluent.Value]] {
        var results: [[String: Fluent.Value]] = []
        
        let values = values.map { $0.postgreSQL }
        
        for row in try database.execute(query, values, on: connection) {
            var result: [String: Fluent.Value] = [:]
            
            for (key, val) in row {
                result[key] = val
            }
            
            results.append(result)
        }
        
        return results
    }
}

extension Fluent.Value {
    public var postgreSQL: PostgreSQL.Value {
        switch structuredData {
        case .int(let int):
            return .int(int)
        case .double(let double):
            return .double(double)
        case .string(let string):
            return .string(string)
        default:
            return .null
        }
    }
}

extension PostgreSQL.Value: Fluent.Value {
    public var structuredData: StructuredData {
        switch self {
        case .string(let string):
            return .string(string)
        case .int(let int):
            return .int(int)
        case .double(let double):
            return .double(double)
        case .bool(let bool):
            return .bool(bool == 1 ? true : false)
        case .null:
            return .null
        }
    }
    
    public var description: String {
        switch self {
        case .string(let string):
            return string
        case int(let int):
            return "\(int)"
        case .double(let double):
            return "\(double)"
        case .bool(let bool):
            return bool == 1 ? "true" : "false"
        case .null:
            return "NULL"
        }
    }
}

