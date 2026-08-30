import 'package:flutter/foundation.dart';

import '../constants/database_constants.dart';

@immutable
class Transaction {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final int? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final int? categoryColor;
  final String? description;
  final DateTime createdAt;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Converts model instance to SQLite v2 column map for database insertion.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) DbCols.id: id,
      DbCols.title: title,
      DbCols.amount: amount,
      DbCols.date: date.toIso8601String(),
      DbCols.categoryId: categoryId,
      DbCols.description: description,
      DbCols.createdAt: createdAt.toIso8601String(),
    };
  }

  /// Constructs a Transaction instance from SQLite database row.
  factory Transaction.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic rawDate) {
      if (rawDate is String) {
        return DateTime.tryParse(rawDate) ?? DateTime.now();
      }
      return DateTime.now();
    }

    double parseAmount(dynamic rawAmount) {
      if (rawAmount is num) {
        return rawAmount.toDouble();
      }
      if (rawAmount is String) {
        return double.tryParse(rawAmount) ?? 0.0;
      }
      return 0.0;
    }

    return Transaction(
      id: map[DbCols.id] as int?,
      title: map[DbCols.title] as String? ?? '',
      amount: parseAmount(map[DbCols.amount]),
      date: parseDate(map[DbCols.date]),
      categoryId: map[DbCols.categoryId] as int?,
      categoryName:
          map['categoryName'] as String? ??
          map['category'] as String? ??
          map[DbCols.name] as String?,
      categoryIcon:
          map['categoryIcon'] as String? ?? map[DbCols.icon] as String?,
      categoryColor: map['categoryColor'] as int? ?? map[DbCols.color] as int?,
      description: map[DbCols.description] as String?,
      createdAt: parseDate(map[DbCols.createdAt]),
    );
  }

  Transaction copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? date,
    int? categoryId,
    String? categoryName,
    String? categoryIcon,
    int? categoryColor,
    String? description,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction &&
        other.id == id &&
        other.title == title &&
        other.amount == amount &&
        other.date == date &&
        other.categoryId == categoryId &&
        other.categoryName == categoryName &&
        other.categoryIcon == categoryIcon &&
        other.categoryColor == categoryColor &&
        other.description == description &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      amount,
      date,
      categoryId,
      categoryName,
      categoryIcon,
      categoryColor,
      description,
      createdAt,
    );
  }
}
