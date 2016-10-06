import Fluent

public final class PostgreSQLSerializer: GeneralSQLSerializer {
    var positionalParameter: Int = 0

    public override func serialize() -> (String, [Node]) {
        self.positionalParameter = 0
        return super.serialize()
    }

    public override func sql(_ value: Node) -> String {
        self.positionalParameter += 1
        return "$\(self.positionalParameter)"
    }

    public override func sql(_ string: String) -> String {
        return "\(string)"
    }

    public override func sql(_ type: Schema.Field.DataType) -> String {
        switch type {
        case .id:
            return "SERIAL PRIMARY KEY"
        case .string(let length):
            if let length = length {
                return "VARCHAR(\(length))"
            } else {
                return "VARCHAR(255)"
            }
        case .double:
            return "FLOAT"
        case .data:
            return "BYTEA"
        case .timestamp:
            return "TIMESTAMP"
        default:
            break
        }
        return super.sql(type)
    }

    public override func sql(_ filter: Filter) -> (String, [Node]) {
        var statement: [String] = []
        var values: [Node] = []

        switch filter.method {
        case .compare(let key, let comparison, let value):
            self.positionalParameter += 1

            statement += "\(sql(filter.entity.entity)).\(sql(key))"
            statement += sql(comparison)
            // Use the positionalParameter instead of "?"
            statement += "$\(self.positionalParameter)"

            /**
                `.like` comparison operator requires additional
                processing of `value`
            */
            switch comparison {
            case .hasPrefix:
                values += sql(hasPrefix: value)
            case .hasSuffix:
                values += sql(hasSuffix: value)
            case .contains:
                values += sql(contains: value)
            default:
                values += value
            }
        case .subset(let key, let scope, let subValues):
            statement += "\(sql(filter.entity.entity)).\(sql(key))"
            statement += sql(scope)
            statement += sql(subValues)
            values += subValues
        case .group(let relation, let filters):
            let (clause, subvals) = sql(filters, relation: relation)
            statement += "(\(clause))"
            values += subvals
        }

        return (
            sql(statement),
            values
        )
    }

    public override func sql(_ data: Node?) -> (String, [Node])? {
        guard let node = data else {
            return nil
        }

        guard case .object(var dict) = node else {
            return nil
        }

        var clause: [String] = []

        // Differs from Fluent implementation
        // Removes idKey value
        // The idKey needs to be blank when inserting a record
        if (dict["id"]?.isNull)! {
            dict.removeValue(forKey: "id")
        }

        let keys = Array(dict.keys)
        let values = Array(dict.values)

        clause += sql(keys: keys)
        clause += "VALUES"
        clause += sql(values)

        return (
            sql(clause),
            values
        )
    }

    public override func sql(limit: Limit) -> String {
        var statement: [String] = []

        statement += "LIMIT"
        statement += "\(limit.count)"
        statement += "OFFSET"
        statement += "\(limit.offset)"

        return statement.joined(separator: " ")
    }
}
