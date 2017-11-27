extension QueryRepresentable where E: Paginatable, Self: ExecutorRepresentable {
    public func paginate(
        page: Int,
        count: Int = E.defaultPageSize,
        computedFields: [RawOr<ComputedField>] = [],
        _ sorts: [Sort] = E.defaultPageSorts
    ) throws -> Page<E> {
        guard page > 0 else {
            throw PaginationError.invalidPageNumber(page)
        }
        // require page 1 or greater
        let page = page > 0 ? page : 1

        // create the query and get a total count
        let query = try makeQuery()
        let total = try query.aggregate(.count).int ?? 0

        // limit the query to the desired page
        try query.limit(count, offset: (page - 1) * count)
        
        // add the sorts w/o replacing
        _ = try sorts.map(query.sort)

        // fetch the data
        let data = try query.all(computedFields)

        return try Page(
            number: page,
            data: data,
            size: count,
            total: total
        )
    }
}
