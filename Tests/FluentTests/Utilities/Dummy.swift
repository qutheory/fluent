import Fluent

final class DummyModel: Entity {
    var exists: Bool = false
    static var entity: String {
        return "dummy_models"
    }

    static func prepare(_ database: Database) throws {}
    static func revert(_ database: Database) throws {}

    var id: Node?
    
    static func fields(for database: Database) -> [String] {
        return []
    }

    init(node: Node, in context: Context) throws {

    }

    func makeNode(context: Context) -> Node {
        return .null
    }
}

class DummyDriver: Driver {
    var idKey: String {
        return "foo"
    }

    enum Error: Swift.Error {
        case broken
    }

    func query<T: Entity>(_ query: Query<T>) throws -> Node {
        return .array([])
    }

    func schema(_ schema: Schema) throws {

    }

    func raw(_ raw: String, _ values: [Node]) throws -> Node {
        return .null
    }
}
