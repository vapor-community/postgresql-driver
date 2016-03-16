import Fluent

class User: Model {
    var id: String?
    var name: String
    
    init(name: String, email: String) {
        self.name = name
    }
    
    func serialize() -> [String: StatementValue] {
        return [
                   "name": self.name,
        ]
    }
    
    class var entity: String {
        return "users"
    }
    
    required init(deserialize: [String: StatementValue]) {
        self.id = deserialize["id"]?.asString ?? ""
        self.name = deserialize["name"]?.asString ?? ""
    }
    
}