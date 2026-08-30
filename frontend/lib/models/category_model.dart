import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String iconName;
  final String colorHex;
  final String description;
  final bool isSystem;
  final int orderIndex;
  final int screenshotCount;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    this.description = '',
    this.isSystem = true,
    this.orderIndex = 0,
    this.screenshotCount = 0,
  });

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  IconData get icon {
    switch (iconName.toLowerCase()) {
      case 'receipt':
      case 'finance':
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_outlined;
      case 'social':
      case 'chat':
      case 'forum':
        return Icons.chat_bubble_outline;
      case 'code':
      case 'developer_mode':
        return Icons.code_rounded;
      case 'work':
      case 'business_center':
        return Icons.business_center_outlined;
      case 'shopping':
      case 'shopping_cart':
        return Icons.shopping_bag_outlined;
      case 'travel':
      case 'flight':
        return Icons.flight_takeoff_outlined;
      case 'meme':
      case 'sentiment_satisfied':
        return Icons.sentiment_satisfied_alt_outlined;
      case 'notes':
      case 'description':
        return Icons.description_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? iconName,
    String? colorHex,
    String? description,
    bool? isSystem,
    int? orderIndex,
    int? screenshotCount,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      description: description ?? this.description,
      isSystem: isSystem ?? this.isSystem,
      orderIndex: orderIndex ?? this.orderIndex,
      screenshotCount: screenshotCount ?? this.screenshotCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'color_hex': colorHex,
      'description': description,
      'is_system': isSystem ? 1 : 0,
      'order_index': orderIndex,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, [int count = 0]) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      iconName: map['icon_name'] as String? ?? 'folder',
      colorHex: map['color_hex'] as String? ?? '6366F1',
      description: map['description'] as String? ?? '',
      isSystem: (map['is_system'] as int? ?? 1) == 1,
      orderIndex: map['order_index'] as int? ?? 0,
      screenshotCount: count,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      CategoryModel.fromMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
