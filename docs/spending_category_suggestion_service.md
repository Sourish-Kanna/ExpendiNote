# Spending Category Suggestion Service

## Overview

The `CategorySuggestionService` provides a lightweight, local, rule-based recommendation system for ExpendiNote. It analyzes a transaction's **Title** and optional **Description** to suggest an appropriate existing category.

Key principles:
- **Local & Lightweight**: Pure Dart/Flutter logic without external ML or network APIs.
- **Strict User Category Constraint**: Suggestions only map to categories currently available to the user (non-archived). No categories are created automatically.
- **Deterministic Rule Engine**: Normalizes input text and evaluates confidence using word/phrase rule mappings.
- **75% Reliability Threshold**: Suggestions are only displayed when confidence meets or exceeds `0.75` (75%).

---

## Result Model: `CategorySuggestionResult`

Located in `lib/models/category_suggestion_result.dart`.

### Fields

| Field | Type | Description |
|---|---|---|
| `category` | `Category?` | Suggested existing category model instance, or `null`. |
| `confidence` | `double` | Score between `0.0` and `1.0`. |
| `matchedReason` | `String` | Explanation of why the category was matched. |
| `matchedKeywords` | `List<String>` | Keywords or phrases that contributed to the score. |
| `isReliable` | `bool` | `true` if `confidence >= 0.75`. |
| `isCleared` | `bool` | `true` if explicitly cleared by the user. |
| `hasSuggestion` | `bool` | Convenience getter: `category != null && isReliable && !isCleared && confidence >= 0.75`. |

### Constructors & Factories

```dart
// Standard constructor
const CategorySuggestionResult({
  this.category,
  this.confidence = 0.0,
  this.matchedReason = '',
  this.matchedKeywords = const [],
  this.isReliable = false,
  this.isCleared = false,
});

// Empty result
factory CategorySuggestionResult.none();

// Cleared result
factory CategorySuggestionResult.cleared();
```

---

## Service API: `CategorySuggestionService`

Located in `lib/services/category_suggestion_service.dart`.

### Async Suggestion

```dart
Future<CategorySuggestionResult> suggestCategory({
  required String title,
  String? description,
  List<Category>? availableCategories,
});
```
Queries non-archived categories via `CategoryRepository.getAllCategories()` (if `availableCategories` is omitted) and returns the top reliable suggestion.

### Sync Suggestion

```dart
CategorySuggestionResult suggestCategorySync({
  required String title,
  String? description,
  required List<Category> availableCategories,
});
```
Evaluates suggestion synchronously using a pre-loaded list of categories.

### Clear / Accept / Reject Helper Contracts

```dart
CategorySuggestionResult clearSuggestion();
CategorySuggestionResult acceptSuggestion(CategorySuggestionResult result);
CategorySuggestionResult rejectSuggestion(CategorySuggestionResult result);
```

---

## Normalization & Matching Rules

1. **Text Normalization**:
   - Case-insensitive (`toLowerCase()`).
   - Trim leading/trailing whitespace.
   - Non-alphanumeric punctuation replaced with spaces.
   - Contiguous whitespace collapsed into single spaces.

2. **Matching Strategy**:
   - **Exact Category Name**: 1.0 confidence (100%).
   - **Rule Phrase Match in Title**: 0.88 confidence.
   - **Rule Keyword Match in Title**: 0.80+ confidence.
   - **Description Match**: 0.35 - 0.50 confidence.
   - **Combined Title + Description**: +0.10 boost if matching same category.
   - **Ambiguity Filter**: If top two category candidate scores differ by < 0.05, no suggestion is returned to prevent incorrect force-matching.

---

## UI Integration Contract Guide

To integrate the `CategorySuggestionService` with an entry form (e.g., `AddSpendingScreen`):

### 1. Initialize Service & State

```dart
final _suggestionService = CategorySuggestionService();
CategorySuggestionResult _currentSuggestion = CategorySuggestionResult.none();
```

### 2. Evaluate Suggestions on Input Change

When the user types in the title or description text fields:

```dart
void _onInputChanged() {
  final title = _titleController.text;
  final description = _descriptionController.text;

  final result = _suggestionService.suggestCategorySync(
    title: title,
    description: description,
    availableCategories: _categories,
  );

  setState(() {
    _currentSuggestion = result;
  });
}
```

### 3. Display Suggestion Banner or Chip

Show the suggested category chip or banner when `_currentSuggestion.hasSuggestion` is true:

```dart
if (_currentSuggestion.hasSuggestion)
  ActionChip(
    avatar: const Icon(Icons.lightbulb_outline, size: 18),
    label: Text('Suggest: ${_currentSuggestion.category!.name}'),
    onPressed: _acceptSuggestion,
  );
```

### 4. Handle Actions

- **Accept Suggestion**: Select `_currentSuggestion.category` as active category.
- **Reject / Clear Suggestion**:
  ```dart
  void _clearSuggestion() {
    setState(() {
      _currentSuggestion = _suggestionService.clearSuggestion();
    });
  }
  ```
- **User Override**: If user explicitly taps a category choice chip, their manual selection always overrides the suggestion.
