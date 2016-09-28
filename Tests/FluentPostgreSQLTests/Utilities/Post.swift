import Fluent

final class Post: Entity {
    /**
     Turn the convertible into a node

     - throws: if convertible can not create a Node
     - returns: a node if possible
     */

    var id: Fluent.Node?
    var title: String
    var text: String
    var exists: Bool = false

    init(id: Node?, title: String, text: String) {
        self.id = id
        self.title = title
        self.text = text
    }

    func makeNode(context:Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "title": title,
            "text": text
            ])
    }

    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        title = try node.extract("title")
        text = try node.extract("text")
    }

    static func prepare(_ database: Fluent.Database) throws {
        try database.create(entity) { builder in
            builder.id()
            builder.string("title")
            builder.string("text")
        }
    }
    static func revert(_ database: Fluent.Database) throws {
        try database.delete(entity)
    }
}
