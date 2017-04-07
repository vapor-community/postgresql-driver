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
                    typeString = "INT(10) UNSIGNED"
                }
            case .uuid:
                if primaryKey {
                    typeString = "CHAR(36) PRIMARY KEY"
                } else {
                    typeString = "CHAR(36)"
                }
            case .custom(let custom):
                typeString = custom
            }
            return typeString
        case .int:
            return "INT(11)"
        case .string(let length):
            if let length = length {
                return "VARCHAR(\(length))"
            } else {
                return "VARCHAR(255)"
            }
        case .double:
            return "FLOAT"
        case .bool:
            return "TINYINT(1) UNSIGNED"
        case .bytes:
            return "BYTEA"
        case .date:
            return "DATETIME"
        case .custom(let type):
            return type
        }
    }
}
