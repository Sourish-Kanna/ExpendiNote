# Database Migrations & Database Architecture

## Current Schema Version

- **Current Database Version**: **v5**
- **Stored in**: `lib/constants/database_constants.dart` (`DbConfig.databaseVersion = 5`)

---

## Database Architecture & Ownership

`DatabaseService` (`lib/services/database_service.dart`) is the centralized owner of SQLite database initialization, table creation, version management, and upgrade migrations (`PRAGMA foreign_keys = ON`).

No direct table creation, column modification, or schema migration operations should occur outside `DatabaseService`.

---

## Complete Migration History

- **v1**: Initial legacy schema using a single `spendings` table:
  - `spendings(id, title, amount, date, category, description)`
- **v2**: Normalized schema introducing dedicated tables:
  - `categories(id, name, createdAt)`
  - `transactions(id, title, amount, date, categoryId, description, createdAt)`
  - `settings(key, value)`
- **v3**: Category model enhancements:
  - Added `icon`, `color`, `isPinned`, and `isArchived` columns to `categories`.
- **v4**: Spending analysis controls:
  - Added `includeInSpendingAnalysis` flag to both `categories` and `transactions` tables (defaults to `1` / `true`).
  - Automatically sets default `includeInSpendingAnalysis = 0` for the `Investment` category.
- **v5**: Icon representation refactoring:
  - Migrated legacy numerical icon code point strings (e.g. `'58674'`) to stable named string identifiers (e.g. `'restaurant'`) in the `categories` table.

---

## Current Database Schema (v5 Summary)

### `categories` Table
- `id`: `INTEGER PRIMARY KEY AUTOINCREMENT`
- `name`: `TEXT NOT NULL UNIQUE COLLATE NOCASE`
- `icon`: `TEXT` (stable string key, e.g. `'restaurant'`)
- `color`: `INTEGER` (ARGB integer value)
- `isPinned`: `INTEGER DEFAULT 0`
- `isArchived`: `INTEGER DEFAULT 0`
- `includeInSpendingAnalysis`: `INTEGER DEFAULT 1`
- `createdAt`: `TEXT NOT NULL` (ISO-8601 string)

### `transactions` Table
- `id`: `INTEGER PRIMARY KEY AUTOINCREMENT`
- `title`: `TEXT NOT NULL`
- `amount`: `REAL NOT NULL`
- `date`: `TEXT NOT NULL` (ISO-8601 transaction occurrence date)
- `categoryId`: `INTEGER` (foreign key -> `categories(id)`)
- `description`: `TEXT`
- `includeInSpendingAnalysis`: `INTEGER DEFAULT 1`
- `createdAt`: `TEXT NOT NULL` (ISO-8601 creation date)

### `settings` Table
- `key`: `TEXT PRIMARY KEY`
- `value`: `TEXT`

---

## Migration Rules & Architectural Directives

- **Atomicity**: Migration steps execute within the database `onUpgrade` process.
- **Error Propagation Rule**: Database migration helper logic MUST allow migration exceptions to propagate so that migration failures properly halt database opening rather than being silently swallowed.
- **Category Normalization**: During migrations (e.g. v1→v2), category strings are trimmed, collapsed, converted to Title Case, and mapped to `Others` if empty.
- **Foreign Key Support**: `PRAGMA foreign_keys = ON` is enabled during database configuration (`onConfigure`).
- **Indexes**: `transactions(date)`, `transactions(categoryId)`, and `categories(name)` indexes are maintained for lookup performance.

---

## Upgrade Process (Developer Guide)

1. Increment `DbConfig.databaseVersion` in `lib/constants/database_constants.dart`.
2. Add a private migration helper method within `DatabaseService` (e.g., `_migrateV5toV6`).
3. Ensure the migration method:
   - Performs DDL and DML operations within `onUpgrade` transaction boundaries.
   - Uses centralized constants (`DbTables`, `DbCols`) where possible while isolating version-specific SQL logic.
   - Let errors throw to prevent unverified or partially migrated states.
4. Call the helper sequentially inside `onUpgrade` according to `oldVersion`.
5. Write and verify automated migration tests in `test/database/migration_test.dart`.
