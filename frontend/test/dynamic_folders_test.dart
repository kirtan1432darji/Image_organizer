import 'package:flutter_test/flutter_test.dart';
import 'package:ai_screenshot_organizer/models/category_model.dart';
import 'package:ai_screenshot_organizer/core/services/media_classifier.dart';

void main() {
  group('CategoryModel Hierarchy Tests', () {
    test('supports parentId, isRoot, and hasSubfolders', () {
      const root = CategoryModel(
        id: 'cat-projects',
        name: 'Projects',
        iconName: 'folder_special',
        colorHex: '#6366F1',
        parentId: null,
      );

      const child = CategoryModel(
        id: 'cat-nhdc',
        name: 'NHDC',
        iconName: 'folder',
        colorHex: '#6366F1',
        parentId: 'cat-projects',
      );

      const grandChild = CategoryModel(
        id: 'cat-payroll',
        name: 'Payroll',
        iconName: 'payments',
        colorHex: '#6366F1',
        parentId: 'cat-nhdc',
      );

      expect(root.isRoot, isTrue);
      expect(child.isRoot, isFalse);
      expect(grandChild.parentId, 'cat-nhdc');

      final rootWithChildren = root.copyWith(subCategories: [child]);
      expect(rootWithChildren.hasSubfolders, isTrue);
    });

    test('serializes and deserializes parent_id in SQLite map', () {
      final map = {
        'id': 'cat-shoes',
        'name': 'Shoes',
        'icon_name': 'roller_skating',
        'color_hex': '#EC4899',
        'description': 'Smart folder for Shoes',
        'is_system': 0,
        'order_index': 0,
        'parent_id': 'cat-shopping',
      };

      final category = CategoryModel.fromMap(map, 8);
      expect(category.id, 'cat-shoes');
      expect(category.name, 'Shoes');
      expect(category.parentId, 'cat-shopping');
      expect(category.screenshotCount, 8);

      final exported = category.toMap();
      expect(exported['parent_id'], 'cat-shopping');
    });
  });

  group('MediaClassifier Dynamic Smart Folder Hierarchy Tests', () {
    const classifier = MediaClassifier();

    test('classifies WhatsApp NHDC payroll screenshot to Projects -> NHDC -> Payroll', () {
      final result = classifier.classifyMediaItem(
        filePath: '/storage/emulated/0/Pictures/Screenshots/Screenshot_20260904_WhatsApp_NHDC.jpg',
        ocrText: 'WhatsApp Group: NHDC Project\nMonthly salary slip and payroll breakdown.\nTotal payout disbursed: \$4,500',
      );

      expect(result.folderPath, contains('Projects'));
      expect(result.folderPath, contains('Payroll'));
      expect(result.folderPath.length, greaterThanOrEqualTo(2));
    });

    test('classifies Amazon shoe screenshot to Shopping -> Shoes', () {
      final result = classifier.classifyMediaItem(
        filePath: '/storage/emulated/0/Pictures/Screenshots/Screenshot_Amazon_Nike.png',
        ocrText: 'Amazon.com: Nike Air Zoom Running Shoes Sneakers\nOrder placed successfully.\nTotal Price: \$129.99',
      );

      expect(result.folderPath, equals(['Shopping', 'Shoes']));
      expect(result.categoryName, 'Shopping');
      expect(result.subcategory, 'Shoes');
    });

    test('classifies Flutter tutorial screenshot to Learning -> Flutter', () {
      final result = classifier.classifyMediaItem(
        filePath: '/storage/emulated/0/Pictures/Screenshots/Screenshot_Youtube_Flutter.png',
        ocrText: 'YouTube: Flutter Tutorial 2026 - State Management with Riverpod Course Lecture',
      );

      expect(result.folderPath, equals(['Learning', 'Flutter']));
      expect(result.categoryName, 'Learning');
      expect(result.subcategory, 'Flutter');
    });

    test('classifies flight ticket screenshot to Travel -> Flights', () {
      final result = classifier.classifyMediaItem(
        filePath: '/storage/emulated/0/Pictures/Screenshots/Screenshot_Indigo_BoardingPass.png',
        ocrText: 'IndiGo Boarding Pass. Flight 6E-204 from DEL to BOM. Seat 14B. Gate 3.',
      );

      expect(result.folderPath, equals(['Travel', 'Flights']));
      expect(result.categoryName, 'Travel');
      expect(result.subcategory, 'Flights');
    });

    test('classifies code repository screenshot to Code & Tech -> Dart', () {
      final result = classifier.classifyMediaItem(
        filePath: '/storage/emulated/0/Pictures/Screenshots/Screenshot_GitHub_Repo.png',
        ocrText: 'github.com/repository/pull/42/service.dart\nclass ScreenshotScannerService extends StateNotifier\nFuture<void> scanMediaItems() async',
      );

      expect(result.folderPath.first, 'Code & Tech');
      expect(result.folderPath, contains('Dart'));
    });

    test('does NOT lock unclassified text to Notes & Knowledge', () {
      final result = classifier.classifyMediaItem(
        filePath: '/storage/emulated/0/Pictures/Screenshots/Screenshot_Random_Recipe.png',
        ocrText: 'Homemade Neapolitan Pizza Dough Recipe with active dry yeast and olive oil',
      );

      expect(result.folderPath, isNot(contains('Notes & Knowledge')));
      expect(result.folderPath.isNotEmpty, isTrue);
    });
  });
}
