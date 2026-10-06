# Agent Project Guidelines

This file contains general project-wide guidance and workflow rules for all AI coding agents working on ExpendiNote.

---

## Documentation & Source of Truth

Before making changes in any project area, AI agents MUST consult the relevant source-of-truth document. Treat these documents as authoritative unless the active code explicitly establishes a newer approved implementation that has not yet been documented.

| Area | Source of Truth |
| :--- | :--- |
| **Overall System Architecture** | `docs/design.md` |
| **UI & Visual Design System** | `docs/ui_design.md` |
| **Database Schema & Migration Philosophy** | `docs/database_migrations.md` |
| **Project Overview & Tech Stack** | `README.md` |

---

## Project Direction & Scope Discipline

- ExpendiNote is a Flutter Material 3 expense-tracking app.
- Follow the existing architecture and project structure before introducing new patterns.
- Prefer changes that reinforce the existing architecture and avoid unnecessary refactoring.
- Keep changes focused on the requested task.
- Do not add speculative features or unrelated improvements.
- Inspect the current implementation instead of relying on assumptions.
- Make the smallest appropriate change that fully satisfies the requested task.
- Avoid changing unrelated files, behavior, dependencies, or architecture.
- Reuse existing repositories, services, utilities, and components where appropriate.

---

## Database & Data Logic Rules

- **Database Boundaries**:
  - Treat `DatabaseService` (`lib/services/database_service.dart`) as the sole owner of schema creation and versioned database migrations.
  - Keep migrations as upgrade operations inside atomic transactions.
  - As an architectural rule for migration development: database migration exception handling must allow errors to propagate so that migration failures properly halt execution.
  - Do not issue ad-hoc schema creation SQL outside `DatabaseService`.
- **Data & Business Logic**:
  - Keep business rules in the appropriate model, repository, or service layer rather than duplicating them across UI widgets.
  - Persisted data changes should consider existing users and backward compatibility.
  - Preserve existing behavior unless the requested task explicitly changes it.
- **Transaction Model Rules**:
  - Respect the distinction between transaction `date` (when spending occurred) and `createdAt` (when entry was logged).
  - Order transaction lists consistently by:
    1. Primary: Transaction `date`
    2. Secondary: Transaction `id` (deterministic tie-breaker)

---

## UI & Visual Design Protocol

- Follow `docs/ui_design.md` as the ongoing source of truth for UI design and visual rules.
- Do **NOT** derive new UI patterns from the incorrect October 5 update (`b099baf`).
- Follow the existing Material 3 and centralized theme architecture.
- Prefer semantic theme values, shared dimensions, shapes, and components over one-off styling.
- Avoid introducing a new UI pattern when an existing project pattern can be reused.

---

## Testing & Review Methodology

- Testing is part of the normal development scope for ExpendiNote.
- When production behavior or functionality changes, add or update the relevant tests.
- Run `flutter analyze` and the relevant test suite(s) before declaring implementation work complete.
- Database/schema/migration changes should include appropriate migration/database tests.
- Do not expand the feature scope solely to add unrelated tests.
- Before declaring work complete:
  1. Verify the requested requirements are actually implemented.
  2. Inspect the resulting code and the complete current patch.
  3. Check related model, database, repository/service, and UI paths when the change crosses those layers.
  4. Check backward compatibility for persisted data when applicable.
  5. Check for unintended changes outside the requested scope.
  6. Treat current code as authoritative when an older review comment conflicts with the actual implementation.

---

## Documentation Maintenance & Agent Collaboration

- When an approved architectural, database, or design decision changes, update the relevant documentation under `docs/` so the source of truth remains current.
- Keep related Markdown documentation consistent without leaving contradictory instructions across files.
- Do not permanently add feature-specific instructions to this file unless they become a general project-wide rule.

---

## Important Rule

When a task prompt contains explicit new user instructions that conflict with a documented rule here, follow the user's newest explicit instruction.
