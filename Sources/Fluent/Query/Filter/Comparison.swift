// MARK: Equality

/// Comparisons that require an equatable value.
public enum EqualityComparison {
    case equals
    case notEquals
}

extension Encodable {
    /// Null
    public static var null: Optional<Self> {
        return nil
    }
}

/// MARK: .equals

/// Model.field == value
/// FIXME: conditional conformance
//public func == <Model, Value>(lhs: ReferenceWritableKeyPath<Model, Value>, rhs: Value) throws -> ModelFilterMethod<Model>
//    where Model: Fluent.Model, Value: Encodable & Equatable
//{
//    return try ModelFilterMethod<Model>(
//        method: .compare(lhs.makeQueryField(), .equality(.equals), .value(rhs))
//    )
//}

/// field == value
public func == <
    Field: QueryFieldRepresentable,
    Value: Encodable & Equatable
>(lhs: Field, rhs: Value?) throws -> QueryFilterMethod {
    return try .compare(lhs.makeQueryField(), .equality(.equals), .value(rhs))
}

/// field == field
public func == <
    A: QueryFieldRepresentable,
    B: QueryFieldRepresentable
>(lhs: A, rhs: B) throws -> QueryFilterMethod {
    return try .compare(lhs.makeQueryField(), .equality(.equals), .field(rhs.makeQueryField()))
}

/// MARK: .notEquals

/// Model.field != value
/// FIXME: conditional conformance
//public func != <Model, Value>(lhs: ReferenceWritableKeyPath<Model, Value>, rhs: Value) throws -> ModelFilterMethod<Model>
//    where Model: Fluent.Model, Value: Encodable & Equatable
//{
//    return try ModelFilterMethod<Model>(
//        method: .compare(lhs.makeQueryField(), .equality(.notEquals), .value(rhs))
//    )
//}

/// field != value
public func != <
    Field: QueryFieldRepresentable,
    Value: Encodable & Equatable
>(lhs: Field, rhs: Value) throws -> QueryFilterMethod {
    return try .compare(lhs.makeQueryField(), .equality(.notEquals), .value(rhs))
}

/// field != field
public func != <
    A: QueryFieldRepresentable,
    B: QueryFieldRepresentable
>(lhs: A, rhs: B) throws -> QueryFilterMethod {
    return try .compare(lhs.makeQueryField(), .equality(.notEquals), .field(rhs.makeQueryField()))
}

// MARK: Sequence

/// Comparisons that require a sequence value.
public enum SequenceComparison {
    case hasSuffix
    case hasPrefix
    case contains
}

extension QueryBuilder {
    /// Add a sequence comparison to the query builder.
    public func filter<
        Field: QueryFieldRepresentable,
        Value: Encodable & Sequence
    >(
        _ field: Field,
        _ comparison: SequenceComparison,
        _ value: Value
    ) throws -> Self {
        return try filter(.compare(field.makeQueryField(), .sequence(comparison), .value(value)))
    }
}

// MARK: Ordered

/// Comparisons that require an ordered value.
public enum OrderedComparison {
    case greaterThan
    case lessThan
    case greaterThanOrEquals
    case lessThanOrEquals
}

/// .greaterThan

/// Model.field > value
/// FIXME: conditional conformance
//public func > <Model, Value>(lhs: ReferenceWritableKeyPath<Model, Value>, rhs: Value) throws -> ModelFilterMethod<Model>
//    where Model: Fluent.Model, Value: Encodable & Equatable
//{
//    return try ModelFilterMethod<Model>(
//        method: .compare(lhs.makeQueryField(), .order(.greaterThan), .value(rhs))
//    )
//}

/// field > value
public func > <
    Field: QueryFieldRepresentable,
    Value: Encodable & Comparable
>(lhs: Field, rhs: Value) throws -> QueryFilterMethod {
    return try .compare(lhs.makeQueryField(), .order(.greaterThan), .value(rhs))
}

/// field > field
public func > <
    A: QueryFieldRepresentable,
    B: QueryFieldRepresentable
>(lhs: A, rhs: B) throws -> QueryFilterMethod {
    return try .compare(lhs.makeQueryField(), .order(.greaterThan), .field(rhs.makeQueryField()))
}

/// .lessThan

/// Model.field > value
/// FIXME: conditional conformance
//public func < <Model, Value>(lhs: ReferenceWritableKeyPath<Model, Value>, rhs: Value) throws -> ModelFilterMethod<Model>
//    where Model: Fluent.Model, Value: Encodable & Equatable
//{
//    return try ModelFilterMethod<Model>(
//        method: .compare(lhs.makeQueryField(), .order(.lessThan), .value(rhs))
//    )
//}

/// field < value
public func < <
    Field: QueryFieldRepresentable,
    Value: Encodable & Comparable
>(lhs: Field, rhs: Value) throws -> QueryFilterMethod {
    return try .compare(lhs.makeQueryField(), .order(.lessThan), .value(rhs))
}

/// field > field
public func < <
    A: QueryFieldRepresentable,
    B: QueryFieldRepresentable
>(lhs: A, rhs: B) throws -> QueryFilterMethod {
    return try .compare(lhs.makeQueryField(), .order(.lessThan), .field(rhs.makeQueryField()))
}

/// .greaterThanOrEquals

/// Model.field >= value
/// FIXME: conditional conformance
//public func >= <Model, Value>(lhs: ReferenceWritableKeyPath<Model, Value>, rhs: Value) throws -> ModelFilterMethod<Model>
//    where Model: Fluent.Model, Value: Encodable & Equatable
//{
//    return try ModelFilterMethod<Model>(
//        method: .compare(lhs.makeQueryField(), .order(.greaterThanOrEquals), .value(rhs))
//    )
//}

/// field >= value
public func >= <
    Field: QueryFieldRepresentable,
    Value: Encodable & Comparable
>(lhs: Field, rhs: Value) throws -> QueryFilterMethod {
    return try .compare(lhs.makeQueryField(), .order(.greaterThanOrEquals), .value(rhs))
}

/// field >= field
public func >= <
    A: QueryFieldRepresentable,
    B: QueryFieldRepresentable
>(lhs: A, rhs: B) throws -> QueryFilterMethod {
    return try .compare(lhs.makeQueryField(), .order(.greaterThanOrEquals), .field(rhs.makeQueryField()))
}

/// .lessThanOrEquals

/// Model.field <= value
/// FIXME: conditional conformance
//public func <= <Model, Value>(lhs: ReferenceWritableKeyPath<Model, Value>, rhs: Value) throws -> ModelFilterMethod<Model>
//    where Model: Fluent.Model, Value: Encodable & Equatable
//{
//    return try ModelFilterMethod<Model>(
//        method: .compare(lhs.makeQueryField(), .order(.lessThanOrEquals), .value(rhs))
//    )
//}

/// field <= value
public func <= <
    Field: QueryFieldRepresentable,
    Value: Encodable & Comparable
>(lhs: Field, rhs: Value) throws -> QueryFilterMethod {
    return try .compare(lhs.makeQueryField(), .order(.lessThanOrEquals), .value(rhs))
}

/// field <= field
public func <= <
    A: QueryFieldRepresentable,
    B: QueryFieldRepresentable
    >(lhs: A, rhs: B) throws -> QueryFilterMethod {
    return try .compare(lhs.makeQueryField(), .order(.lessThanOrEquals), .field(rhs.makeQueryField()))
}
