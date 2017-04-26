import Fluent

// PostgreSQL flavored SQL serializer.
public final class PostgreSQLSerializer<E: Entity>: GeneralSQLSerializer<E> {
    public override func type(_ type: Field.DataType, primaryKey: Bool) -> String {
        switch type {
        case .id(let type):
            let typeString: String
            switch type {
            case .int:
                if primaryKey {
                    typeString = "SERIAL PRIMARY KEY"
                } else {
                    typeString = "INT UNSIGNED"
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
        case .string(let length):
            if let length = length {
                return "VARCHAR(\(length))"
            } else {
                return "VARCHAR(255)"
            }
        case .double:
            return "FLOAT"
        case .bool:
            return "TINYINT UNSIGNED"
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

    public override func values(_ values: [RawOr<Node>]) -> (String, [Node]) {
        var v: [Node] = []
        
        let parsed: [String] = values.enumerated().map { index, value in
            switch value {
            case .raw(let string, _):
                return string
            case .some(let some):
                v.append(some)
                return "$\(index + 1)"
            }
        }
        
        let string = parsed.joined(separator: ", ")
        return (
            "(" + string + ")",
            v
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
}
