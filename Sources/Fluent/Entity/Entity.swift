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
        The entity's primary identifier.
        This is the same value used for
        `find(:_)`.
    */
    var id: Node? { get set }
}

//MARK: Defaults

extension Entity {
    /**
        The default entity is the
        lowercase model pluralized.
    */
    public static var entity: String {
        return name + "s"
    }

    public static var name: String {
        return String(self).lowercased()
    }
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
        guard let idKey = database?.driver.idKey else {
            return nil
        }

        return try Self.query().filter(idKey, .equals, id).first()
    }

    /**
        Finds the entities with the given `ids`.
    */
    public static func find(_ ids: [NodeRepresentable]) throws -> [Self] {
        guard let idKey = database?.driver.idKey else {
            return []
        }

        return try Self.query().filter(idKey, .in, ids).all()
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
