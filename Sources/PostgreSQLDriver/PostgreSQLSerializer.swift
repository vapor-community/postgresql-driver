import Fluent

// PostgreSQL flavored SQL serializer.
public final class PostgreSQLSerializer<E: Entity>: GeneralSQLSerializer<E> {
    private var positionalIndex = 0

    public override func serialize() -> (String, [Node]) {
        positionalIndex = 0
        return super.serialize()
    }
    
    // MARK: Data
    
    public override func insert() -> (String, [Node]) {
        var statement: [String] = []
        
        statement += "INSERT INTO"
        statement += escape(E.entity)
        
        let bind: [Node]
        
        // Remove ID from the query data to avoid constraint violation error
        var data = query.data
        
        if case .some(.some(let id)) = data[.some(E.idKey)], id.isNull {
            data.removeValue(forKey: .some(E.idKey))
        }
        
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
    
    // MARK: Schema

    public override func drop() -> (String, [Node]) {
        var statement: [String] = []

        statement += "DROP TABLE IF EXISTS"
        statement += escape(E.entity)
        statement += "CASCADE" // added for PostgreSQL

        return (
            concatenate(statement),
            []
        )
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
                    typeString = "INT4"
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
            return "INT8"
        case .string(let length):
            if let length = length {
                return "VARCHAR(\(length))"
            } else {
                return "VARCHAR"
            }
        case .double:
            return "FLOAT8"
        case .bool:
            return "BOOLEAN"
        case .bytes:
            return "BYTEA"
        case .date:
            return "TIMESTAMP WITH TIME ZONE"
        case .custom(let type):
            return type
        }
    }
    
    // MARK: Query Types

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

    public override func filter(_ filter: Filter) -> (String, [Node]) {
        var statement: [String] = []
        var values: [Node] = []

        switch filter.method {
        case .compare(let key, let c, let value):
            // `.null` needs special handling in the case of `.equals` or `.notEquals`.
            if c == .equals && value == .null {
                statement += escape(filter.entity.entity) + "." + escape(key) + " IS NULL"
            }
            else if c == .notEquals && value == .null {
                statement += escape(filter.entity.entity) + "." + escape(key) + " IS NOT NULL"
            }
            else {
                // Augment pos
                self.positionalIndex += 1

                statement += escape(filter.entity.entity) + "." + escape(key)
                statement += comparison(c)
                // Use the positionalIndex instead of "?"
                statement += "$\(self.positionalIndex)"

                // `.like` comparison operator requires additional
                // processing of `value`
                switch c {
                case .hasPrefix:
                    values += hasPrefix(value)
                case .hasSuffix:
                    values += hasSuffix(value)
                case .contains:
                    values += contains(value)
                default:
                    values += value
                }
            }
        case .subset(let key, let s, let subValues):
            if subValues.count == 0 {
                switch s {
                case .in:
                    // where in empty set should
                    // not match any rows
                    statement += "false"
                case .notIn:
                    // where not in empty set should
                    // match all rows
                    statement += "true"
                }
            } else {
                statement += escape(filter.entity.entity) + "." + escape(key)
                statement += scope(s)
                statement += placeholders(subValues)
                values += subValues
            }
        case .group(let relation, let f):
            if f.count == 0 {
                // empty subqueries should result to false to protect
                // unfiltered data from being returned
                statement += "false"
            } else {
                let (clause, subvals) = filters(f, relation)
                statement += "(\(clause))"
                values += subvals
            }
        }

        return (
            concatenate(statement),
            values
        )
    }
    
    // MARK: - Convenience

    public override func placeholder(_ value: Node) -> String {
        positionalIndex += 1
        return "$\(positionalIndex)"
    }
    
    public override func escape(_ string: String) -> String {
        return "\"\(string)\""
    }
}
