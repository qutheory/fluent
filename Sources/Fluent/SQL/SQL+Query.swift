extension SQL {
	init<T: Entity>(query: Query<T>) {
        switch query.action {
        case .fetch:
            self = .select(
                table: query.entity,
                filters: query.filters,
                joins: query.unions,
                orders: query.sorts,
                limit: query.limit
            )
        case .create:
            self = .insert(
                table: query.entity,
                data: query.data,
                shouldUpdate: false
            )
        case .createOrModify:
            self = .insert(
                table: query.entity,
                data: query.data,
                shouldUpdate: true
            )
        case .delete:
            self = .delete(
                table: query.entity,
                filters: query.filters,
                limit: query.limit
            )
        case .modify:
            self = .update(
                table: query.entity,
                filters: query.filters,
                data: query.data
            )
        }
    }
}

extension Query {
    public var sql: SQL {
        return SQL(query: self)
    }
}
