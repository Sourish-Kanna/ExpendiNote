# Agent Project Guidelines

This file contains general project-wide guidance for all coding agents working on ExpendiNote.

## Project Direction

- ExpendiNote is a Flutter Material 3 expense-tracking app.
- Follow the existing architecture and project structure before introducing new patterns.
- Prefer changes that reinforce the existing architecture and avoid unnecessary refactoring.
- Keep changes focused on the requested task.
- Do not add speculative features or unrelated improvements.
- Complete requested feature work before doing a planned broad UI redesign.
- Do not start future-scope work unless explicitly requested.
- The user's newest explicit decision takes precedence over older project guidance.

## Scope Discipline

- Read and understand the relevant issue, PR, or task requirements before making changes.
- Inspect the current implementation instead of relying on assumptions.
- Make the smallest appropriate change that fully satisfies the requested task.
- Avoid changing unrelated files, behavior, dependencies, or architecture.
- Reuse existing repositories, services, utilities, and components where appropriate.
- Do not expand a feature task into analytics, redesign, refactoring, or other future work unless explicitly requested.

## Database Architecture

- Keep database responsibilities centralized in the existing database architecture.
- Fresh-install schema creation and upgrade migrations must remain clearly separated.
- Migrations should perform upgrade operations appropriate to their version boundary.
- Keep database versioning and migration behavior backward-compatible.
- Do not swallow database migration errors.
- Avoid unrelated database schema or migration refactors.

## Data & Business Logic

- Keep business rules in the appropriate model, repository, or service layer rather than duplicating them across UI widgets.
- Persisted data changes should consider existing users and backward compatibility.
- Prefer data-driven behavior over hardcoded feature-specific values when the existing architecture supports it.
- Preserve existing behavior unless the requested task explicitly changes it.

## UI & Theme

- Follow the existing Material 3 and centralized theme architecture.
- Prefer semantic theme values, shared dimensions, shapes, and components over one-off styling.
- Keep data-level styling separate from global application theme styling where the architecture requires it.
- Avoid introducing a new UI pattern when an existing project pattern can be reused.
- Feature implementation and UI redesign should remain separate unless redesign is explicitly requested.

## Testing

- Follow the current project decision regarding tests.
- Do not introduce a new testing strategy or recreate removed tests unless explicitly requested.
- Do not expand feature scope solely to add tests.

## Review Method

Before declaring work complete:

1. Verify the requested requirements are actually implemented.
2. Inspect the resulting code and the complete current patch.
3. Check related model, database, repository/service, and UI paths when the change crosses those layers.
4. Check backward compatibility for persisted data when applicable.
5. Check for unintended changes outside the requested scope.
6. Treat current code as authoritative when an older review comment conflicts with the actual implementation.
7. Keep the final change set focused and consistent with the existing architecture.

## Agent Collaboration

- This file provides general project guidance only.
- Feature-specific requirements, acceptance criteria, implementation details, and temporary decisions should be provided in the relevant issue, PR, or direct task prompt.
- Do not permanently add feature-specific instructions to this file unless they become a general project-wide rule.

## Important Rule

When a task conflicts with a documented rule here, follow the user's newest explicit instruction.
