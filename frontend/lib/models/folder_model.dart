import 'package:flutter/material.dart';

class FolderModel {
  final String id;
  final String name;
  final String icon;
  final bool isDefault;
  final DateTime createdAt;
  final int itemCount;

  const FolderModel({
    required this.id,
    required this.name,
    this.icon = 'folder',
    this.isDefault = false,
    required this.createdAt,
    this.itemCount = 0,
  });

  IconData get iconData {
    switch (icon.toLowerCase()) {
      case 'star':
        return Icons.star_rounded;
      case 'receipt':
        return Icons.receipt_long_rounded;
      case 'work':
        return Icons.work_outline_rounded;
      case 'code':
        return Icons.code_rounded;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'archive':
        return Icons.archive_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  FolderModel copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isDefault,
    DateTime? createdAt,
    int? itemCount,
  }) {
    return FolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FolderModel.fromMap(Map<String, dynamic> map, [int count = 0]) {
    return FolderModel(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? 'folder',
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      itemCount: count,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory FolderModel.fromJson(Map<String, dynamic> json) =>
      FolderModel.fromMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FolderModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
