# Database Migrations

## Current Schema Version

- Current database version: v2
- Stored in: `lib/constants/database_constants.dart` (`DbConfig.databaseVersion`)

## Migration History

- v1: Original app schema used a single `spendings` table:
  - `spendings(id, title, amount, date, category, description)`
- v2: Normalized schema introduced in refactor:
  - `transactions` — normalized spending records
  - `categories` — category metadata (name, icon, color, pinned/archived flags)
  - `settings` — key/value application settings

Migration recorded: v1 → v2 implemented directly in `lib/services/database_service.dart`.

## Migration Rules

- Migration MUST be atomic: v1→v2 is run inside a single transaction so partial changes rollback on failure.
- Category normalization during migration:
  - Trim whitespace, collapse multi-spaces, convert to Title Case (e.g., " food  " → "Food").
  - Empty or missing category names map to `Others`.
  - Category uniqueness enforced case-insensitively (`UNIQUE COLLATE NOCASE`) to prevent duplicates like `Food` and `food`.
- Foreign key enforcement:
  - `PRAGMA foreign_keys = ON` is enabled during DB configure to ensure referential integrity.
- Indexes:
  - `transactions(date)`, `transactions(categoryId)`, and `categories(name)` indexes are created `IF NOT EXISTS` for performance.
- Color values for categories are stored as integer ARGB values (no encoding change in migration).

## Upgrade Process (Developer Guide)

1. Update `DbConfig.databaseVersion` in `lib/constants/database_constants.dart`.
2. Add a private migration helper method within `DatabaseService` (e.g., `_migrateV2toV3`).
3. Ensure the migration method:
   - Performs schema modifications and data transformation within the `onUpgrade` transaction (or its own transaction if needed) to guarantee atomicity.
   - Uses centralized constants from `DbTables`/`DbCols`/`DbConfig` where appropriate, but maintains specific SQL for the target version to ensure independence from future schema changes.
   - Normalizes and deduplicates user-facing strings (categories) as required.
4. Update `DatabaseService.onUpgrade` to call your migration helper based on `oldVersion`.
5. Run `flutter analyze`, fix issues, then ship.

## Best Practices for Future Migrations

- Always write and run automated tests that:
  - Create a realistic pre-migration DB file, run migration, and assert final schema and data.
  - Simulate failures to confirm rollback semantics.
- Prefer non-destructive migrations where possible (create new tables, copy data, validate, then drop legacy tables at the very end of a successful transaction).
- Keep migration logic idempotent if possible: running twice should be safe or fail gracefully.
- Use centralized schema constants (`DbTables`, `DbCols`) across services, migrations, and tests.
- Avoid inline SQL string duplication; prefer constants and `IF NOT EXISTS` semantics for DDL.
- Log informative migration steps for easier debugging, but avoid leaking user data in logs.
- When changing column types or encodings (e.g., color representation), provide clear migration paths and tests ensuring no user data loss.

## Troubleshooting

- If migration fails during CI or on-device, reproduce locally by creating an equivalent vN DB using the test harness and run the migration helper.
- Verify `PRAGMA foreign_keys` is enabled during `onConfigure` — missing this can allow invalid data states.
