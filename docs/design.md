# System Architecture & Design Document

## 1. Executive Overview & Goals

ExpendiNote is a minimalist personal finance tracker designed for fast daily expense logging and a clear understanding of personal spending.

### Core Principles
- **Speed & Frictionless Logging**: Minimal steps required to record everyday transactions.
- **Privacy & Local-First**: All spending data resides locally in SQLite; data never leaves the device unless explicitly exported or backed up by the user.
- **Simplicity & Clarity**: Clean, intuitive Material 3 interface that keeps everyday spending easy to record and understand.
- **Data Integrity & Consistency**: Strict data model, centralized database ownership, and deterministic transaction ordering.

---

## 2. System & Screen Architecture

The application follows a layered Flutter architecture:

```
UI Layer (Screens & Widgets)
       ↓
Repository Layer (TransactionRepository, CategoryRepository, SettingsRepository)
       ↓
Service Layer (DatabaseService, BackupService, ImportService, ExportService)
       ↓
Local SQLite Database (`spending_database.db`)
```

### Layer Responsibilities

#### UI Layer (`lib/screens/`, `lib/widgets/`)
- Contains screen layouts, modal bottom sheets, dialogs, and reusable widgets.
- Observes changes via reactive notifiers (`ValueNotifier` / `ChangeNotifier`).
- Delegates data access and mutations strictly to repositories/services.

#### Repository Layer (`lib/repositories/`)
- Encapsulates queries and mutations for entities (`Transaction`, `Category`, `Settings`).
- Provides clean Dart interfaces for UI consumption.
- Coordinates database queries with model transformations.

#### Service Layer (`lib/services/`)
- **`DatabaseService`**: Centralized owner of SQLite database creation, opening, configuration (`PRAGMA foreign_keys = ON`), schema versioning (v5), and atomic migration handling (`onUpgrade`).
- **`BackupService`**: Manages creating full local JSON backup file exports.
- **`ImportService`**: Manages picking, parsing, validating (`ExportMigrationService`), and performing atomic JSON backup restores into SQLite.
- **`ExportService`**: Manages exporting transaction records into formatted CSV and PDF files.

---

## 3. Data Model & Rules

### Transaction Model (`lib/models/transaction.dart`)
- **`id`**: Autoincrement integer primary key in SQLite.
- **`title`**: String describing the transaction.
- **`amount`**: Numeric value representing spending.
- **`date`**: DateTime when the transaction actually occurred (user-selectable date/time).
- **`createdAt`**: DateTime when the transaction record was inserted/created in the application.
- **`categoryId`**: Foreign key linking to `categories.id`.
- **`description`**: Optional detailed note.
- **`includeInSpendingAnalysis`**: Boolean flag indicating whether this entry counts toward total spending analytics/summaries.

#### Transaction Ordering Invariant
Transaction lists and queries MUST follow deterministic ordering across all screens, exports, and reports:
1. **Primary Key/Ordering**: Transaction `date` (chronological order, typically descending for activity feeds).
2. **Secondary Deterministic Key**: Transaction `id` (descending/ascending depending on view direction).

*Rationale*: A user may log an older transaction at a later time. Using `date` reflects real-world chronology, while `id` provides stable, deterministic secondary tie-breaking for events occurring on the same transaction date.

### Category Model (`lib/models/category.dart`)
- Represents spending categories (`id`, `name`, `icon`, `color`, `isPinned`, `isArchived`, `includeInSpendingAnalysis`, `createdAt`).
- Enforces case-insensitive uniqueness (`UNIQUE COLLATE NOCASE`).
- Category management includes pinning, editing, archiving, and category merging.

### Spending Analysis Rules
- **Category Summary Views**: Display all transactions regardless of `includeInSpendingAnalysis` flag to give a complete view of category activity.
- **Daily & Monthly Summary Totals**: Filter strictly by `includeInSpendingAnalysis == true`.
- **Top Category Calculation**: Evaluates only transactions where `includeInSpendingAnalysis == true`. Returns 'None' if no included transactions exist for the period.

---

## 4. Reactive State & Navigation

- **Reactive Refresh**: UI screens maintain state synchronization using lightweight notifiers (e.g., `_refreshNotifier = ValueNotifier<int>(0)`).
- **Cross-Screen Consistency**: When a transaction or category is modified/deleted in a detail or edit screen, returning `true` triggers a bump to `_refreshNotifier`, reloading the dependent views.
- **Navigation Responsibilities**: Screen navigation delegates route pushes and arguments via standard Flutter Navigator patterns.

---

## 5. Database Architecture & Migration Philosophy

- **Centralized Ownership**: `DatabaseService` is the single owner of schema creation and database migrations.
- **Upgrade Operations**: Database versioning is incremental (v1 → v2 → v3 → v4 → v5). Migrations run within `onUpgrade`.
- **Foreign Keys**: Enforced via `PRAGMA foreign_keys = ON`.
- **Indexes**: Explicit indexes created on `transactions(date)`, `transactions(categoryId)`, and `categories(name)`.
- **No Direct Schema Manipulation Elsewhere**: Repositories and screens MUST NOT issue raw `CREATE TABLE` or schema-altering SQL outside of `DatabaseService`.

---

## 6. Backup, Restore, and Export Architecture

### Backup & Restore
- Full database state export is generated as a structured JSON file via `BackupService`.
- Restore picking, JSON migration, validation, and database insertion are executed via `ImportService`.
- Restore operates inside an atomic database transaction (`merge` or `replaceExistingTransactions`).

### Export Architecture
- **Supported Formats**: CSV and PDF formats via `ExportService`.
- **Unsupported Formats**: XLSX is explicitly dropped and omitted from export options.
- **Date Filtering**: Supports defined date-range filters (e.g. daily, monthly, all-time). Arbitrary custom date range selection is excluded unless explicitly added to the core feature set.

---

## 7. Important Architectural Invariants

1. **No Application Code in Docs**: Keep documentation separate from application source code (`lib/`).
2. **Layer Isolation**: UI widgets must not execute direct SQLite SQL queries.
3. **Deterministic Ordering**: Always order transaction queries by `date`, then `id`.
4. **Migration Safety**: Migration exception handling MUST allow errors to propagate so failed migrations rollback atomically.
