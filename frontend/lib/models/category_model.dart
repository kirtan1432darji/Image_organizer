import 'package:flutter/material.dart';

class CategoryModel {
  static const String unsortedId = 'unsorted';
  static const String unsortedName = 'Unsorted';

  static const CategoryModel unsortedCategory = CategoryModel(
    id: unsortedId,
    name: unsortedName,
    iconName: 'help_outline',
    colorHex: '94A3B8',
    description: 'Screenshots awaiting AI classification',
    isSystem: true,
    orderIndex: 999,
  );

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
    final lowerIcon = iconName.toLowerCase();
    final lowerName = name.toLowerCase();

    if (lowerIcon.contains('receipt') || lowerName.contains('receipt') || lowerName.contains('invoice')) {
      return Icons.receipt_long_rounded;
    }
    if (lowerIcon.contains('account_balance') || lowerIcon.contains('finance') || lowerName.contains('finance') || lowerName.contains('banking')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (lowerIcon.contains('forum') || lowerIcon.contains('chat') || lowerIcon.contains('social') || lowerName.contains('social') || lowerName.contains('chat')) {
      return Icons.chat_bubble_outline_rounded;
    }
    if (lowerIcon.contains('code') || lowerName.contains('code') || lowerName.contains('tech') || lowerName.contains('dev')) {
      return Icons.code_rounded;
    }
    if (lowerIcon.contains('description') || lowerIcon.contains('document') || lowerName.contains('document') || lowerName.contains('id')) {
      return Icons.description_outlined;
    }
    if (lowerIcon.contains('sentiment') || lowerIcon.contains('meme') || lowerName.contains('meme') || lowerName.contains('humor')) {
      return Icons.sentiment_satisfied_alt_rounded;
    }
    if (lowerIcon.contains('note') || lowerName.contains('note') || lowerName.contains('knowledge')) {
      return Icons.edit_note_rounded;
    }
    if (lowerIcon.contains('shopping') || lowerName.contains('shopping') || lowerName.contains('wishlist')) {
      return Icons.shopping_bag_outlined;
    }
    if (lowerIcon.contains('flight') || lowerIcon.contains('travel') || lowerName.contains('travel') || lowerName.contains('ticket')) {
      return Icons.flight_takeoff_rounded;
    }
    if (lowerIcon.contains('help') || lowerName.contains('unsorted')) {
      return Icons.help_outline_rounded;
    }

    return Icons.folder_outlined;
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
    final rawId = map['id']?.toString() ?? '';
    final rawName = map['name'] as String? ?? '';
    final rawIcon = map['icon_name'] as String? ?? map['icon'] as String? ?? 'folder';
    final rawColor = map['color_hex'] as String? ?? map['color'] as String? ?? '6366F1';
    final rawDesc = map['description'] as String? ?? '';
    final rawOrder = map['order_index'] as int? ?? map['displayOrder'] as int? ?? 0;
    final isSys = map['is_system'] != null 
        ? (map['is_system'] as int? ?? 1) == 1
        : !(map['createdByAI'] as bool? ?? false);

    return CategoryModel(
      id: rawId,
      name: rawName,
      iconName: rawIcon,
      colorHex: rawColor,
      description: rawDesc,
      isSystem: isSys,
      orderIndex: rawOrder,
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
