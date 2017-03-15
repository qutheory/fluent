/// Serializers a Query into general SQL
open class GeneralSQLSerializer<E: Entity>: SQLSerializer {
    public let query: Query<E>
    public required init(_ query: Query<E>) {
        self.query = query
    }

    open func serialize() -> (String, [Node]) {
        switch query.action {
        case .create:
            return insert()
        case .fetch:
            return select()
        case .count:
            return count()
        case .delete:
            return delete()
        case .modify:
            return modify()
        case .schema(let schema):
            switch schema {
            case .create(let fields):
                return create(fields)
            case .modify(let add, let remove):
                return alter(add: add, drop: remove)
            case .delete:
                return drop()
            }
        }
    }

    // MARK: Data

    open func insert() -> (String, [Node]) {
        var statement: [String] = []

        statement += "INSERT INTO"
        statement += escape(E.entity)

        let values: [Node]

        if let dict = query.data?.typeObject {
            values = Array(dict.values)
            let k = Array(dict.keys)

            statement += keys(k)
            statement += "VALUES"
            statement += placeholders(values)
        } else {
            values = []
        }

        return (
            concatenate(statement),
            values
        )
    }

    open func select() -> (String, [Node]) {
        var statement: [String] = []
        var values: [Node] = []

        let table = escape(E.entity)
        statement += "SELECT \(table).* FROM"
        statement += table

        if !query.joins.isEmpty {
            statement += joins(query.joins)
        }

        if !query.filters.isEmpty {
            let (filtersClause, filtersValues) = filters(query.filters)
            statement += filtersClause
            values += filtersValues
        }

        if !query.sorts.isEmpty {
            statement += sorts(query.sorts)
        }

        if let l = query.limit {
            statement += limit(l)
        }

        return (
            concatenate(statement),
            values
        )
    }

    open func count() -> (String, [Node]) {
        var fragments: [String] = []
        var values: [Node] = []

        fragments += "SELECT COUNT(*) as _fluent_count FROM"
        fragments += escape(E.entity)

        if !query.joins.isEmpty {
            fragments += joins(query.joins)
        }

        if !query.filters.isEmpty {
            let (filtersClause, filtersValues) = filters(query.filters)
            fragments += filtersClause
            values += filtersValues
        }

        return (
            concatenate(fragments),
            values
        )
    }

    open func delete() -> (String, [Node]) {
        var fragments: [String] = []
        var values: [Node] = []

        fragments += "DELETE FROM"
        fragments += escape(E.entity)

        if !query.filters.isEmpty {
            let (filtersClause, filtersValues) = filters(query.filters)
            fragments += filtersClause
            values += filtersValues
        }

        if let l = query.limit {
            fragments += limit(l)
        }

        return (
            concatenate(fragments),
            values
        )
    }

    open func modify() -> (String, [Node]) {
        var statement: [String] = []

        var values: [Node] = []

        statement += "UPDATE"
        statement += escape(E.entity)
        statement += "SET"

        if let data = query.data, let obj = data.typeObject {
            var fragments: [String] = []

            obj.forEach { (key, value) in
                fragments += escape(key) + " = " + placeholder(value)
            }

            statement += fragments.joined(separator: ", ")
            values += Array(obj.values)
        }

        let (filterclause, filterValues) = filters(query.filters)
        statement += filterclause
        values += filterValues

        return (
            concatenate(statement),
            values
        )
    }

    // MARK: Schema


    open func create(_ add: [Field]) -> (String, [Node]) {
        var statement: [String] = []

        statement += "CREATE TABLE"
        statement += escape(E.entity)
        statement += columns(add)

        return (
            concatenate(statement),
            []
        )
    }

    open func alter(add: [Field], drop: [Field]) -> (String, [Node]) {
        var statement: [String] = []

        statement += "ALTER TABLE"
        statement += escape(E.entity)

        var subclause: [String] = []

        for field in add {
            subclause += "ADD " + column(field)
        }

        for field in drop {
            subclause += "DROP " + escape(field.name)
        }

        statement += subclause.joined(separator: ", ")

        return (
            concatenate(statement),
            []
        )
    }

    open func drop() -> (String, [Node]) {
        var statement: [String] = []

        statement += "DROP TABLE IF EXISTS"
        statement += escape(E.entity)

        return (
            concatenate(statement),
            []
        )
    }

    open func columns(_ fields: [Field]) -> String {
        let string = fields.map { field in
            return column(field)
            }.joined(separator: ", ")

        return "(\(string))"
    }

    open func column(_ field: Field) -> String {
        var clause: [String] = []

        clause += escape(field.name)
        clause += type(field.type, primaryKey: field.primaryKey)

        if !field.optional {
            clause += "NOT NULL"
        }

        if field.unique {
            clause += "UNIQUE"
        }

        if let d = field.default {
            let dc: String

            switch d.wrapped {
            case .number(let n):
                dc = "'" + n.description + "'"
            case .null:
                dc = "NULL"
            case .bool(let b):
                dc = b ? "TRUE" : "FALSE"
            default:
                dc = "'" + (d.string ?? "") + "'"
            }

            clause += "DEFAULT \(dc)"
        }

        return clause.joined(separator: " ")
    }


    open func type(_ type: Field.DataType, primaryKey: Bool) -> String {
        switch type {
        case .id(let type):
            let typeString: String
            switch type {
            case .int:
                typeString = "INTEGER"
            case .uuid:
                typeString = "STRING"
            case .custom(let dataType):
                typeString = dataType
            }
            if primaryKey {
                return typeString + " PRIMARY KEY"
            } else {
                return typeString
            }
        case .int:
            return "INTEGER"
        case .string(_):
            return "STRING"
        case .double:
            return "DOUBLE"
        case .bool:
            return "BOOL"
        case .bytes:
            return "BLOB"
        case .date:
            return "TIMESTAMP"
        case .custom(let type):
            return type
        }
    }

    // MARK: Query Types

    open func limit(_ limit: Limit) -> String {
        var statement: [String] = []

        statement += "LIMIT"
        statement += "\(limit.offset), \(limit.count)"

        return statement.joined(separator: " ")
    }


    open func filters(_ f: [RawOr<Filter>]) -> (String, [Node]) {
        var fragments: [String] = []

        fragments += "WHERE"

        let (clause, values) = filters(f, .and)

        fragments += clause

        return (
            concatenate(fragments),
            values
        )
    }

    open func filters(_ filters: [RawOr<Filter>], _ r: Filter.Relation) -> (String, [Node]) {
        var fragments: [String] = []
        var values: [Node] = []


        var subFragments: [String] = []

        for f in filters {
            let (clause, subValues) = filter(f)
            subFragments += clause
            values += subValues
        }

        fragments += subFragments.joined(separator: " \(relation(r)) ")

        return (
            concatenate(fragments),
            values
        )
    }

    open func relation(_ relation: Filter.Relation) -> String {
        let word: String
        switch relation {
        case .and:
            word = "AND"
        case .or:
            word = "OR"
        }
        return word
    }

    open func filter(_ f: RawOr<Filter>) -> (String, [Node]) {
        switch f {
        case .raw(let string, let values):
            return (string, values)
        case .some(let f):
            return filter(f)
        }
    }

    open func filter(_ filter: Filter) -> (String, [Node]) {
        var statement: [String] = []
        var values: [Node] = []

        switch filter.method {
        case .compare(let key, let c, let value):
            // `.null` needs special handling in the case of `.equals` or `.notEquals`.
            if c == .equals && value == .null {
                statement += escape(filter.entity.entity) + "." + escape(key) + " IS NULL"
            }
            else if c == .notEquals && value == .null {
                statement += escape(filter.entity.entity) + "." + escape(key) + " IS NOT NULL"
            }
            else {
                statement += escape(filter.entity.entity) + "." + escape(key)
                statement += comparison(c)
                statement += "?"

                /// `.like` comparison operator requires additional
                /// processing of `value`
                switch c {
                case .hasPrefix:
                    values += hasPrefix(value)
                case .hasSuffix:
                    values += hasSuffix(value)
                case .contains:
                    values += contains(value)
                default:
                    values += value
                }
            }
        case .subset(let key, let s, let subValues):
            statement += escape(filter.entity.entity) + "." + escape(key)
            statement += scope(s)
            statement += placeholders(subValues)
            values += subValues
        case .group(let relation, let f):
            let (clause, subvals) = filters(f, relation)
            statement += "(\(clause))"
            values += subvals
        }

        return (
            concatenate(statement),
            values
        )
    }

    open func sorts(_ sorts: [Sort]) -> String {
        var clause: [String] = []

        clause += "ORDER BY"

        clause += sorts
            .map(sort)
            .joined(separator: ", ")

        return clause.joined(separator: " ")
    }

    open func sort(_ sort: Sort) -> String {
        var clause: [String] = []

        clause += escape(sort.entity.entity) + "." + escape(sort.field)

        switch sort.direction {
        case .ascending:
            clause += "ASC"
        case .descending:
            clause += "DESC"
        }

        return clause.joined(separator: " ")
    }

    open func comparison(_ comparison: Filter.Comparison) -> String {
        switch comparison {
        case .equals:
            return "="
        case .greaterThan:
            return ">"
        case .greaterThanOrEquals:
            return ">="
        case .lessThan:
            return "<"
        case .lessThanOrEquals:
            return "<="
        case .notEquals:
            return "!="
        case .hasSuffix:
            fallthrough
        case .hasPrefix:
            fallthrough
        case .contains:
            return "LIKE"
        case .custom(let string):
            return string
        }
    }

    open func hasPrefix(_ value: Node) -> Node {
        guard let string = value.string else {
            return value
        }

        return .string("\(string)%")
    }

    open func hasSuffix(_ value: Node) -> Node {
        guard let string = value.string else {
            return value
        }

        return .string("%\(string)")
    }

    open func contains(_ value: Node) -> Node {
        guard let string = value.string else {
            return value
        }

        return .string("%\(string)%")
    }

    open func scope(_ scope: Filter.Scope) -> String {
        switch scope {
        case .in:
            return "IN"
        case .notIn:
            return "NOT IN"
        }
    }

    open func joins(_ joins: [Join]) -> String {
        var fragments: [String] = []

        for j in joins {
            fragments += join(j)
        }

        return concatenate(fragments)
    }

    open func join(_ join: Join) -> String {
        var fragments: [String] = []

        fragments += "JOIN"
        fragments += escape(join.joined.entity)
        fragments += "ON"

        fragments += "\(escape(join.base.entity)).\(escape(join.baseKey))"
        fragments += "="
        fragments += "\(escape(join.joined.entity)).\(escape(join.joinedKey))"

        return concatenate(fragments)
    }

    // MARK: Convenience

    open func concatenate(_ fragments: [String]) -> String {
        return fragments.joined(separator: " ")
    }

    open func keys(_ keys: [String]) -> String {
        return list(keys.map { escape($0) })
    }

    open func list(_ list: [String]) -> String {
        let string = list.joined(separator: ", ")
        return "(\(string))"
    }

    open func placeholders(_ values: [Node]) -> String {
        let string = values.map { value in
            return placeholder(value)
        }.joined(separator: ", ")
        return "(\(string))"
    }

    open func placeholder(_ value: Node) -> String {
        return "?"
    }

    open func escape(_ string: String) -> String {
        return "`\(string)`"
    }
}

public func +=(lhs: inout [String], rhs: String) {
    lhs.append(rhs)
}

public func +=(lhs: inout [Node], rhs: Node) {
    lhs.append(rhs)
}
