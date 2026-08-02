class Setting {
  final String key;
  final String? value;

  Setting({required this.key, this.value});

  Map<String, dynamic> toMap() => {'key': key, 'value': value};

  factory Setting.fromMap(Map<String, dynamic> map) {
    return Setting(key: map['key'] as String, value: map['value'] as String?);
  }
}
