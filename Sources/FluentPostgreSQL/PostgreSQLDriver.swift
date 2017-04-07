import Fluent
import PostgreSQL
import Random

public final class Driver: Fluent.Driver {
    // The string value for the default identifier key.
    //
    // The `idKey` will be used when `Model.find(_:)` or other find by
    // identifier methods are used.
    //
    // This value is overriden by entities that implement the `Entity.idKey`
    // static property.
    public let idKey: String

    // The default type for values stored against the identifier key.
    //
    // The `idType` will be accessed by those Entity implementations
    // which do not themselves implement `Entity.idType`.
    public let idType: IdentifierType

    // The naming convetion to use for foreign id keys, table names, etc.
    // ex: snake_case vs. camelCase.
    public let keyNamingConvention: KeyNamingConvention

    // The master MySQL Database for read/write
    public let master: PostgreSQL.Database

    // The read replicas for read only
    public let readReplicas: [PostgreSQL.Database]

    // Stores query logger
    public var log: QueryLogCallback?

    // Attempts to establish a connection to a PostgreSQL database engine
    // running on host.
    //
    // - parameter masterHostname: May be either a host name or an IP address.
    //         Defaults to "localhost".
    // - parameter user: The PostgreSQL login ID.
    // - parameter password: Password for user.
    // - parameter database: Database name.
    //         The connection sets the default database to this value.
    // - parameter port: If port is not 0, the value is used as
    //         the port number for the TCP/IP connection.
    // - parameter socket: If socket is not NULL, the string specifies
    //         the socket or named pipe to use.
    // - parameter encoding: Usually "utf8".
    //
    // - throws: `Error.connection(String)` if the call to connection fails.
    //
    public convenience init(
        masterHostname: String = "localhost",
        readReplicaHostnames: [String],
        port: Int = 5432,
        database: String,
        user: String,
        password: String,
        encoding: String = "UTF8",
        idKey: String = "id",
        idType: IdentifierType = .int,
        keyNamingConvention: KeyNamingConvention = .snake_case
    ) throws {
        let master = try PostgreSQL.Database(
            hostname: masterHostname,
            port: port,
            database: database,
            user: user,
            password: password
        )
        let readReplicas: [PostgreSQL.Database] = try readReplicaHostnames.map { hostname in
            return try PostgreSQL.Database(
                hostname: hostname,
                port: port,
                database: database,
                user: user,
                password: password
            )
        }
        self.init(
            master: master,
            readReplicas: readReplicas,
            idKey: idKey,
            idType: idType,
            keyNamingConvention: keyNamingConvention
        )
    }

    // Creates the driver from an already initialized database.
    public init(
        master: PostgreSQL.Database,
        readReplicas: [PostgreSQL.Database] = [],
        idKey: String = "id",
        idType: IdentifierType = .int,
        keyNamingConvention: KeyNamingConvention = .snake_case
    ) {
        self.master = master
        self.readReplicas = readReplicas
        self.idKey = idKey
        self.idType = idType
        self.keyNamingConvention = keyNamingConvention
    }

    // Creates a connection for executing queries. This method is used to
    // automatically create a connection if any Executor methods are called on
    // the Driver.
    public func makeConnection(_ type: ConnectionType) throws -> Fluent.Connection {
        let database: PostgreSQL.Database
        switch type {
        case .read:
            database = readReplicas.random ?? master
        case .readWrite:
            database = master
        }
        let conn = try database.makeConnection()
        return Connection(conn)
    }
}

// extension Driver {
//     // Executes a PostgreSQL transaction on a single connection.
//     //
//     // The argument supplied to the closure is the connection to use for
//     // this transaction.
//     //
//     // It may be ignored if you are using Fluent and not performing
//     // complex threading.
//     public func transaction(_ closure: (PostgreSQL.Connection) throws -> ()) throws {
//         let conn = try master.makeConnection()
//         try conn.transaction {
//             let wrapped = PostgreSQLDriver.Connection(conn)
//             try closure(wrapped)
//         }
//     }
// }
