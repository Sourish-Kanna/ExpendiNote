class Transaction {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final int? categoryId;
  final String? categoryName;
  final String? description;
  final DateTime createdAt;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.categoryId,
    this.categoryName,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'categoryId': categoryId,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      amount: (map['amount'] is int)
          ? (map['amount'] as int).toDouble()
          : (map['amount'] as double? ?? 0.0),
      date: DateTime.parse(map['date'] as String),
      categoryId: map.containsKey('categoryId')
          ? map['categoryId'] as int?
          : null,
      categoryName: map.containsKey('category')
          ? map['category'] as String?
          : null,
      description: map['description'] as String?,
      createdAt: map.containsKey('createdAt') && map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convenience getter to provide a `category` string for UI compatibility
  String get category => categoryName ?? '';
}
