class Category {
  final int? id;
  final String name;
  final String? icon;
  final int? color;
  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;

  Category({
    this.id,
    required this.name,
    this.icon,
    this.color,
    this.isPinned = false,
    this.isArchived = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'isPinned': isPinned ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      icon: map['icon'] as String?,
      color: map['color'] as int?,
      isPinned: (map['isPinned'] == 1),
      isArchived: (map['isArchived'] == 1),
      createdAt: map.containsKey('createdAt') && map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
