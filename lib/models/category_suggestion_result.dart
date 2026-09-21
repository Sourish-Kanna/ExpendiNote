import 'package:flutter/foundation.dart';

import 'category.dart';

/// Represents the result of a category suggestion evaluation.
@immutable
class CategorySuggestionResult {
  /// Default reliability threshold for displaying a category suggestion (75%).
  static const double reliabilityThreshold = 0.75;

  /// The suggested category, or null if no matching category was found.
  final Category? category;

  /// Confidence score between 0.0 and 1.0.
  final double confidence;

  /// Human-readable explanation of why this category was suggested.
  final String matchedReason;

  /// List of keywords or phrases that matched during analysis.
  final List<String> matchedKeywords;

  /// Whether the suggestion confidence meets or exceeds the required threshold.
  final bool isReliable;

  /// Whether the user or system explicitly cleared this suggestion.
  final bool isCleared;

  const CategorySuggestionResult({
    this.category,
    this.confidence = 0.0,
    this.matchedReason = '',
    this.matchedKeywords = const [],
    this.isReliable = false,
    this.isCleared = false,
  });

  /// Constructs an empty result indicating no suggestion is available.
  factory CategorySuggestionResult.none() {
    return const CategorySuggestionResult(
      category: null,
      confidence: 0.0,
      matchedReason: 'No matching category found',
      matchedKeywords: [],
      isReliable: false,
      isCleared: false,
    );
  }

  /// Constructs a result representing a cleared suggestion.
  factory CategorySuggestionResult.cleared() {
    return const CategorySuggestionResult(
      category: null,
      confidence: 0.0,
      matchedReason: 'Suggestion cleared by user',
      matchedKeywords: [],
      isReliable: false,
      isCleared: true,
    );
  }

  /// Returns true if a valid, reliable, uncleared suggestion is present.
  bool get hasSuggestion =>
      category != null && isReliable && !isCleared && confidence >= reliabilityThreshold;

  CategorySuggestionResult copyWith({
    Category? category,
    double? confidence,
    String? matchedReason,
    List<String>? matchedKeywords,
    bool? isReliable,
    bool? isCleared,
  }) {
    return CategorySuggestionResult(
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      matchedReason: matchedReason ?? this.matchedReason,
      matchedKeywords: matchedKeywords ?? this.matchedKeywords,
      isReliable: isReliable ?? this.isReliable,
      isCleared: isCleared ?? this.isCleared,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategorySuggestionResult &&
        other.category == category &&
        other.confidence == confidence &&
        other.matchedReason == matchedReason &&
        listEquals(other.matchedKeywords, matchedKeywords) &&
        other.isReliable == isReliable &&
        other.isCleared == isCleared;
  }

  @override
  int get hashCode {
    return Object.hash(
      category,
      confidence,
      matchedReason,
      Object.hashAll(matchedKeywords),
      isReliable,
      isCleared,
    );
  }

  @override
  String toString() {
    return 'CategorySuggestionResult(category: ${category?.name}, confidence: $confidence, isReliable: $isReliable, isCleared: $isCleared, matchedReason: "$matchedReason")';
  }
}
