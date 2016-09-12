import Fluent

public final class PostgreSQLSerializer: GeneralSQLSerializer {
    var placeholderCount: Int = 0

    public override func sql(_ value: Node) -> String {
        self.placeholderCount += 1
        return "$\(self.placeholderCount)"
    }
    
    public override func serialize() -> (String, [Node]) {
        self.placeholderCount = 0
        return super.serialize()
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
        default:
            break
        }
        return super.sql(type)
    }
    
    public override func sql(_ data: Node?) -> (String, [Node])? {
        guard let node = data else {
            return nil
        }
        
        guard case .object(var dict) = node else {
            return nil
        }
        
        var clause: [String] = []
        
        if dict.keys.contains("id") {
            
            dict.removeValue(forKey: "id")
        }
        
        let values = Array(dict.values)
        
        clause += sql(keys: Array(dict.keys))
        clause += "VALUES"
        clause += sql(values)
        
        return (
            sql(clause),
            values
        )
    }
}


