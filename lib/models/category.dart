import 'package:flutter/foundation.dart';

import '../constants/database_constants.dart';

@immutable
class Category {
  final int? id;
  final String name;
  final String? icon;
  final int? color;
  final bool isPinned;
  final bool isArchived;
  final bool includeInSpendingAnalysis;
  final DateTime createdAt;

  Category({
    this.id,
    required this.name,
    this.icon,
    this.color,
    this.isPinned = false,
    this.isArchived = false,
    this.includeInSpendingAnalysis = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Converts model instance to SQLite v2 column map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) DbCols.id: id,
      DbCols.name: name,
      DbCols.icon: icon,
      DbCols.color: color,
      DbCols.isPinned: isPinned ? 1 : 0,
      DbCols.isArchived: isArchived ? 1 : 0,
      DbCols.includeInSpendingAnalysis: includeInSpendingAnalysis ? 1 : 0,
      DbCols.createdAt: createdAt.toIso8601String(),
    };
  }

  /// Constructs a Category instance from SQLite database row.
  factory Category.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic rawDate) {
      if (rawDate is String) {
        return DateTime.tryParse(rawDate) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final rawInclude = map[DbCols.includeInSpendingAnalysis];

    return Category(
      id: map[DbCols.id] as int?,
      name: map[DbCols.name] as String? ?? '',
      icon: map[DbCols.icon] as String?,
      color: map[DbCols.color] as int?,
      isPinned: map[DbCols.isPinned] == 1 || map[DbCols.isPinned] == true,
      isArchived: map[DbCols.isArchived] == 1 || map[DbCols.isArchived] == true,
      includeInSpendingAnalysis: rawInclude == null
          ? true
          : (rawInclude == 1 || rawInclude == true),
      createdAt: parseDate(map[DbCols.createdAt]),
    );
  }

  Category copyWith({
    int? id,
    String? name,
    String? icon,
    int? color,
    bool? isPinned,
    bool? isArchived,
    bool? includeInSpendingAnalysis,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      includeInSpendingAnalysis:
          includeInSpendingAnalysis ?? this.includeInSpendingAnalysis,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.icon == icon &&
        other.color == color &&
        other.isPinned == isPinned &&
        other.isArchived == isArchived &&
        other.includeInSpendingAnalysis == includeInSpendingAnalysis &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      icon,
      color,
      isPinned,
      isArchived,
      includeInSpendingAnalysis,
      createdAt,
    );
  }
}
