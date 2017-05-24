import Fluent

class Photo: Entity, Preparation {
    public let storage = Storage()
    var title: String?
    var content: [UInt8]
    
    init(id: Identifier? = nil, title: String?, content: [UInt8]) {
        self.title = title
        self.content = content
        self.id = id
    }

    required init(row: Row) throws {
        title = try row.get("title")
        content = try row.get("content")
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set("title", title)
        try row.set("content", content)
        return row
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self) { photos in
            photos.id()
            photos.string("title", optional: true)
            photos.bytes("content")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
