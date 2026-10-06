# Database Migrations & Database Architecture

## Current Schema Version

- Current database version: v2
- Stored in: `lib/constants/database_constants.dart` (`DbConfig.databaseVersion`)

## Architecture & Database Ownership

`DatabaseService` (`lib/services/database_service.dart`) is the centralized owner of schema creation, versioning, upgrade migrations, and SQLite lifecycle management (`PRAGMA foreign_keys = ON`).

No direct table creation or schema alteration operations should occur outside `DatabaseService`.

## Migration History

- v1: Original app schema used a single `spendings` table:
  - `spendings(id, title, amount, date, category, description)`
- v2: Normalized schema introduced in refactor:
  - `transactions` — normalized spending records (`id`, `title`, `amount`, `date`, `createdAt`, `categoryId`, `description`, `includeInSpendingAnalysis`)
  - `categories` — category metadata (`id`, `name`, `icon`, `color`, `isPinned`, `isArchived`)
  - `settings` — key/value application settings (`key`, `value`)

Migration recorded: v1 → v2 implemented directly in `lib/services/database_service.dart`.

## Migration Rules

- Migration MUST be atomic: v1→v2 is run inside a single transaction so partial changes rollback on failure.
- Migration errors MUST NOT be swallowed in try-catch blocks; failures must halt execution to ensure rollback.
- Category normalization during migration:
  - Trim whitespace, collapse multi-spaces, convert to Title Case (e.g., " food  " → "Food").
  - Empty or missing category names map to `Others`.
  - Category uniqueness enforced case-insensitively (`UNIQUE COLLATE NOCASE`) to prevent duplicates like `Food` and `food`.
- Foreign key enforcement:
  - `PRAGMA foreign_keys = ON` is enabled during DB configure to ensure referential integrity.
- Indexes:
  - `transactions(date)`, `transactions(categoryId)`, and `categories(name)` indexes are created `IF NOT EXISTS` for performance.
- Color values for categories are stored as integer ARGB values.

## Upgrade Process (Developer Guide)

1. Update `DbConfig.databaseVersion` in `lib/constants/database_constants.dart`.
2. Add a private migration helper method within `DatabaseService` (e.g., `_migrateV2toV3`).
3. Ensure the migration method:
   - Performs schema modifications and data transformation within the `onUpgrade` transaction to guarantee atomicity.
   - Uses centralized constants from `DbTables`/`DbCols`/`DbConfig` where appropriate.
   - Normalizes and deduplicates user-facing strings (categories) as required.
4. Update `DatabaseService.onUpgrade` to call your migration helper based on `oldVersion`.
5. Run tests, verify schema consistency, then ship.

## Best Practices for Future Migrations

- Always write and run automated tests that:
  - Create a realistic pre-migration DB file, run migration, and assert final schema and data.
  - Simulate failures to confirm rollback semantics.
- Prefer non-destructive migrations where possible (create new tables, copy data, validate, then drop legacy tables at the very end of a successful transaction).
- Keep migration logic idempotent if possible: running twice should be safe or fail gracefully.
- Use centralized schema constants (`DbTables`, `DbCols`) across services, migrations, and tests.
- Avoid inline SQL string duplication; prefer constants and `IF NOT EXISTS` semantics for DDL.
- Log informative migration steps for easier debugging, but avoid leaking user data in logs.
