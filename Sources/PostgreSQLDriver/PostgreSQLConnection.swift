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
    public func query<E>(_ query: RawOr<Query<E>>) throws -> Node {
        switch query {
        case .raw(let raw, let values):
            return try postgresql(raw, values)
        case .some(let query):
            let serializer = PostgreSQLSerializer(query)
            let (statement, values) = serializer.serialize()
            let results = try postgresql(statement, values)

            if query.action == .create {
                return results.array?[0].object?[E.idKey] ?? Node.null
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
                values as [NodeRepresentable]
            )
        } catch let error as PostgreSQLError
            where
                error.code == .connectionException ||
                error.code == .connectionDoesNotExist ||
                error.code == .connectionFailure
        {
            throw QueryError.connectionClosed(error)
        }
    }
}
