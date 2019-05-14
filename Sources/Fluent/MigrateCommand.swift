import Vapor

public final class MigrateCommand: Command {
    public struct Signature: CommandSignature {
        public let revert = Option<Bool>(name: "revert", type: .flag)
    }

    public let signature = Signature()

    public let help: String? = nil

    let migrator: Migrator

    public init(migrator: Migrator) {
        self.migrator = migrator
    }

    public func run(using context: CommandContext<MigrateCommand>) throws {
        let isRevert = try context.option(\.revert) ?? false
        context.console.info("Migrate Command: \(isRevert ? "Revert" : "Prepare")")
        try self.migrator.setupIfNeeded().wait()
        if isRevert {
            try self.revert(using: context)
        } else {
            try self.prepare(using: context)
        }
    }

    private func revert(using context: CommandContext<MigrateCommand>) throws {
        let migrations = try self.migrator.previewRevertLastBatch().wait()
        guard migrations.count > 0 else {
            context.console.print("No migrations to revert.")
            return
        }
        context.console.print("The following migration(s) will be reverted:")
        for (migration, dbid) in migrations {
            context.console.print("- ", newLine: false)
            context.console.error(migration.name, newLine: false)
            context.console.print(" on ", newLine: false)
            context.console.print(dbid?.string ?? "default")
        }
        if context.console.confirm("Would you like to continue?".consoleText(.warning)) {
            try self.migrator.revertLastBatch().wait()
            context.console.print("Migration successful")
        } else {
            context.console.warning("Migration cancelled")
        }
    }

    private func prepare(using context: CommandContext<MigrateCommand>) throws {
        let migrations = try self.migrator.previewPrepareBatch().wait()
        guard migrations.count > 0 else {
            context.console.print("No new migrations.")
            return
        }
        context.console.print("The following migration(s) will be prepared:")
        for (migration, dbid) in migrations {
            context.console.print("+ ", newLine: false)
            context.console.success(migration.name, newLine: false)
            context.console.print(" on ", newLine: false)
            context.console.print(dbid?.string ?? "default")
        }
        if context.console.confirm("Would you like to continue?".consoleText(.warning)) {
            try self.migrator.prepareBatch().wait()
            context.console.print("Migration successful")
        } else {
            context.console.warning("Migration cancelled")
        }
    }
}
