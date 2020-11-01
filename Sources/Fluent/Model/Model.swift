/// Represents a single table / collection in a Fluent database. Models
/// are the basis for querying databases (create, read, update, and delete).
///
/// Models can also conform to `Migration` to provide prepare and revert methods for performing actions
/// on the database before the application boots.
///
/// Both `struct`s and `class`es can be models. Since Fluent is closure-based,
/// copied `struct`s will be returned by any methods that must mutate the model.
///
/// Here is an example of a simple `User` model.
///
///     final class User: Model {
///         typealias Database = PostgreSQLDatabase
///         static let idKey: WritableKeyPath<User, UUID?> = \.id
///         var id: UUID?
///         var name: String
///
///         init(id: UUID? = nil, name: String) {
///             self.id = id
///             self.name = name
///         }
///     }
///
/// Most of the time, you should use the Fluent driver's sub-protocols for conforming to `Model` instead of
/// using the protocol directly.
///
/// ## Query
///
/// To create a `QueryBuilder` for a model, use the `query(on:)` method.
///
///     let users = try User.query(on: req).filter(\.name == "Vapor").all()
///
/// You can also create `QueryBuilder`s for any `Decodable` type. However, `QueryBuilder`s created for `Model`s
/// have some extra methods and functionality.
///
/// ## Lifecycle
///
/// Models can implement optional lifecycle methods to hook into Fluent actions.
///
///     final class User: Model {
///         ...
///         func willDelete(on conn: PostgreSQLConnection) throws -> Future<User> {
///             print("Deleting user: \(id)")
///             return conn.future(self)
///         }
///     }
///
/// ## Timestamps
///
/// Models are capable of storing timestamps representing when this model was first created and when it was last updated.
/// If you decide to store timestamps on your model, Fluent will automatically update them whenever changes to the database are made.
///
///     final class User: Model {
///         static let createdAtKey: TimestampKey? = \User.createdAt
///         static let updatedAtKey: TimestampKey? = \User.updatedAt
///         ...
///         var createdAt: Date?
///         var updatedAt: Date?
///     }
///
/// Add timestamp keys pointing to the properties on your model to let Fluent automatically update the values.
/// You can set key paths for one or both of the keys per model.
///
/// ## Soft Delete
///
/// Instead of actually deleting rows from the database, soft deleted models can have a "deleted at" property set.
///
///
///     final class User: Model {
///         ...
///         var deletedAt: Date?
///     }
///
///     extension User: SoftDeletable {
///         static let deletedAtKey: TimestampKey? = \.deletedAt
///     }
///
/// You can add `SoftDeletable` to existing models that have an optional `Date` property for storing the
/// deleted at date.
///
/// - note: The deleted at date may be set in the future. The model will continue to be included in
///         queries until the deleted at date passes.
///
/// Use `softDelete(on:)` to soft-delete a `SoftDeletable` model from the database.
/// Use `restore(on:)` to restore a soft-deleted model.
///
///     let user: User
///     try user.softDelete(on: conn)
///     // later ...
///     try user.restore(on: conn)
///
/// Use `excludeSoftDeleted()` on `QueryBuilder` to exclude soft-deleted results (included by default).
///
///     User.query(on: conn).excludeSoftDeleted().count()
///
/// `SoftDeletable` models have extra lifecycle events:
///
///     - `willRestore`.
///     - `didRestore`.
///     - `willSoftDelete`.
///     - `didSoftDelete`.
///
/// See `Model` to learn more about Fluent lifecycle hooks.
public protocol Model: AnyModel, Reflectable {
    // MARK: DB

    /// The type of database this model can be queried on.
    associatedtype Database: QuerySupporting

    // MARK: ID

    /// The associated Identifier type. Usually `Int` or `UUID`. Must conform to `ID`.
    associatedtype ID: Fluent.ID

    /// Typealias for Swift `KeyPath` to an optional ID for this model.
    typealias IDKey = WritableKeyPath<Self, ID?>

    /// Swift `KeyPath` to this `Model`'s identifier.
    static var idKey: IDKey { get }
    
    // MARK: Timestamps
    
    /// Timestamp key.
    typealias TimestampKey = WritableKeyPath<Self, Date?>
    
    /// The date at which this model was created. `nil` if the model has not been created yet.
    /// By default, Fluent will assume your model does not have a created at key.
    static var createdAtKey: TimestampKey? { get }
    
    /// The date at which this model was last updated. `nil` if the model has not been created yet.
    /// By default, Fluent will assume your model does not have an updated at key.
    static var updatedAtKey: TimestampKey? { get }
    
    /// The date at which this model was or will be soft deleted. `nil` if the model has not been deleted yet.
    /// If this property is set, the model will not be included in any query results unless
    /// `withSoftDeleted()` is used on the `QueryBuilder`.
    static var deletedAtKey: TimestampKey? { get }

    // MARK: Lifecycle

    /// Called before a model is created when saving.
    /// - note: Throwing will cancel the save.
    /// - parameters:
    ///     - conn: Current database connection.
    func willCreate(on conn: Database.Connection)  throws -> Future<Self>
    /// Called after the model is created when saving.
    /// - parameters:
    ///     - conn: Current database connection.
    func didCreate(on conn: Database.Connection) throws -> Future<Self>

    /// Called before a model is fetched.
    /// - note: Throwing will cancel the fetch.
    /// - parameters:
    ///     - conn: Current database connection.
    func willRead(on conn: Database.Connection)  throws -> Future<Self>

    /// Called before a model is updated when saving.
    /// - note: Throwing will cancel the save.
    /// - parameters:
    ///     - conn: Current database connection.
    func willUpdate(on conn: Database.Connection) throws -> Future<Self>
    /// Called after the model is updated when saving.
    /// - parameters:
    ///     - conn: Current database connection.
    func didUpdate(on conn: Database.Connection) throws -> Future<Self>

    /// Called before a model is deleted.
    /// - note: Throwing will cancel the delete.
    /// - parameters:
    ///     - conn: Current database connection.
    func willDelete(on conn: Database.Connection) throws -> Future<Self>
    /// Called after the model is deleted.
    /// - parameters:
    ///     - conn: Current database connection.
    func didDelete(on conn: Database.Connection) throws -> Future<Self>
    
    /// Called before a model is restored (from being soft deleted).
    /// - note: Throwing will cancel the restore.
    /// - parameters:
    ///     - conn: Current database connection.
    func willRestore(on conn: Database.Connection) throws -> Future<Self>
    /// Called after the model is restored (from being soft deleted.
    /// - parameters:
    ///     - conn: Current database connection.
    func didRestore(on conn: Database.Connection) throws -> Future<Self>
    
    /// Called before a model is soft deleted.
    /// - note: Throwing will cancel the soft delete.
    /// - parameters:
    ///     - conn: Current database connection.
    func willSoftDelete(on conn: Database.Connection) throws -> Future<Self>
    /// Called after the model is soft deleted.
    /// - parameters:
    ///     - conn: Current database connection.
    func didSoftDelete(on conn: Database.Connection) throws -> Future<Self>
}

// MARK: Optional

extension Model {
    /// See `Model`.
    public func willCreate(on conn: Database.Connection) throws -> Future<Self> {
        return conn.future(self)
    }

    /// See `Model`.
    public func didCreate(on conn: Database.Connection) throws -> Future<Self> {
        return conn.future(self)
    }

    /// See `Model`.
    public func willUpdate(on conn: Database.Connection) throws -> Future<Self> {
        return conn.future(self)
    }
    /// See `Model`.
    public func didUpdate(on conn: Database.Connection) throws -> Future<Self> {
        return conn.future(self)
    }

    /// See `Model`.
    public func willRead(on conn: Database.Connection) throws -> Future<Self> {
        return conn.future(self)
    }

    /// See `Model`.
    public func willDelete(on conn: Database.Connection) throws -> Future<Self> {
        return conn.future(self)
    }
    /// See `Model`.
    public func didDelete(on conn: Database.Connection) throws -> Future<Self> {
        return conn.future(self)
    }
    
    /// See `Model`.
    public func willRestore(on conn: Database.Connection) throws -> Future<Self> {
        return conn.future(self)
    }
    /// See `Model`.
    public func didRestore(on conn: Database.Connection) throws -> Future<Self> {
        return conn.future(self)
    }
    /// See `Model`.
    public func willSoftDelete(on conn: Database.Connection) throws -> Future<Self> {
        return conn.future(self)
    }
    /// See `Model`.
    public func didSoftDelete(on conn: Database.Connection) throws -> Future<Self> {
        return conn.future(self)
    }
    
    /// See `Model`.
    public static var createdAtKey: TimestampKey? {
        return nil
    }
    
    /// See `Model`.
    public static var updatedAtKey: TimestampKey? {
        return nil
    }
    
    /// See `Model`.
    public static var deletedAtKey: TimestampKey? {
        return nil
    }
}

/// MARK: Key Access

extension Model {
    /// Returns the model's ID, throwing an error if the model does not yet have an ID.
    public func requireID() throws -> ID {
        guard let id = self.fluentID else {
            throw FluentError(identifier: "idRequired", reason: "\(Self.self) does not have an identifier.")
        }

        return id
    }

    /// Access the Fluent identifier keyed by `idKey`.
    public var fluentID: ID? {
        get {
            let path = Self.idKey
            return self[keyPath: path]
        }
        set {
            let path = Self.idKey
            self[keyPath: path] = newValue
        }
    }
    
    /// Access the Fluent timestamp keyed by `createdAtKey`.
    public var fluentCreatedAt: Date? {
        get {
            guard let createdAt = Self.createdAtKey else {
                return nil
            }
            return self[keyPath: createdAt]
        }
        set {
            guard let createdAt = Self.createdAtKey else {
                return
            }
            self[keyPath: createdAt] = newValue
        }
    }
    
    /// Access the Fluent timestamp keyed by `updatedAtKey`.
    public var fluentUpdatedAt: Date? {
        get {
            guard let updatedAt = Self.updatedAtKey else {
                return nil
            }
            return self[keyPath: updatedAt]
        }
        set {
            guard let updatedAt = Self.updatedAtKey else {
                return
            }
            self[keyPath: updatedAt] = newValue
        }
    }
    
    /// Access the Fluent timestamp keyed by `deletedAtKey`.
    public var fluentDeletedAt: Date? {
        get {
            guard let deletedAt = Self.deletedAtKey else {
                return nil
            }
            return self[keyPath: deletedAt]
        }
        set {
            guard let deletedAt = Self.deletedAtKey else {
                return
            }
            self[keyPath: deletedAt] = newValue
        }
    }
}

// MARK: Query

extension Model where Database: QuerySupporting {
    /// Creates a query for this model type on the supplied connection.
    ///
    ///     let users = try User.query(on: req).filter(\.name == "Vapor").all()
    ///
    /// - parameters:
    ///     - conn: Something `DatabaseConnectable` to create the `QueryBuilder` on.
    ///     - database: Database identifier for the database this should run on. If `nil`, the model's default database is used.
    ///     - withSoftDeleted: If `true`, soft-deleted models will be included in the results. Defaults to `false`.
    /// - returns: A new `QueryBuilder` for this model.
    public static func query(on conn: DatabaseConnectable, to database: DatabaseIdentifier<Database>? = nil, withSoftDeleted: Bool = false) -> QueryBuilder<Self.Database, Self> {
        return query(on: conn.databaseConnection(to: database ?? Self.defaultDatabase), withSoftDeleted: withSoftDeleted)
    }

    /// Attempts to find an instance of this model with the supplied identifier.
    ///
    ///     let user = try User.find(42)
    ///
    /// - parameters:
    ///     - id: ID to lookup.
    ///     - conn: Something `DatabaseConnectable` to create the `QueryBuilder` on.
    /// - returns: A future containing the model, if found.
    public static func find(_ id: Self.ID, on conn: DatabaseConnectable) -> Future<Self?> {
        return query(on: conn).filter(idKey == id).first()
    }

    /// Creates a `QueryBuilder` for this model, decoding instances of this model as the result.
    static func query(on connection: Future<Self.Database.Connection>, withSoftDeleted: Bool) -> QueryBuilder<Self.Database, Self> {
        let builder = QueryBuilder<Self.Database, Self.Database.Output>.raw(entity: Self.entity, on: connection).decode(Self.self).transformResult { row, conn, result in
            return Self.Database.modelEvent(event: .willRead, model: result, on: conn).flatMap { model -> Future<Self> in
                return try model.willRead(on: conn)
            }
        }
        
        if !withSoftDeleted, let deletedAtKey = Self.deletedAtKey {
            /// if the model is soft deletable, and soft deleted
            /// models were not requested, then exclude the
            return builder.group(Database.queryFilterRelationOr) { or in
                or.filter(deletedAtKey == nil)
                or.filter(deletedAtKey > Date())
            }
        } else {
            return builder
        }
    }
}

extension Decodable {
    /// Creates a `QueryBuilder` for a generic `Decodable` type on a given connection.
    ///
    ///     struct User: Codable {
    ///         var id: Int
    ///         var name: String
    ///     }
    ///
    ///     try SimpleUser.query("users", on: conn).count()
    ///
    /// - parameters:
    ///     - entity: Entity (table or collection name) to use for the query.
    ///     - conn: Connection to use.
    /// - returns: Newly created `QueryBuilder`.
    public static func query<C>(_ entity: String, on conn: C) -> QueryBuilder<C.Database, Self>
        where C: DatabaseConnection
    {
        return QueryBuilder<C.Database, C.Database.Output>.raw(entity: entity, on: conn.future(conn)).decode(data: Self.self, entity)
    }
}

// MARK: Default Database

/// Private static default database storage.
private var _defaultDatabases: [ObjectIdentifier: Any] = [:]

extension Model {
    /// This Model's default database. This will be used when no database id is passed (for example, on `Model.query(on:)`)
    /// or when it is not possible to pass a database (such as static lookup).
    ///
    /// You can set this property manually for each model. This is especially useful if you are not using migrations.
    ///
    ///     User.defaultDatabase = .mysql
    ///
    /// Make sure to set this property _before_ running any queries using your model.
    public static var defaultDatabase: DatabaseIdentifier<Database>? {
        get { return _defaultDatabases[ObjectIdentifier(Self.self)] as? DatabaseIdentifier<Database> }
        set { _defaultDatabases[ObjectIdentifier(Self.self)] = newValue }
    }

    /// Returns the `defaultDatabase` or throws an error.
    public static func requireDefaultDatabase() throws -> DatabaseIdentifier<Database> {
        guard let dbid = Self.defaultDatabase else {
            throw FluentError(
                identifier: "noDefaultDatabase",
                reason: "A default database is required if no database ID is passed to `\(Self.self).query(_:on:)` or if `\(Self.self)` is being looked up statically.",
                suggestedFixes: ["Set `\(Self.self).defaultDatabase` or to fix this error."]
            )
        }
        return dbid
    }
}

// Note: The below code is required so that Models can automatically be parameterizable. It's kind of a hack, don't touch it.

// MARK: Routing

extension Model where Database: QuerySupporting {
    /// See `Parameter`.
    public static func make(for parameter: String, using container: Container) throws -> Future<Self> {
        guard let idType = ID.self as? LosslessStringConvertible.Type else {
            throw FluentError(
                identifier: "invalidIDType",
                reason: "Could not convert string to ID.",
                suggestedFixes: ["Conform `\(ID.self)` to `LosslessStringConvertible` to fix this error."]
            )
        }

        guard let id = idType.init(parameter) as? ID else {
            throw FluentError(
                identifier: "invalidID",
                reason: "Could not convert parameter \(parameter) to type `\(ID.self)`"
            )
        }

        func findModel(in connection: Database.Connection) throws -> Future<Self> {
            return self.find(id, on: connection).map(to: Self.self) { model in
                guard let model = model else {
                    let error = FluentError(identifier: "modelNotFound", reason: "No model with ID \(id) was found")
                    throw NotFound(rootCause: error)
                }
                return model
            }
        }

        let dbid = try Self.requireDefaultDatabase()
        if let subcontainer = container as? SubContainer {
            let connection = subcontainer.requestCachedConnection(to: dbid)
            return connection.flatMap(to: Self.self, findModel)
        } else {
            return container.withPooledConnection(to: dbid, closure: findModel)
        }
    }

    /// See `Parameter`.
    public static func resolveParameter(_ parameter: String, on container: Container) throws -> Future<Self> {
        return try make(for: parameter, using: container)
    }
}
