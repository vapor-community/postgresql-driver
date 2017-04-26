import Fluent

// PostgreSQL flavored SQL serializer.
public final class PostgreSQLSerializer<E: Entity>: GeneralSQLSerializer<E> {
    private var positionalIndex = 0

    public override func serialize() -> (String, [Node]) {
        positionalIndex = 0
        return super.serialize()
    }

    public override func type(_ type: Field.DataType, primaryKey: Bool) -> String {
        switch type {
        case .id(let type):
            let typeString: String
            switch type {
            case .int:
                if primaryKey {
                    typeString = "SERIAL PRIMARY KEY"
                } else {
                    typeString = "INT"
                }
            case .uuid:
                if primaryKey {
                    typeString = "UUID PRIMARY KEY"
                } else {
                    typeString = "UUID"
                }
            case .custom(let custom):
                typeString = custom
            }
            return typeString
        case .int:
            return "INT"
        case .string:
            return "TEXT"
        case .double:
            return "FLOAT"
        case .bool:
            return "BOOLEAN"
        case .bytes:
            return "BYTEA"
        case .date:
            return "TIMESTAMP"
        case .custom(let type):
            return type
        }
    }

    public override func deleteIndex(_ idx: RawOr<Index>) -> (String, [Node]) {
        var statement: [String] = []

        statement.append("ALTER TABLE")
        statement.append(escape(E.entity))
        statement.append("DROP INDEX")

        switch idx {
        case .raw(let raw, _):
            statement.append(raw)
        case .some(let idx):
            statement.append(escape(idx.name))
        }

        return (
            concatenate(statement),
            []
        )
    }

    public override func escape(_ string: String) -> String {
        return "\"\(string)\""
    }

    public override func insert() -> (String, [Node]) {
        var statement: [String] = []
        
        statement += "INSERT INTO"
        statement += escape(E.entity)
        
        let bind: [Node]
        
        // Remove ID from the query data to avoid constraint violation error
        var data = query.data
        data.removeValue(forKey: .some(E.idKey))
        
        if !data.isEmpty {
            statement += keys(data.keys.array)
            statement += "VALUES"
            let (fragment, nodes) = values(data.values.array)
            statement += fragment
            bind = nodes
        } else {
            bind = []
        }
        
        statement += "RETURNING"
        statement += E.idKey

        return (
            concatenate(statement),
            bind
        )
    }

    public override func limit(_ limit: RawOr<Limit>) -> String {
        var statement: [String] = []
        
        statement += "LIMIT"
        switch limit {
        case .raw(let raw, _):
            statement += raw
        case .some(let some):
            statement += "\(some.count) OFFSET \(some.offset)"
        }
        
        return statement.joined(separator: " ")
    }
    
    public override func placeholder(_ value: Node) -> String {
        return nextPlaceholder
    }
    
    private var nextPlaceholder: String {
        positionalIndex += 1
        return "$\(positionalIndex)"
    }
}
