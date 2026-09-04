import 'package:flutter_test/flutter_test.dart';
import 'package:ai_screenshot_organizer/models/folder_context_model.dart';
import 'package:ai_screenshot_organizer/repositories/folder_context_repository.dart';
import 'package:ai_screenshot_organizer/core/services/api_client.dart';
import 'package:ai_screenshot_organizer/core/utils/result.dart';
import 'package:ai_screenshot_organizer/repositories/screenshot_repository.dart';
import 'package:ai_screenshot_organizer/models/screenshot_model.dart';

class MockApiClient extends ApiClient {
  FolderContextModel? mockContextResponse;
  bool shouldFail = false;

  @override
  Future<Result<FolderContextModel>> fetchFolderContext(String categoryId) async {
    if (shouldFail) {
      return Result.failure('404 Not Found');
    }
    if (mockContextResponse != null) {
      return Result.success(mockContextResponse!);
    }
    return Result.failure('No mock context set');
  }

  @override
  Future<Result<FolderContextModel>> generateFolderContext(String categoryId) async {
    if (shouldFail) {
      return Result.failure('Server Error');
    }
    if (mockContextResponse != null) {
      return Result.success(mockContextResponse!);
    }
    return Result.failure('No mock context set');
  }
}

class MockScreenshotRepository extends ScreenshotRepositoryImpl {
  final List<ScreenshotModel> mockScreenshots;

  MockScreenshotRepository(this.mockScreenshots);

  @override
  Future<List<ScreenshotModel>> getScreenshots({
    String? categoryId,
    bool? isFavorite,
    bool? needsReview,
    int limit = 100,
    int offset = 0,
  }) async {
    return mockScreenshots;
  }
}

void main() {
  group('FolderContextModel JSON Serialization', () {
    test('Correctly serializes and deserializes full context model', () {
      final json = {
        'categoryId': 'finance-123',
        'categoryName': 'Finance & Invoices',
        'summary': 'Invoices and receipts from August 2026 totaling \$1,450.',
        'keywords': ['invoice', 'receipt', 'tax', 'stripe'],
        'confidence': 0.94,
        'screenshotCount': 15,
        'lastUpdatedAt': '2026-08-30T10:00:00.000Z',
        'tasks': [
          {
            'id': 'task-1',
            'title': 'Pay AWS bill by end of month',
            'isCompleted': false,
            'dueDate': '2026-08-31',
          },
          {
            'id': 'task-2',
            'title': 'File GST quarterly return',
            'isCompleted': true,
          }
        ],
        'entities': [
          {'name': 'Stripe', 'type': 'PaymentGateway', 'count': 4},
          {'name': 'John Doe', 'type': 'Person', 'count': 2}
        ],
        'people': ['John Doe', 'Sarah Miller'],
        'links': ['https://dashboard.stripe.com/receipts/123'],
        'dates': [
          {'event': 'AWS Due Date', 'date': 'Aug 31, 2026'}
        ],
        'apps': ['Stripe', 'HDFC Mobile Banking'],
        'topics': ['Taxes', 'Cloud Infrastructure'],
        'timeline': [
          {
            'screenshotId': 'sc-1',
            'title': 'Stripe Invoice #4021',
            'description': 'Payment confirmation for \$249.00',
            'capturedAt': '2026-08-28T14:22:00.000Z',
            'imagePath': '/storage/emulated/0/DCIM/Screenshots/sc-1.png',
          }
        ],
      };

      final model = FolderContextModel.fromJson(json);

      expect(model.categoryId, 'finance-123');
      expect(model.categoryName, 'Finance & Invoices');
      expect(model.summary, contains('Invoices and receipts'));
      expect(model.keywords, contains('stripe'));
      expect(model.confidence, 0.94);
      expect(model.screenshotCount, 15);
      expect(model.tasks.length, 2);
      expect(model.tasks.first.title, 'Pay AWS bill by end of month');
      expect(model.tasks.first.isCompleted, isFalse);
      expect(model.tasks.first.dueDate, '2026-08-31');
      expect(model.tasks.last.isCompleted, isTrue);
      expect(model.entities.length, 2);
      expect(model.people, contains('Sarah Miller'));
      expect(model.links.first, contains('dashboard.stripe.com'));
      expect(model.dates.first.event, 'AWS Due Date');
      expect(model.apps, contains('HDFC Mobile Banking'));
      expect(model.topics, contains('Taxes'));
      expect(model.timeline.length, 1);
      expect(model.timeline.first.title, 'Stripe Invoice #4021');
      expect(model.isEmpty, isFalse);

      final reEncoded = model.toJson();
      expect(reEncoded['categoryId'], 'finance-123');
      expect(reEncoded['tasks'], hasLength(2));
      expect(reEncoded['timeline'], hasLength(1));
    });

    test('Handles empty and fallback representations correctly', () {
      final empty = FolderContextModel.empty(
        categoryId: 'empty-cat',
        categoryName: 'Empty Folder',
      );

      expect(empty.isEmpty, isTrue);
      expect(empty.tasks, isEmpty);
      expect(empty.timeline, isEmpty);
      expect(empty.summary, isEmpty);

      // copyWith updates fields properly
      final updated = empty.copyWith(summary: 'New summary');
      expect(updated.summary, 'New summary');
      expect(updated.isEmpty, isFalse);
    });
  });

  group('FolderContextRepository', () {
    test('Returns API data when backend succeeds', () async {
      final mockApi = MockApiClient();
      mockApi.mockContextResponse = const FolderContextModel(
        categoryId: 'travel-1',
        categoryName: 'Travel',
        summary: 'Flight bookings to Tokyo and hotel vouchers.',
        keywords: ['tokyo', 'flight', 'ana'],
        confidence: 0.98,
        screenshotCount: 5,
      );

      final repo = FolderContextRepositoryImpl(
        apiClient: mockApi,
        screenshotRepository: MockScreenshotRepository([]),
      );

      final result = await repo.getFolderContext('travel-1');
      expect(result.summary, contains('Flight bookings to Tokyo'));
      expect(result.confidence, 0.98);
    });

    test('Falls back to local screenshots timeline when API returns 404 or fails', () async {
      final mockApi = MockApiClient();
      mockApi.shouldFail = true;

      final now = DateTime.now();
      final List<ScreenshotModel> mockScreenshots = [
        ScreenshotModel(
          id: 'sc-101',
          fileName: 'boarding_pass.png',
          filePath: '/storage/emulated/0/DCIM/Screenshots/boarding_pass.png',
          fileSize: 204800,
          createdAt: now,
          ocrText: 'Boarding pass for ANA flight NH802 to Tokyo Narita.',
          categoryId: 'travel-1',
          categoryName: 'Travel',
        ),
      ];

      final repo = FolderContextRepositoryImpl(
        apiClient: mockApi,
        screenshotRepository: MockScreenshotRepository(mockScreenshots),
      );

      final result = await repo.getFolderContext('travel-1', categoryName: 'Travel');
      expect(result.categoryId, 'travel-1');
      expect(result.screenshotCount, 1);
      expect(result.timeline.length, 1);
      expect(result.timeline.first.title, 'boarding_pass.png');
      expect(result.timeline.first.description, contains('NH802'));
    });
  });
}
