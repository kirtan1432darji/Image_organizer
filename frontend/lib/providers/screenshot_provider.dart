import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/screenshot_model.dart';
import '../models/tag_model.dart';
import '../repositories/screenshot_repository.dart';
import 'category_provider.dart';

final screenshotRepositoryProvider = Provider<ScreenshotRepository>((ref) {
  return ScreenshotRepositoryImpl();
});

class ScreenshotNotifier extends AsyncNotifier<List<ScreenshotModel>> {
  @override
  Future<List<ScreenshotModel>> build() async {
    return _fetchScreenshots();
  }

  Future<List<ScreenshotModel>> _fetchScreenshots() async {
    final repo = ref.read(screenshotRepositoryProvider);
    await repo.purgeMockData();
    return repo.getScreenshots(limit: 200);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchScreenshots());
    // Also refresh category counters
    ref.invalidate(categoryListProvider);
  }

  Future<void> toggleFavorite(String id, bool currentStatus) async {
    final repo = ref.read(screenshotRepositoryProvider);
    await repo.toggleFavorite(id, !currentStatus);

    state = state.whenData((list) => list.map((item) {
          if (item.id == id) {
            return item.copyWith(isFavorite: !currentStatus);
          }
          return item;
        }).toList());
  }

  Future<void> updateCategory(
      String id, String categoryId, String categoryName) async {
    final repo = ref.read(screenshotRepositoryProvider);
    await repo.updateCategory(id, categoryId, categoryName);

    state = state.whenData((list) => list.map((item) {
          if (item.id == id) {
            return item.copyWith(
              categoryId: categoryId,
              categoryName: categoryName,
              isReviewed: true,
            );
          }
          return item;
        }).toList());

    ref.invalidate(categoryListProvider);
  }

  Future<void> addTag(String id, TagModel tag) async {
    final repo = ref.read(screenshotRepositoryProvider);
    await repo.addTagToScreenshot(id, tag);

    state = state.whenData((list) => list.map((item) {
          if (item.id == id) {
            if (!item.tags.any((t) => t.id == tag.id)) {
              return item.copyWith(tags: [...item.tags, tag]);
            }
          }
          return item;
        }).toList());
  }

  Future<void> removeTag(String id, String tagId) async {
    final repo = ref.read(screenshotRepositoryProvider);
    await repo.removeTagFromScreenshot(id, tagId);

    state = state.whenData((list) => list.map((item) {
          if (item.id == id) {
            return item.copyWith(
              tags: item.tags.where((t) => t.id != tagId).toList(),
            );
          }
          return item;
        }).toList());
  }

  Future<void> markReviewed(String id) async {
    final repo = ref.read(screenshotRepositoryProvider);
    await repo.markReviewed(id);

    state = state.whenData((list) => list.map((item) {
          if (item.id == id) {
            return item.copyWith(isReviewed: true);
          }
          return item;
        }).toList());
  }

  Future<void> deleteScreenshot(String id) async {
    final repo = ref.read(screenshotRepositoryProvider);
    await repo.deleteScreenshot(id);

    state = state.whenData(
        (list) => list.where((item) => item.id != id).toList());
    ref.invalidate(categoryListProvider);
  }

  Future<void> runAiClassification(String id) async {
    final repo = ref.read(screenshotRepositoryProvider);
    final result = await repo.runOcrAndClassification(id);
    if (result.isSuccess) {
      final updated = result.dataOrNull!;
      state = state.whenData((list) => list.map((item) {
            if (item.id == id) return updated;
            return item;
          }).toList());
      ref.invalidate(categoryListProvider);
    }
  }
}

final screenshotListProvider =
    AsyncNotifierProvider<ScreenshotNotifier, List<ScreenshotModel>>(() {
  return ScreenshotNotifier();
});

// Specific selectors
final recentScreenshotsProvider = Provider<List<ScreenshotModel>>((ref) {
  final asyncScreenshots = ref.watch(screenshotListProvider);
  return asyncScreenshots.maybeWhen(
    data: (list) => list.take(10).toList(),
    orElse: () => [],
  );
});

final needsReviewScreenshotsProvider = Provider<List<ScreenshotModel>>((ref) {
  final asyncScreenshots = ref.watch(screenshotListProvider);
  return asyncScreenshots.maybeWhen(
    data: (list) => list.where((s) => s.needsReview).toList(),
    orElse: () => [],
  );
});

final statsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.read(screenshotRepositoryProvider);
  return repo.getStats();
});
