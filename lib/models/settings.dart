import 'package:flutter/foundation.dart';

@immutable
class Setting {
  final String key;
  final String? value;

  const Setting({required this.key, this.value});

  Map<String, dynamic> toMap() => {'key': key, 'value': value};

  factory Setting.fromMap(Map<String, dynamic> map) {
    return Setting(key: map['key'] as String, value: map['value'] as String?);
  }

  /// Typed getters for value conversion
  bool get boolValue => value?.toLowerCase() == 'true';
  int? get intValue => value != null ? int.tryParse(value!) : null;
  double? get doubleValue => value != null ? double.tryParse(value!) : null;

  Setting copyWith({String? key, String? value}) {
    return Setting(key: key ?? this.key, value: value ?? this.value);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Setting && other.key == key && other.value == value;
  }

  @override
  int get hashCode => Object.hash(key, value);
}
