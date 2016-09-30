import Fluent
import PostgreSQL

public class PostgreSQLDriver: Fluent.Driver {
    public var idKey: String = "id"
    public var database: PostgreSQL.Database

    /**
     Attempts to establish a connection to a PostgreSQL database engine.
     - host: May be either a host name or an IP address. Default is "localhost".
     - port: Port number for the TCP/IP connection. Default is 5432. Can't be 0.
     - dbname: Name of PostgreSQL database.
     - user: Login ID of the PostgreSQL user.
     - password: Password for user.
     - throws: `Error.cannotEstablishConnection` if the call to connection fails.
     */
    public init(
        host: String = "localhost",
        port: Int = 5432,
        dbname: String,
        user: String,
        password: String
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
    public func query<T: Entity>(_ query: Query<T>) throws -> Node {
        let serializer = PostgreSQLSerializer(sql: query.sql)
        let (statement, values) = serializer.serialize()
        return try raw(statement, values)
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
    public func raw(_ raw: String, _ values: [Node]) throws -> Node {
        let connection = try database.makeConnection()
        let result = try database.execute(raw, values, on: connection).map { Node.object($0) }
        return .array(result)
    }
}
