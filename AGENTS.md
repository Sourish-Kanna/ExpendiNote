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

## Agent Behavior & Workflow Protocol

1. **Consult Source of Truth First**:
   - Read `docs/design.md` before making architectural or structural code changes.
   - Read `docs/ui_design.md` before modifying, refactoring, or creating UI screens and components.
   - Read `docs/database_migrations.md` before changing database models, constants, or migrations.
2. **Follow Documented UI Guidelines**:
   - Treat `docs/ui_design.md` as the actual ongoing source of truth for UI design and visual language.
   - Do **NOT** derive new UI patterns from the incorrect October 5 update (`b099baf`).
   - Prefer consistency with existing design-system rules in `docs/ui_design.md` over introducing arbitrary screen-specific styling.
3. **Database & Persistence Boundaries**:
   - Treat `DatabaseService` (`lib/services/database_service.dart`) as the sole owner of schema creation and versioned database migrations.
   - Keep migrations as upgrade operations inside atomic transactions.
   - Never swallow database migration errors with try-catch blocks.
   - Do not issue ad-hoc schema creation SQL outside `DatabaseService`.
4. **Transaction Model Rules**:
   - Respect the distinction between transaction `date` (when spending occurred) and `createdAt` (when entry was logged).
   - Order transaction lists consistently by:
     1. Primary: Transaction `date`
     2. Secondary: Transaction `id` (deterministic tie-breaker)
5. **Documentation Maintenance**:
   - When an approved architectural, database, or design change is made, update the relevant documentation under `docs/` so the source of truth stays current.
   - Do not leave contradictory instructions across Markdown files.
   - Do not duplicate large portions of design docs inside this file; point agents to the proper source of truth.

---

## Scope Discipline & Review

- Inspect current implementations instead of relying on assumptions.
- Make the smallest appropriate change that fully satisfies the requested task.
- Avoid changing unrelated files, behavior, dependencies, or architecture.
- Reuse existing repositories, services, utilities, and components where appropriate.
- Verify that changes meet acceptance criteria and do not introduce regressions.

---

## Important Rule

When a task prompt contains explicit new user instructions that conflict with a documented rule here, follow the user's newest explicit instruction.
