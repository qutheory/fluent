import Async
import Dispatch
import Fluent
import Foundation

extension Benchmarker where Database: QuerySupporting {
    /// The actual benchmark.
    fileprivate func _benchmark(on conn: Database.Connection) throws {
        // create
        let a = Foo<Database>(bar: "asdf", baz: 42)
        let b = Foo<Database>(bar: "asdf", baz: 42)
        
        _ = try test(a.save(on: conn))
        _ = try test(b.save(on: conn))
        var count = try test(conn.query(Foo<Database>.self).count())
        if count != 2 {
            self.fail("count should have been 2")
        }

        // update
        b.bar = "fdsa"
        _ = try test(b.save(on: conn))

        // read
        let fetched = try test(Foo<Database>.find(b.requireID(), on: conn))
        if fetched?.bar != "fdsa" {
            self.fail("b.bar should have been updated")
        }

        // make sure that AND queries work as expected - this query should return exactly one result
        let fetchedWithAndQuery = try test(Foo<Database>.query(on: conn)
            .group(.and) { and in
                and.filter(\Foo.bar == "asdf")
                and.filter(\Foo.baz == 42)
            }
            .all())
        if fetchedWithAndQuery.count != 1 {
            self.fail("fetchedWithAndQuery.count = \(fetchedWithAndQuery.count), should be 1")
        }

        let c = try test(b.delete(on: conn))
        if c.id != nil {
            self.fail("id should have been set to nil")
        }
        count = try test(conn.query(Foo<Database>.self).count())
        if count != 1 {
            self.fail("count should have been 1")
        }
    }

    /// Benchmark the basic model CRUD.
    public func benchmarkModels() throws {
        let conn = try test(pool.requestConnection())
        try self._benchmark(on: conn)
        pool.releaseConnection(conn)
    }
}

extension Benchmarker where Database: QuerySupporting & SchemaSupporting {
    /// Benchmark the basic model CRUD.
    /// The schema will be prepared first.
    public func benchmarkModels_withSchema() throws {
        let conn = try test(pool.requestConnection())
        try test(FooMigration<Database>.prepare(on: conn))
        defer {
            try? test(FooMigration<Database>.revert(on: conn))
        }
        try self._benchmark(on: conn)
        pool.releaseConnection(conn)
    }
}
