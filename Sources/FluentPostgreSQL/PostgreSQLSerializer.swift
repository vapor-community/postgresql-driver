import Fluent

public final class PostgreSQLSerializer: GeneralSQLSerializer {
    var placeholderCount: Int = 0

    public override func sql(_ value: Value) -> String {
        self.placeholderCount += 1
        return "$\(self.placeholderCount)"
    }
    
    public override func serialize() -> (String, [Value]) {
        self.placeholderCount = 0
        return super.serialize()
    }
    
    public override func sql(_ string: String) -> String {
        return "\(string)"
    }
    
    public override func sql(_ column: SQL.Column) -> String {
        switch column {
        case .primaryKey:
            return sql("id") + " SERIAL PRIMARY KEY"
        case .integer(let name):
            return sql(name) + " INT"
        case .string(let name, let length):
            if let length = length {
                return sql(name) + " VARCHAR(\(length))"
            } else {
                return sql(name) + " VARCHAR(255)"
            }
        case .double(let name, _, _):
            return sql(name) + " FLOAT"
        }
    }
    
    public override func sql(_ data: [String: Value]) -> (String, [Value]) {
        var clause: [String] = []
        
        var d = data
        if d.keys.contains("id") {
            d.removeValue(forKey: "id")
        }
        
        let values = Array(d.values)
        
        clause += sql(keys: Array(d.keys))
        clause += "VALUES"
        clause += sql(values)
        
        return (
            sql(clause),
            values
        )
    }

}
