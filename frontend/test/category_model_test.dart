import 'package:flutter_test/flutter_test.dart';
import 'package:ai_screenshot_organizer/models/category_model.dart';

void main() {
  group('CategoryModel Canonical ID & Count Tests', () {
    test('parses SQL Server backend CategoryDto format with GUID', () {
      final backendJson = {
        'id': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
        'name': 'Receipts & Invoices',
        'icon': 'receipt',
        'color': '#4CAF50',
        'description': 'Payment receipts and invoices',
        'createdByAI': false,
        'displayOrder': 1,
      };

      final category = CategoryModel.fromJson(backendJson);
      expect(category.id, '3fa85f64-5717-4562-b3fc-2c963f66afa6');
      expect(category.name, 'Receipts & Invoices');
      expect(category.iconName, 'receipt');
      expect(category.colorHex, '#4CAF50');
      expect(category.isSystem, isTrue);
      expect(category.orderIndex, 1);
    });

    test('parses SQLite database category row format', () {
      final dbRow = {
        'id': 'd290f1ee-6c54-4b01-90e6-d701748f0851',
        'name': 'Social & Chat',
        'icon_name': 'chat',
        'color_hex': '3B82F6',
        'description': 'Chat screenshots',
        'is_system': 1,
        'order_index': 2,
      };

      final category = CategoryModel.fromMap(dbRow, 15);
      expect(category.id, 'd290f1ee-6c54-4b01-90e6-d701748f0851');
      expect(category.name, 'Social & Chat');
      expect(category.screenshotCount, 15);
      expect(category.isSystem, isTrue);
    });

    test('provides canonical Unsorted category with stable ID', () {
      expect(CategoryModel.unsortedCategory.id, 'unsorted');
      expect(CategoryModel.unsortedCategory.name, 'Unsorted');
      expect(CategoryModel.unsortedCategory.isSystem, isTrue);
    });

    test('copyWith properly updates screenshot count', () {
      final cat = CategoryModel.unsortedCategory.copyWith(screenshotCount: 42);
      expect(cat.screenshotCount, 42);
      expect(cat.id, 'unsorted');
    });
  });
}
