import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_screenshot_organizer/features/context/folder_context_screen.dart';
import 'package:ai_screenshot_organizer/models/folder_context_model.dart';
import 'package:ai_screenshot_organizer/providers/folder_context_provider.dart';
import 'package:ai_screenshot_organizer/repositories/folder_context_repository.dart';

class MockFolderContextRepository implements FolderContextRepository {
  final FolderContextModel model;
  MockFolderContextRepository(this.model);

  @override
  Future<FolderContextModel> getFolderContext(String categoryId, {String? categoryName}) async {
    return model;
  }

  @override
  Future<FolderContextModel> generateFolderContext(String categoryId, {String? categoryName}) async {
    return model;
  }
}

void main() {
  testWidgets('FolderContextScreen renders full AI knowledge space correctly', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockModel = FolderContextModel(
      categoryId: 'finance-1',
      categoryName: 'Finance & Invoices',
      summary: 'Q3 Invoices and tax receipts totaling \$3,200 from Stripe and AWS.',
      keywords: const ['stripe', 'invoices', 'taxes', 'receipts'],
      confidence: 0.96,
      screenshotCount: 8,
      lastUpdatedAt: DateTime(2026, 8, 31, 14, 30),
      tasks: const [
        ContextTaskModel(
          id: 'task-1',
          title: 'Pay quarterly AWS hosting invoice',
          isCompleted: false,
          dueDate: 'Aug 31',
        ),
        ContextTaskModel(
          id: 'task-2',
          title: 'Download Stripe tax summary',
          isCompleted: true,
        ),
      ],
      people: const ['Alice Finance', 'Bob Accountant'],
      links: const ['https://dashboard.stripe.com/invoices'],
      dates: const [
        ContextDateModel(event: 'Tax Due Date', date: 'Sep 15, 2026'),
      ],
      apps: const ['Stripe', 'AWS Console'],
      topics: const ['Taxes', 'Cloud Infrastructure'],
      timeline: [
        ContextTimelineItemModel(
          screenshotId: 'sc-101',
          title: 'Stripe Invoice #4021',
          description: 'Payment confirmation for \$249.00 USD',
          capturedAt: DateTime(2026, 8, 28, 11, 15),
        ),
      ],
    );

    final mockRepo = MockFolderContextRepository(mockModel);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          folderContextRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: FolderContextScreen(
            categoryId: 'finance-1',
            categoryName: 'Finance & Invoices',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Header verification
    expect(find.text('Finance & Invoices Context'), findsOneWidget);
    expect(find.text('8 Screenshots'), findsOneWidget);
    expect(find.text('Generate / Refresh Context'), findsOneWidget);

    // 2. Summary Card verification
    expect(find.text('AI Context Summary'), findsOneWidget);
    expect(find.textContaining('Q3 Invoices and tax receipts'), findsOneWidget);
    expect(find.text('#stripe'), findsOneWidget);
    expect(find.text('#invoices'), findsOneWidget);

    // 3. Extracted Information sections
    expect(find.text('Extracted Information'), findsOneWidget);
    expect(find.text('Pending Tasks'), findsOneWidget);
    expect(find.text('Pay quarterly AWS hosting invoice'), findsOneWidget);
    expect(find.text('People Mentioned'), findsOneWidget);
    expect(find.text('Alice Finance'), findsOneWidget);
    expect(find.text('Important Links'), findsOneWidget);
    expect(find.text('Important Dates'), findsOneWidget);
    expect(find.text('Apps Used'), findsOneWidget);
    expect(find.text('Stripe'), findsWidgets);
    expect(find.text('AWS Console'), findsOneWidget);
    expect(find.text('Topics & Entities'), findsOneWidget);

    // 4. Screenshot Timeline verification
    expect(find.text('Screenshot Timeline'), findsOneWidget);
    expect(find.text('1 Events'), findsOneWidget);
    expect(find.text('Stripe Invoice #4021'), findsOneWidget);

    // 5. Quick Actions verification
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Ask Context AI'), findsOneWidget);
    expect(find.text('All Screenshots'), findsOneWidget);
    expect(find.text('Search Inside Finance & Invoices'), findsOneWidget);

    // 6. Test interaction: Tap 'Ask Context AI' modal
    await tester.tap(find.text('Ask Context AI'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ask Context AI (Finance & Invoices)'), findsOneWidget);
  });

  testWidgets('FolderContextScreen renders clean empty state when no context exists', (tester) async {
    final emptyModel = FolderContextModel.empty(
      categoryId: 'new-folder',
      categoryName: 'New Folder',
    );

    final mockRepo = MockFolderContextRepository(emptyModel);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          folderContextRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: FolderContextScreen(
            categoryId: 'new-folder',
            categoryName: 'New Folder',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No Context Generated Yet'), findsOneWidget);
    expect(find.text('Generate Context'), findsOneWidget);
  });
}
