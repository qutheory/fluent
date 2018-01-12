/// Represents any type of schema builder
public protocol Builder: class {
    var entity: Entity.Type { get} 
    var fields: [RawOr<Field>] { get set }
    var foreignKeys: [RawOr<ForeignKey>] { get set }
}

extension Builder {
    public func field(_ field: Field) {
        fields.append(.some(field))
    }

    public func id() {
        let field = Field(
            name: entity.idKey,
            type: .id(type: entity.idType),
            primaryKey: true
        )
        self.field(field)
    }

    public func foreignId<E: Entity>(
        for entityType: E.Type,
        optional: Bool = false,
        unique: Bool = false,
        foreignIdKey: String = E.foreignIdKey,
        foreignKeyName: String? = nil,
        onUpdate: ForeignKey.ReferentialAction = .noAction,
        onDelete: ForeignKey.ReferentialAction = .noAction
    ) {
        let field = Field(
            name: foreignIdKey,
            type: .id(type: E.idType),
            optional: optional,
            unique: unique
        )
        self.field(field)
        
        if autoForeignKeys {
            self.foreignKey(
                foreignIdKey,
                references: E.idKey,
                on: E.self,
                named: foreignKeyName,
                onUpdate: onUpdate,
                onDelete: onDelete
            )
        }
    }

    public func int(
        _ name: String,
        optional: Bool = false,
        unique: Bool = false,
        default: NodeRepresentable? = nil
    ) {
        let field = Field(
            name: name,
            type: .int,
            optional: optional,
            unique: unique,
            default: `default`
        )
        self.field(field)
    }

    public func string(
        _ name: String,
        length: Int? = nil,
        optional: Bool = false,
        unique: Bool = false,
        default: NodeRepresentable? = nil
    ) {
        let field = Field(
            name: name,
            type: .string(length: length),
            optional: optional,
            unique: unique,
            default: `default`
        )
        self.field(field)
    }

    public func double(
        _ name: String,
        optional: Bool = false,
        unique: Bool = false,
        default: NodeRepresentable? = nil
    ) {
        let field = Field(
            name: name,
            type: .double,
            optional: optional,
            unique: unique,
            default: `default`
        )
        self.field(field)
    }

    public func bool(
        _ name: String,
        optional: Bool = false,
        unique: Bool = false,
        default: NodeRepresentable? = nil
    ) {
        let field = Field(
            name: name,
            type: .bool,
            optional: optional,
            unique: unique,
            default: `default`
        )
        self.field(field)
    }

    public func bytes(
        _ name: String,
        optional: Bool = false,
        unique: Bool = false,
        default: NodeRepresentable? = nil
    ) {
        let field = Field(
            name: name,
            type: .bytes,
            optional: optional,
            unique: unique,
            default: `default`
        )
        self.field(field)
    }

    public func date(
        _ name: String,
        optional: Bool = false,
        unique: Bool = false,
        default: NodeRepresentable? = nil
    ) {
        let field = Field(
            name: name,
            type: .date,
            optional: optional,
            unique: unique,
            default: `default`
        )
        self.field(field)
    }

    public func custom(
        _ name: String,
        type: String,
        optional: Bool = false,
        unique: Bool = false,
        default: NodeRepresentable? = nil
    ) {
        let field = Field(
            name: name,
            type: .custom(type: type),
            optional: optional,
            unique: unique,
            default: `default`
        )
        self.field(field)
    }

    // MARK: Relations

    public func parent<E: Entity>(
        _ entity: E.Type = E.self,
        optional: Bool = false,
        unique: Bool = false,
        foreignIdKey: String = E.foreignIdKey,
        onUpdate: ForeignKey.ReferentialAction = .noAction,
        onDelete: ForeignKey.ReferentialAction = .noAction
    ) {
        foreignId(
            for: E.self,
            optional: optional,
            unique: unique,
            foreignIdKey: foreignIdKey,
            onUpdate: onUpdate,
            onDelete: onDelete
        )
    }
    
    // MARK: Foreign Key
    
    public func foreignKey(_ foreignKey: ForeignKey) {
        foreignKeys.append(.some(foreignKey))
    }
    
    /// Adds a foreign key constraint from a local
    /// column to a column on the foreign entity.
    public func foreignKey<E: Entity>(
        _ foreignIdKey: String,
        references idKey: String,
        on foreignEntity: E.Type = E.self,
        named name: String? = nil,
        onUpdate: ForeignKey.ReferentialAction = .noAction,
        onDelete: ForeignKey.ReferentialAction = .noAction
    ) {
        let foreignKey = ForeignKey(
            entity: entity,
            field: foreignIdKey,
            foreignField: idKey,
            foreignEntity: foreignEntity,
            name: name,
            onUpdate: onUpdate,
            onDelete: onDelete
        )
        self.foreignKey(foreignKey)
    }
    
    /// Adds a foreign key constraint from a local
    /// column to a column on the foreign entity.
    public func foreignKey<E: Entity>(
        for: E.Type = E.self
    ) {
        self.foreignKey(
            E.foreignIdKey,
            references: E.idKey,
            on: E.self
        )
    }

    // MARK: Raw

    public func raw(_ string: String) {
        fields.append(.raw(string, []))
    }
}

public var autoForeignKeys = true


// MARK: Deprecated

extension Builder {
    @available(*, deprecated, message: "Please use foreignKey(_: String, references: String, on: Entity, named: String)")
    public func foreignKey<E: Entity>(
        foreignIdKey: String = E.foreignIdKey,
        referencesIdKey: String = E.idKey,
        on foreignEntity: E.Type = E.self,
        name: String? = nil
    ) {
        self.foreignKey(
            foreignIdKey,
            references: referencesIdKey,
            on: foreignEntity,
            named: name
        )
    }
}
