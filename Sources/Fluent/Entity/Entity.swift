import Foundation

/**
    Represents an entity that can be
    stored and retrieved from the `Database`.
*/
public protocol Entity: Preparation, NodeConvertible {
    /**
        The collection or table name
        for this entity.
    */
    static var entity: String { get }

    /**
        The name to use for internal storage.

        This should be left as the default 
        implementation except for special cases
        like pivots.
    */
    static var name: String { get }
    
    /**
        The name of the column that corresponds
        to this entity's key.
     
        The default return is 'database.driver.idKey',
        and if no database is set, 'id' is returned,
        instead.
     */
    static var idKey: String { get }
    
    /**
        The entity's primary identifier.
        This is the same value used for
        `find(:_)`.
    */
    var id: Node? { get set }
    
    static var idType: Schema.Field.KeyType { get }

    /**
        Whether or not entity was retrieved from database.
        
        This value shouldn't be interacted w/ external users 
        w/o explicit knowledge.
     
        General implementation should just be `var exists = false`
    */
    var exists: Bool { get set }

    /**
        Called before the entity will be created.
    */
    func willCreate()

    /**
        Called after the entity has been created.
    */
    func didCreate()

    /**
        Called before the entity will be updated.
    */
    func willUpdate()

    /**
        Called after the entity has been updated.
    */
    func didUpdate()

    /**
        Called before the entity will be deleted.
    */
    func willDelete()

    /**
        Called after the entity has been deleted.
    */
    func didDelete()
}

// MARK: Defaults

extension Entity {
    /**
        The default entity is the
        lowercase model pluralized.
    */
    public static var entity: String {
        return name + "s"
    }

    public static var name: String {
        return String(describing: self).lowercased()
    }
    
    public static var idType: Schema.Field.KeyType {
        return database?.driver.idType ?? .int

    public static var idKey: String {
        return database?.driver.idKey ?? "id"
    }

    // FIXME: Remove in 2.0. Also, make exists optional.
    @available(*, deprecated: 1.0, message: "This 'exists' property is not stored. Add `var exists: Bool = false` to the model. This default implementation will be removed in a future update.")
    public var exists: Bool {
        get {
            let type = type(of: self)
            print("[DEPRECATED] No 'exists' property is stored on '\(type)'. Add `var exists: Bool = false` to this model. The default implementation will be removed in a future update.")
            return true
        }
        set {
            let type = type(of: self)
            print("[DEPRECATED] No 'exists' property is stored on '\(type)'. Add `var exists: Bool = false` to this model. The default implementation will be removed in a future update.")
        }
    }
}


extension Entity {
    public func willCreate() {}
    public func didCreate() {}
    public func willUpdate() {}
    public func didUpdate() {}
    public func willDelete() {}
    public func didDelete() {}
}

//MARK: CRUD

extension Entity {
    /**
        Persists the entity into the 
        data store and sets the `id` property.
    */
    public mutating func save() throws {
        try Self.query().save(&self)
    }

    /**
        Deletes the entity from the data
        store if the `id` property is set.
    */
    public func delete() throws {
        try Self.query().delete(self)
    }

    /**
        Returns all entities for this `Model`.
    */
    public static func all() throws -> [Self] {
        return try Self.query().all()
    }

    /**
        Finds the entity with the given `id`.
    */
    public static func find(_ id: NodeRepresentable) throws -> Self? {
        guard let _ = database else { return nil }
        return try Self.query().filter(Self.idKey, .equals, id).first()
    }

    /**
        Creates a `Query` instance for this `Model`.
    */
    public static func query() throws -> Query<Self> {
        guard let db = database else {
            throw EntityError.noDatabase
        }
        return Query(db)
    }
}

public enum EntityError: Error {
    case noDatabase
}

//MARK: Database

extension Entity {
    /**
        Fetches or sets the `Database` for this
        `Model` from the static database map.
    */
    public static var database: Database? {
        get {
            if let db = Database.map[Self.name] {
                return db
            } else {
                return Database.default
            }
        }
        set {
            Database.map[Self.name] = newValue
        }
    }
}
