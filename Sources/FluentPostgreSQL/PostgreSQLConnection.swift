import Fluent
import PostgreSQL

public final class Connection: Fluent.Connection {
    public let postgresqlConnection: PostgreSQL.Connection
    public var queryLogger: QueryLogger?
    public var isClosed: Bool {
        return !postgresqlConnection.isConnected
    }

    public init(_ conn: PostgreSQL.Connection) {
        postgresqlConnection = conn
    }

    // Executes a `Query` from and returns an array of results fetched,
    // created, or updated by the action.
    //
    // Drivers that support raw querying accept string queries and
    // parameterized values.
    //
    // This allows Fluent extensions to be written that can support custom
    // querying behavior.
    @discardableResult
    public func query<E: Entity>(_ query: RawOr<Query<E>>) throws -> Node {
        switch query {
        case .raw(let raw, let values):
            return try postgresql(raw, values)
        case .some(let query):
            let serializer = PostgreSQLSerializer(query)
            let (statement, values) = serializer.serialize()
            let results = try postgresql(statement, values)

            if query.action == .create {
                let insert = try postgresql("SELECT LAST_INSERT_ID() as id", [])
                if
                    case .array(let array) = insert.wrapped,
                    let first = array.first,
                    case .object(let obj) = first,
                    let id = obj["id"]
                {
                    return Node(id, in: insert.context)
                }
            }

            return results
        }
    }

    @discardableResult
    private func postgresql(_ query: String, _ values: [Node] = []) throws -> Node {
        queryLogger?.log(query, values)
        do {
            return try postgresqlConnection.execute(
                query,
                values
            )
        } catch let error as PostgreSQLError
            where
                error.code == .connection_exception ||
                error.code == .connection_does_not_exist ||
                error.code == .connection_failure
        {
            throw QueryError.connectionClosed(error)
        }
    }
}
