# Project UI Design System & Visual Guidelines

## 1. Design System Authority & Source of Truth

This document (`docs/ui_design.md`) is the ongoing **source of truth** for all visual and user-interface design rules across ExpendiNote. Future screens, widgets, and UI features MUST adhere directly to the visual guidelines defined herein.

### Historical Context & Reference Baseline
The design principles, component hierarchy, card structures, and visual language documented here were derived from studying the pre-October-5 Home Screen implementation (specifically git commit `d4b9d17392ec0dea17298e2f682cff95d3d6eac8`).

> **NOTE ON OCTOBER 5 UPDATE (`b099baf`)**:
> The Home Screen refactoring introduced in commit `b099baf` on October 5/6, 2026 was **INCORRECT** and does **NOT** represent the intended UI design direction. Do **NOT** use commit `b099baf` or its `SummaryCard` refactoring as a reference for future UI design or component layout. Follow `docs/ui_design.md` directly.

### Representative Codebase Examples
When building or updating UI components, refer to the established patterns in:
- `lib/screens/add_spending_screen.dart` (Primary metric cards, form layout, and input styling)
- `lib/screens/spending_detail_screen.dart` (Category-tinted cards and detail rows)
- `lib/screens/category_management_screen.dart` (Category item styling and badge indicators)

---

## 2. Visual Direction & Material 3 Principles

ExpendiNote uses a clean, modern, high-contrast Material 3 design system built for speed, legibility, and effortless expense logging.

### Background & Safe Area
- **Scaffold Background**: Root Scaffold background MUST be `colorScheme.surface`.
- **Global Safe Area**: Do **NOT** add a local `SafeArea` widget inside individual screens. The application handles global safe areas inside `MaterialApp.builder` (`lib/main.dart`) to ensure full-bleed themed backgrounds across devices.

---

## 3. Card & Container Architecture

### Elevation
- All `Card` widgets MUST use `elevation: 0`. Depth is expressed through background tinting and subtle borders, not heavy material dropshadows.

### Border Radius Hierarchy
- **Primary Metric / Highlight Summary Banners**: `BorderRadius.circular(28)`
- **Grouped Container / Section Cards**: `BorderRadius.circular(24)`
- **List Item Cards**: `BorderRadius.circular(16)`
- **Small Tags / Badges / Input Containers**: `BorderRadius.circular(12)`

### Background Tints & Opacity
- **App Overview / Highlight Banners**: `colorScheme.primaryContainer.withValues(alpha: 0.3)`
- **Neutral Group Cards**: `colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)`
- **Category-Associated Cards / Items**:
  - Default: Category's custom color (`catColor`) with low opacity: `catColor.withValues(alpha: 0.12)`.
  - Selected State: `catColor.withValues(alpha: 0.2)` with a 2px solid border in `catColor`.

---

## 4. Typography & Text Hierarchy

ExpendiNote relies on bold, readable typography with strong visual contrast:

- **AppBars**: `textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)`, with `scrolledUnderElevation: 0`.
- **Section Headers**: Bold label style (`textTheme.titleMedium` or `textTheme.labelLarge` with `fontWeight.bold`).
- **Primary Metric Numbers**: `textTheme.displayMedium` or `textTheme.headlineMedium` with `fontWeight.bold`.
- **List Item Titles**: `textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)`.
- **Subtitles & Auxiliary Text**: `textTheme.bodySmall` or `textTheme.bodyMedium` using lower contrast text colors (e.g. `colorScheme.onSurfaceVariant`).

---

## 5. Iconography

- **Filled Material Icons**: Always use FILLED Material icons (e.g., `Icons.calendar_today`, `Icons.analytics`, `Icons.share`, `Icons.delete`, `Icons.edit`, `Icons.settings`, `Icons.category`, `Icons.chevron_right`).
- **No Outlined Variants**: Do **NOT** use `_outlined` icon variants (e.g., avoid `Icons.delete_outline` or `Icons.edit_outlined`).
- **Category Icons**: Render category icons directly in the category's custom color (`catColor`) rather than wrapping them in heavy `CircleAvatar` backgrounds.

---

## 6. Spacing & Padding System

- **Standard Screen Outer Padding**: `EdgeInsets.symmetric(horizontal: 16, vertical: 12)`.
- **Item / Card Vertical Spacing**: `8dp` to `12dp`.
- **Major Section Spacing**: `20dp` to `28dp`.

---

## 7. Component & Screen Patterns

### AppBars
- Clean title layout using `titleLarge`.
- No scrolled under elevation (`scrolledUnderElevation: 0`).
- Transparent or `surface` background.

### Summary & Metric Banners
- Top-of-screen summary metrics are displayed in prominent cards (`BorderRadius.circular(28)`) using `primaryContainer.withValues(alpha: 0.3)`.

### List Items & Activity Feeds
- Encapsulated in `Card` (`elevation: 0`, `BorderRadius.circular(16)`).
- Category color tinting at `0.12` alpha.
- Trailing action menus or expand icons aligned consistently.

### Empty, Loading & Error States
- Empty state: Center-aligned icon (`Icons.receipt_long`, size 64) with neutral muted color (`colorScheme.outline`) and concise textual notice (e.g. "No spending noted yet.").
