import '../models/category.dart';
import '../models/category_suggestion_result.dart';
import '../repositories/category_repository.dart';

/// A lightweight, local, rule-based service for suggesting an existing spending
/// category based on a transaction's title and optional description.
class CategorySuggestionService {
  /// Default reliability threshold required to display a suggestion.
  static const double minConfidenceThreshold = CategorySuggestionResult.reliabilityThreshold;

  /// Suggests an existing category asynchronously by querying available categories.
  Future<CategorySuggestionResult> suggestCategory({
    required String title,
    String? description,
    List<Category>? availableCategories,
  }) async {
    final categories = availableCategories ??
        await CategoryRepository.getAllCategories(includeArchived: false);

    return suggestCategorySync(
      title: title,
      description: description,
      availableCategories: categories,
    );
  }

  /// Suggests an existing category synchronously from a provided list of categories.
  CategorySuggestionResult suggestCategorySync({
    required String title,
    String? description,
    required List<Category> availableCategories,
  }) {
    // 1. Filter available categories (exclude archived)
    final validCategories = availableCategories
        .where((cat) => !cat.isArchived)
        .toList();

    if (validCategories.isEmpty) {
      return CategorySuggestionResult.none();
    }

    // 2. Normalize text inputs
    final normalizedTitle = normalizeText(title);
    final normalizedDescription = normalizeText(description ?? '');

    if (normalizedTitle.isEmpty && normalizedDescription.isEmpty) {
      return CategorySuggestionResult.none();
    }

    // 3. Evaluate candidate scores for each category
    final candidateScores = <Category, _CategoryScore>{};

    for (final category in validCategories) {
      final score = _evaluateCategory(
        category: category,
        title: normalizedTitle,
        description: normalizedDescription,
      );

      if (score.confidence > 0.0) {
        candidateScores[category] = score;
      }
    }

    if (candidateScores.isEmpty) {
      return CategorySuggestionResult.none();
    }

    // 4. Find highest candidate score
    final sortedCandidates = candidateScores.entries.toList()
      ..sort((a, b) => b.value.confidence.compareTo(a.value.confidence));

    final topCandidate = sortedCandidates.first;
    final topScore = topCandidate.value;

    // Check for ambiguity (e.g. tie or very close top two candidates)
    if (sortedCandidates.length > 1) {
      final secondScore = sortedCandidates[1].value;
      if (topScore.confidence - secondScore.confidence < 0.05 &&
          topScore.confidence < 0.90) {
        // Ambiguous match, do not force a suggestion
        return CategorySuggestionResult.none();
      }
    }

    // 5. Evaluate reliability against threshold
    final isReliable = topScore.confidence >= minConfidenceThreshold;

    if (!isReliable) {
      return CategorySuggestionResult.none();
    }

    final reason = topScore.buildReason(topCandidate.key.name);

    return CategorySuggestionResult(
      category: topCandidate.key,
      confidence: topScore.confidence,
      matchedReason: reason,
      matchedKeywords: topScore.matchedKeywords.toList(),
      isReliable: true,
      isCleared: false,
    );
  }

  /// Helper contract method to clear a suggestion result.
  CategorySuggestionResult clearSuggestion() {
    return CategorySuggestionResult.cleared();
  }

  /// Helper contract method to accept a suggestion result.
  CategorySuggestionResult acceptSuggestion(CategorySuggestionResult result) {
    if (!result.hasSuggestion) return result;
    return result;
  }

  /// Helper contract method to reject a suggestion result.
  CategorySuggestionResult rejectSuggestion(CategorySuggestionResult result) {
    return CategorySuggestionResult.cleared();
  }

  /// Normalizes input string for matching:
  /// - Trim whitespace
  /// - Lowercase
  /// - Replace non-alphanumeric punctuation with spaces
  /// - Collapse contiguous spaces
  static String normalizeText(String text) {
    if (text.isEmpty) return '';
    final cleaned = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned;
  }

  /// Internal evaluation function for a category.
  _CategoryScore _evaluateCategory({
    required Category category,
    required String title,
    required String description,
  }) {
    final matchedKeywords = <String>{};
    double titleScore = 0.0;
    double descriptionScore = 0.0;

    final catNameNormalized = normalizeText(category.name);

    // Check exact name match in title
    if (catNameNormalized.isNotEmpty && title == catNameNormalized) {
      return _CategoryScore(
        confidence: 1.0,
        matchedKeywords: {category.name},
        matchedInTitle: true,
        matchedInDescription: false,
      );
    }

    // Gather rule keywords for standard category concepts
    final ruleKeywords = _getRuleKeywordsForCategory(category.name);

    // If custom category name itself appears as a phrase or word in title
    if (catNameNormalized.length > 2 &&
        _containsPhrase(title, catNameNormalized)) {
      matchedKeywords.add(category.name);
      titleScore = 0.88;
    }

    // Evaluate rule phrases/keywords in Title
    for (final phrase in ruleKeywords.phrases) {
      if (_containsPhrase(title, phrase)) {
        matchedKeywords.add(phrase);
        titleScore = titleScore < 0.88 ? 0.88 : titleScore;
      }
    }

    for (final word in ruleKeywords.words) {
      if (_containsWord(title, word)) {
        matchedKeywords.add(word);
        titleScore = titleScore < 0.80 ? 0.80 : titleScore + 0.02;
      }
    }

    // Cap title score
    if (titleScore > 0.95) titleScore = 0.95;

    // Evaluate in Description
    if (description.isNotEmpty) {
      for (final phrase in ruleKeywords.phrases) {
        if (_containsPhrase(description, phrase)) {
          matchedKeywords.add(phrase);
          descriptionScore = descriptionScore < 0.50 ? 0.50 : descriptionScore;
        }
      }

      for (final word in ruleKeywords.words) {
        if (_containsWord(description, word)) {
          matchedKeywords.add(word);
          descriptionScore = descriptionScore < 0.35 ? 0.35 : descriptionScore;
        }
      }
    }

    // Calculate combined confidence
    double finalScore = 0.0;
    bool matchedInTitle = titleScore > 0.0;
    bool matchedInDesc = descriptionScore > 0.0;

    if (matchedInTitle && matchedInDesc) {
      finalScore = (titleScore + 0.10).clamp(0.0, 0.98);
    } else if (matchedInTitle) {
      finalScore = titleScore;
    } else if (matchedInDesc) {
      // Description-only match is capped below threshold unless very strong
      finalScore = descriptionScore;
    }

    return _CategoryScore(
      confidence: finalScore,
      matchedKeywords: matchedKeywords,
      matchedInTitle: matchedInTitle,
      matchedInDescription: matchedInDesc,
    );
  }

  bool _containsPhrase(String text, String phrase) {
    if (text.isEmpty || phrase.isEmpty) return false;
    return text.contains(phrase);
  }

  bool _containsWord(String text, String word) {
    if (text.isEmpty || word.isEmpty) return false;
    final words = text.split(' ');
    return words.contains(word);
  }

  /// Maps standard category names to rule phrase and word keywords.
  _CategoryRules _getRuleKeywordsForCategory(String categoryName) {
    final lowerName = categoryName.toLowerCase().trim();

    if (lowerName.contains('transport') || lowerName.contains('travel') || lowerName.contains('commute')) {
      return const _CategoryRules(
        phrases: [
          'petrol pump', 'train ticket', 'bus ticket',
          'cab fare', 'flight ticket', 'ola cab', 'uber ride', 'auto fare'
        ],
        words: [
          'bus', 'train', 'metro', 'cab', 'taxi', 'uber', 'auto', 'fuel',
          'petrol', 'diesel', 'fare', 'flight', 'airline', 'commute',
          'ola', 'lyft', 'rapido', 'toll', 'parking', 'ticket'
        ],
      );
    }

    if (lowerName.contains('food') || lowerName.contains('restaurant') || lowerName.contains('dining')) {
      return const _CategoryRules(
        phrases: [
          'swiggy order', 'zomato order', 'eating out', 'coffee shop',
          'fast food', 'food order', 'fine dining'
        ],
        words: [
          'restaurant', 'food', 'lunch', 'dinner', 'breakfast', 'snacks',
          'meal', 'cafe', 'coffee', 'tea', 'swiggy', 'zomato', 'bakery',
          'grocery', 'groceries', 'supermarket', 'dining', 'pizza', 'burger'
        ],
      );
    }

    if (lowerName.contains('shop') || lowerName.contains('store')) {
      return const _CategoryRules(
        phrases: [
          'online shopping', 'amazon pay', 'amazon order', 'clothes shopping'
        ],
        words: [
          'amazon', 'shopping', 'clothes', 'shoes', 'flipkart', 'myntra',
          'clothing', 'apparel', 'mall', 'store', 'purchase', 'electronics'
        ],
      );
    }

    if (lowerName.contains('health') || lowerName.contains('medical') || lowerName.contains('care')) {
      return const _CategoryRules(
        phrases: [
          'health checkup', 'doctor fee', 'medical store', 'lab test', 'dental clinic'
        ],
        words: [
          'medicine', 'pharmacy', 'doctor', 'hospital', 'clinic', 'medical',
          'chemist', 'health', 'prescription', 'dental'
        ],
      );
    }

    if (lowerName.contains('bill') || lowerName.contains('utility')) {
      return const _CategoryRules(
        phrases: [
          'electricity bill', 'water bill', 'gas bill', 'mobile bill',
          'internet bill', 'mobile recharge', 'tv recharge', 'power bill'
        ],
        words: [
          'electricity', 'internet', 'recharge', 'wifi', 'utility', 'postpaid',
          'prepaid', 'broadband', 'subscription'
        ],
      );
    }

    if (lowerName.contains('entertain') || lowerName.contains('movie')) {
      return const _CategoryRules(
        phrases: ['movie ticket', 'prime video', 'cinema ticket'],
        words: [
          'movie', 'cinema', 'netflix', 'spotify', 'concert', 'game',
          'gaming', 'theater', 'show', 'hotstar', 'disney'
        ],
      );
    }

    if (lowerName.contains('educat') || lowerName.contains('school') || lowerName.contains('study')) {
      return const _CategoryRules(
        phrases: ['school fee', 'college fee', 'tuition fee', 'exam fee'],
        words: [
          'tuition', 'school', 'college', 'course', 'udemy', 'book', 'books',
          'fee', 'fees', 'stationery', 'stationeries'
        ],
      );
    }

    if (lowerName.contains('hous') || lowerName.contains('rent') || lowerName.contains('home')) {
      return const _CategoryRules(
        phrases: ['house rent', 'room rent', 'maintenance fee'],
        words: ['rent', 'maintenance', 'lease', 'mortgage', 'furniture', 'repair'],
      );
    }

    if (lowerName.contains('invest')) {
      return const _CategoryRules(
        phrases: ['mutual fund', 'fixed deposit', 'stock market'],
        words: ['stock', 'sip', 'equity', 'share', 'crypto', 'bond', 'gold', 'fd'],
      );
    }

    if (lowerName.contains('income') || lowerName.contains('salary')) {
      return const _CategoryRules(
        phrases: ['salary credit', 'freelance payment'],
        words: ['salary', 'bonus', 'dividend', 'interest', 'cashback', 'refund', 'freelance'],
      );
    }

    return const _CategoryRules(phrases: [], words: []);
  }
}

class _CategoryRules {
  final List<String> phrases;
  final List<String> words;

  const _CategoryRules({required this.phrases, required this.words});
}

class _CategoryScore {
  final double confidence;
  final Set<String> matchedKeywords;
  final bool matchedInTitle;
  final bool matchedInDescription;

  _CategoryScore({
    required this.confidence,
    required this.matchedKeywords,
    required this.matchedInTitle,
    required this.matchedInDescription,
  });

  String buildReason(String categoryName) {
    final keywordsStr = matchedKeywords.join(', ');
    if (matchedInTitle && matchedInDescription) {
      return 'Matched "$keywordsStr" in title and description for $categoryName';
    } else if (matchedInTitle) {
      return 'Matched "$keywordsStr" in title for $categoryName';
    } else {
      return 'Matched "$keywordsStr" in description for $categoryName';
    }
  }
}
