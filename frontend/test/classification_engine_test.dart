import 'package:flutter_test/flutter_test.dart';
import 'package:ai_screenshot_organizer/models/classification_result_model.dart';
import 'package:ai_screenshot_organizer/core/services/media_classifier.dart';

void main() {
  group('ClassificationResultModel Sprint 1.3 Tests', () {
    test('serializes and deserializes folderPath, keywords, detectedApp', () {
      final json = {
        'screenshot_id': 'ss-12345',
        'category_id': 'cat-shopping',
        'category_name': 'Shopping',
        'subcategory_id': 'cat-shoes',
        'subcategory': 'Shoes',
        'folder_path': ['Shopping', 'Shoes'],
        'confidence': 0.95,
        'source_app': 'Amazon',
        'detected_app': 'Amazon',
        'suggested_tags': ['shoes', 'sneakers'],
        'keywords': ['Nike', 'Air', 'Zoom', 'Shoes'],
        'summary': 'Amazon shoe order',
        'is_auto_categorized': true,
      };

      final model = ClassificationResultModel.fromJson(json);

      expect(model.screenshotId, 'ss-12345');
      expect(model.categoryName, 'Shopping');
      expect(model.subcategory, 'Shoes');
      expect(model.folderPath, equals(['Shopping', 'Shoes']));
      expect(model.detectedApp, 'Amazon');
      expect(model.keywords, contains('Nike'));
      expect(model.isAutoCategorized, isTrue);

      final exported = model.toJson();
      expect(exported['folder_path'], equals(['Shopping', 'Shoes']));
      expect(exported['detected_app'], 'Amazon');
      expect(exported['is_auto_categorized'], isTrue);
    });

    test('handles backend CategoryDto without subcategory_id gracefully', () {
      final backendJson = {
        'screenshot_id': 'ss-999',
        'category_id': 'cat-learning',
        'category_name': 'Learning',
        'sub_category_name': 'Flutter',
        'folder_path': ['Learning', 'Flutter'],
        'confidence': 0.94,
        'source_app': 'YouTube',
      };

      final model = ClassificationResultModel.fromJson(backendJson);
      expect(model.categoryName, 'Learning');
      expect(model.subcategory, 'Flutter');
      expect(model.folderPath, equals(['Learning', 'Flutter']));
      expect(model.detectedApp, 'YouTube');
    });
  });

  group('Classification Engine Expected Examples Verification', () {
    const classifier = MediaClassifier();

    test('WhatsApp payroll screenshot -> Projects -> NHDC -> Payroll', () {
      final result = classifier.classifyMediaItem(
        filePath: '/storage/emulated/0/Pictures/Screenshots/Screenshot_WhatsApp_NHDC.jpg',
        ocrText: 'WhatsApp Group: NHDC Project\nMonthly salary slip and payroll breakdown.\nTotal payout disbursed: \$4,500',
        sourceApp: 'WhatsApp',
      );

      expect(result.folderPath, contains('Projects'));
      expect(result.folderPath, contains('Payroll'));
      expect(result.categoryName, 'Projects');
    });

    test('Amazon shoes screenshot -> Shopping -> Shoes', () {
      final result = classifier.classifyMediaItem(
        filePath: '/storage/emulated/0/Pictures/Screenshots/Screenshot_Amazon.png',
        ocrText: 'Amazon.com: Nike Air Zoom Running Shoes Sneakers\nOrder placed successfully.\nTotal Price: \$129.99',
        sourceApp: 'Amazon',
      );

      expect(result.folderPath, equals(['Shopping', 'Shoes']));
      expect(result.categoryName, 'Shopping');
      expect(result.subcategory, 'Shoes');
    });

    test('Flutter tutorial screenshot -> Learning -> Flutter', () {
      final result = classifier.classifyMediaItem(
        filePath: '/storage/emulated/0/Pictures/Screenshots/Screenshot_YouTube.png',
        ocrText: 'YouTube: Flutter Tutorial 2026 - State Management with Riverpod Course Lecture',
        sourceApp: 'YouTube',
      );

      expect(result.folderPath, equals(['Learning', 'Flutter']));
      expect(result.categoryName, 'Learning');
      expect(result.subcategory, 'Flutter');
    });

    test('UPI payment screenshot -> Finance -> Payments', () {
      final result = classifier.classifyMediaItem(
        filePath: '/storage/emulated/0/Pictures/Screenshots/Screenshot_GPay.png',
        ocrText: 'Google Pay: Paid to Merchant. UPI Transaction ID: 123456789. Amount: \$45.00',
        sourceApp: 'Google Pay',
      );

      expect(result.folderPath.first, 'Finance');
      expect(result.categoryName, 'Finance');
    });
  });
}
