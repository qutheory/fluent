import XCTest
@testable import Fluent

class ModelFindTests: XCTestCase {

    /// Dummy Model implementation for testing.
    final class DummyModel: Entity {
        static var entity: String {
            return "dummy_models"
        }

        var id: Node?

        func makeNode() -> Node {
            return .null
        }

        init(node: Node, in context: Context) throws {

        }
        
        static func prepare(_ database: Database) throws {}
        static func revert(_ database: Database) throws {}
    }

    /// Dummy Driver implementation for testing.
    class DummyDriver: Driver {
        var idKey: String {
            return "foo"
        }

        enum Error: Swift.Error {
            case broken
        }

        func query<T: Entity>(_ query: Query<T>) throws -> Node {
            if
                let filter = query.filters.first,
                case .compare(let key, let comparison, let value) = filter.method,
                query.action == .fetch &&
                    query.filters.count == 1 &&
                    key == idKey &&
                    comparison == .equals
            {
                if value.int == 42 {
                    return .array([
                        .object([idKey: 42])
                    ])
                } else if value.int == 500 {
                    throw Error.broken
                }
            }
            
            return .array([])
        }

        func schema(_ builder: Schema) throws {
            //
        }

        func raw(_ raw: String, _ values: [Node]) throws -> Node {
            return .null
        }
    }

    static let allTests = [
        ("testFindFailing", testFindFailing),
        ("testFindSucceeding", testFindSucceeding),
        ("testFindErroring", testFindErroring),
    ]

    override func setUp() {
        database = Database(DummyDriver())
        Database.default = database
    }

    var database: Database!

    func testFindFailing() {
        do {
            let result = try DummyModel.find(404)
            XCTAssert(result == nil, "Result should be nil")
        } catch {
            XCTFail("Find should not have failed")
        }
    }

    func testFindSucceeding() {
        do {
            let result = try DummyModel.find(42)
            XCTAssert(result?.id?.int == 42, "Result should have matching id")
        } catch {
            XCTFail("Find should not have failed")
        }
    }

    func testFindErroring() {
        do {
            let _ = try DummyModel.find(500)
            XCTFail("Should have thrown error")
        } catch DummyDriver.Error.broken {
            //
        } catch {
            XCTFail("Error should have been caught")
        }
    }
}
