import Fluent

final class DummyModel: Entity {
    let storage = Storage()
    static var entity: String {
        return "dummy_models"
    }

    static func prepare(_ database: Database) throws {}
    static func revert(_ database: Database) throws {}

    var id: Node?

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
    
    func makeConnection() throws -> Connection {
        return DummyConnection()
    }
}

class DummyConnection: Connection {
    public var closed: Bool = false

    func query<T: Entity>(_ query: Query<T>) throws -> Node {
        if query.action == .count {
            return 0
        }
        
        return .array([])
    }

    func schema(_ schema: Schema) throws {

    }

    func raw(_ raw: String, _ values: [Node]) throws -> Node {
        return .null
    }
}
