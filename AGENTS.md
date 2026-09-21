# Agent Project Guidelines

This file records decisions and implementation methods that all coding agents (Gemini, Jules, Copilot, etc.) must follow when working on ExpendiNote.

## 1. Project Direction
- ExpendiNote is a Flutter Material 3 expense-tracking app.
- Complete requested features before doing the planned full UI redesign.
- Do not start analytics, interactive charts, budgets, recurring transactions, or other future-scope work unless explicitly requested.
- Prefer changes that reinforce the current architecture and avoid unnecessary refactoring.
- Keep changes scoped to the requested issue/PR.
- Do not add speculative features or improvements outside the requested scope.

## 2. Testing Decision
- Tests are intentionally not a current project focus.
- Do not add or recreate test files unless explicitly requested.
- Do not expand a feature's scope just to introduce tests.

## 3. Database Architecture
- DatabaseService is the single owner of schema creation and migration logic.
- Fresh-install schema creation belongs in DatabaseService._createTables().
- Migrations are upgrade operations only; do not create a separate migration framework/files unless explicitly decided later.
- Keep migrations version-aware and preserve historical migration boundaries.
- Current database version is 4.
- For schema changes, update the database version, fresh-install schema, appropriate upgrade migration, and documentation when needed.
- Do not swallow migration errors with broad try/catch blocks.
- Avoid unrelated database refactors while implementing feature work.

## 4. Category Architecture
- Categories are data-driven; do not reintroduce hardcoded category lists into transaction UI.
- Category metadata includes name, icon, color, pinning, and archive state.
- Category names are trimmed and validated case-insensitively for uniqueness.
- Category usage statistics are derived from transactions.
- Category colors are data-level values and remain independent of the global app theme.
- Deleting a category with transactions is restricted; users should rename or merge instead.
- Merge operations must preserve transaction integrity and be transactional.

## 5. Spending-Analysis Inclusion
The includeInSpendingAnalysis flag exists at both category and transaction level.

### Category
- Category.includeInSpendingAnalysis is the default for new transactions in that category.
- Normal/custom categories default to true.
- The built-in Investment category defaults to false.
- A custom category can opt out by changing its default in category management.

### Transaction
- Transaction.includeInSpendingAnalysis controls whether that individual transaction contributes to normal spending totals.
- New transactions inherit the selected category's default.
- Existing transactions preserve their stored transaction-level value.
- If an existing transaction changes category, the user must be able to keep the current transaction setting or apply the new category default.
- Never silently overwrite an existing transaction's inclusion choice because its category changed.

### Summary behavior
- Excluded transactions must not contribute to normal daily/monthly/home spending totals.
- Excluded transactions must not become the top category.
- Excluded transactions must not contribute to normal spending overview calculations.
- Excluded transactions must remain visible in history, searchable, and visible in transaction details.
- When all transactions in a summary are excluded, the top category must be None rather than falling back to excluded transactions.

## 6. Import / Export
- Preserve includeInSpendingAnalysis when the existing data format supports it.
- JSON import should tolerate both camelCase and snake_case field names where already supported, and handle boolean/numeric representations.
- Missing inclusion data should default to true for backward compatibility.
- Do not claim that JSON backup/export exists unless it is actually implemented.
- Do not expand a feature PR into a general backup/export redesign unless explicitly requested.

## 7. Theme Architecture
- Use the centralized theme architecture under lib/theme/.
- Prefer semantic ColorScheme, TextTheme, component themes, shared dimensions, and shared shapes.
- Theme mode and custom theme color selection are independent settings.
- Preserve Android Dynamic Color when custom theme is disabled.
- Category colors remain independent from global theme colors.
- Do not create one-off global colors when an existing semantic theme value is appropriate.

## 8. UI / Code Style
- Follow the existing project structure and naming conventions.
- Prefer small, focused changes over broad rewrites.
- Reuse existing repositories/services/utilities instead of duplicating logic.
- Keep business rules in the appropriate model/repository/service layer rather than scattering them through widgets.
- Preserve existing behavior unless the issue explicitly changes it.
- Before changing behavior, inspect the current implementation and related screens/services.

## 9. Review Method
Before declaring a task complete:
1. Read the relevant issue/PR requirements.
2. Inspect the current implementation rather than relying on assumptions.
3. Trace the feature through model -> database -> repository/service -> UI -> import/export as applicable.
4. Check backward compatibility and migration behavior for persisted data.
5. Check that excluded/optional data is still visible where visibility is expected.
6. Review the actual current patch after making fixes; do not rely on stale review comments.
7. Keep the final change set limited to the requested scope.

## 10. Current PR #15 Context
PR #15 implements transaction/category-level spending-analysis inclusion and the Investment category.

Core requirements already implemented include:
- database v3 -> v4 migration;
- Investment category seeded/ensured with inclusion disabled;
- category-level default;
- transaction-level inclusion toggle;
- category-change handling for existing transactions;
- filtering of normal spending totals and top-category calculations;
- continued visibility/search/details for excluded transactions;
- CSV export preservation;
- JSON import preservation.

Do not expand PR #15 into analytics, charts, budgets, recurring transactions, or unrelated UI redesign.

## 11. Important Rule
When a future agent receives a request that conflicts with a decision in this file, follow the user's newest explicit decision. Otherwise, treat this file as the project's source of truth for the documented facts and methods above.
