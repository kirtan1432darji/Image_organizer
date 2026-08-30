import 'package:flutter/material.dart';

class TagModel {
  final String id;
  final String name;
  final String colorHex;

  const TagModel({
    required this.id,
    required this.name,
    this.colorHex = '6366F1',
  });

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  TagModel copyWith({
    String? id,
    String? name,
    String? colorHex,
  }) {
    return TagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_hex': colorHex,
    };
  }

  factory TagModel.fromMap(Map<String, dynamic> map) {
    return TagModel(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['color_hex'] as String? ?? '6366F1',
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory TagModel.fromJson(Map<String, dynamic> json) => TagModel.fromMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
