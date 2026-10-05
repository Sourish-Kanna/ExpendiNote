### Project Design System & Visual Guidelines

1. Background & Safe Area:
    - Root Scaffold background MUST be `colorScheme.surface`.
    - Never add a local `SafeArea` widget inside individual screens. The app already has a global `SafeArea` inside `MaterialApp.builder` in `lib/main.dart` with a full-bleed themed background.

2. Card & Container Architecture:
    - All `Card` widgets MUST use `elevation: 0`.
    - Corner Radii:
        - Primary metric / highlight summary cards: `BorderRadius.circular(28)`
        - Grouped container / section cards: `BorderRadius.circular(24)`
        - List item cards: `BorderRadius.circular(16)`
        - Small tags / badge containers: `BorderRadius.circular(12)`
    - Background Tints:
        - App overview / summary cards: `colorScheme.primaryContainer.withValues(alpha: 0.3)`
        - Neutral group cards: `colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)`
        - Category-associated cards/items: Use the category's own color with low opacity: `catColor.withValues(alpha: 0.12)`. Selected state uses `catColor.withValues(alpha: 0.2)` with a 2px `catColor` border.

3. Typography & Text Hierarchy:
    - Bold, modern, and high contrast.
    - Screen AppBars: `textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)` with `scrolledUnderElevation: 0`.
    - Section headers: Bold label style (`textTheme.titleMedium` or `textTheme.labelLarge` with `fontWeight.bold`).
    - Primary metric numbers: `textTheme.displayMedium` or `textTheme.headlineMedium` with `fontWeight.bold`.
    - List item titles: `textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)`.

4. Iconography:
    - Always use FILLED Material icons (e.g. `Icons.calendar_today`, `Icons.analytics`, `Icons.share`, `Icons.delete`, `Icons.edit`, `Icons.settings`, `Icons.category`, `Icons.chevron_right`).
    - Do NOT use `_outlined` icon variants.
    - When displaying category icons, render them directly in the category's custom color (`catColor`) rather than wrapping them inside heavy CircleAvatars.

5. Spacing Philosophy:
    - Standard screen padding: `EdgeInsets.symmetric(horizontal: 16, vertical: 12)`.
    - Spacing between related cards / items: `8dp` to `12dp`.
    - Spacing between major sections: `20dp` to `28dp`.

---

### Primary Visual Reference Files:
- `lib/screens/new_home_screen.dart` (Main reference for cards, metric summary banners, and list tiles)
- `lib/screens/add_spending_screen.dart` (Reference for primary metric cards and form inputs)
- `lib/screens/spending_detail_screen.dart` (Reference for category-tinted cards and plain detail rows)
- `lib/screens/category_management_screen.dart` (Reference for category item styling)

### Constraints:
- Do NOT alter any business logic, calculations, date formatting, database schema, or repository methods.
- Preserve all navigation callbacks, arguments, and `refreshNotifier` hooks.
- After making changes, run `flutter analyze` and ensure 0 errors or warnings.