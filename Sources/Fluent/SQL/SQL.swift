/// Represents a SQL query that
/// can act as an intermediary between
/// Fluent data structures and serializers.
public enum SQL {
    public enum TableAction {
        case create(columns: [Schema.Field])
        case alter(create: [Schema.Field], delete: [String])
        case drop
    }
    
    case insert(table: String, data: Node?)
    case select(table: String, filters: [Filter], joins: [Join], groups: [GroupBy], orders: [Sort], limit: Limit?)
    case count(table: String, filters: [Filter], joins: [Join], groups: [GroupBy])
    case update(table: String, filters: [Filter], data: Node?)
    case delete(table: String, filters: [Filter], limit: Limit?)
    case table(action: TableAction, table: String)
}
