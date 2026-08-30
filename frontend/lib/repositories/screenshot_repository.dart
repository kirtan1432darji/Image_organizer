import '../core/services/database_service.dart';
import '../core/services/api_client.dart';
import '../core/services/ocr_service.dart';
import '../core/utils/result.dart';
import '../models/screenshot_model.dart';
import '../models/tag_model.dart';
import '../models/sync_queue_item_model.dart';
import 'package:uuid/uuid.dart';

abstract class ScreenshotRepository {
  Future<List<ScreenshotModel>> getScreenshots({
    String? categoryId,
    bool? isFavorite,
    bool? needsReview,
    int limit = 100,
    int offset = 0,
  });

  Future<ScreenshotModel?> getScreenshotById(String id);
  Future<void> saveScannedScreenshots(List<ScreenshotModel> screenshots);
  Future<void> toggleFavorite(String id, bool isFavorite);
  Future<void> updateCategory(String id, String categoryId, String categoryName);
  Future<void> addTagToScreenshot(String id, TagModel tag);
  Future<void> removeTagFromScreenshot(String id, String tagId);
  Future<void> markReviewed(String id);
  Future<void> deleteScreenshot(String id);
  Future<Result<ScreenshotModel>> runOcrAndClassification(String id);
  Future<Map<String, int>> getStats();
  Future<void> purgeMockData();
}

class ScreenshotRepositoryImpl implements ScreenshotRepository {
  final DatabaseService _db;
  final ApiClient _apiClient;
  final OcrService _ocrService;
  final _uuid = const Uuid();

  ScreenshotRepositoryImpl({
    DatabaseService? db,
    ApiClient? apiClient,
    OcrService? ocrService,
  })  : _db = db ?? DatabaseService(),
        _apiClient = apiClient ?? ApiClient(),
        _ocrService = ocrService ?? LocalOcrService();

  @override
  Future<void> purgeMockData() async {
    await _db.purgeMockScreenshots();
  }

  @override
  Future<List<ScreenshotModel>> getScreenshots({
    String? categoryId,
    bool? isFavorite,
    bool? needsReview,
    int limit = 100,
    int offset = 0,
  }) {
    return _db.getAllScreenshots(
      categoryId: categoryId,
      isFavorite: isFavorite,
      needsReview: needsReview,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<ScreenshotModel?> getScreenshotById(String id) {
    return _db.getScreenshotById(id);
  }

  @override
  Future<void> saveScannedScreenshots(List<ScreenshotModel> screenshots) async {
    for (final s in screenshots) {
      await _db.insertScreenshot(s);
    }
    // Push batch metadata to SQL Server backend asynchronously
    try {
      await _apiClient.batchScanScreenshots(screenshots);
    } catch (_) {}
  }

  @override
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    await _db.toggleFavorite(id, isFavorite);
    try {
      await _apiClient.toggleFavorite(id, isFavorite);
    } catch (_) {}
  }

  @override
  Future<void> updateCategory(String id, String categoryId, String categoryName) async {
    final item = await _db.getScreenshotById(id);
    if (item != null) {
      final updated = item.copyWith(
        categoryId: categoryId,
        categoryName: categoryName,
        isReviewed: true,
      );
      await _db.updateScreenshot(updated);
    }
  }

  @override
  Future<void> addTagToScreenshot(String id, TagModel tag) async {
    await _db.addTag(tag);
    final item = await _db.getScreenshotById(id);
    if (item != null) {
      if (!item.tags.any((t) => t.id == tag.id)) {
        final updatedTags = List<TagModel>.from(item.tags)..add(tag);
        await _db.updateScreenshot(item.copyWith(tags: updatedTags));
      }
    }
  }

  @override
  Future<void> removeTagFromScreenshot(String id, String tagId) async {
    final item = await _db.getScreenshotById(id);
    if (item != null) {
      final updatedTags = item.tags.where((t) => t.id != tagId).toList();
      await _db.updateScreenshot(item.copyWith(tags: updatedTags));
    }
  }

  @override
  Future<void> markReviewed(String id) async {
    final item = await _db.getScreenshotById(id);
    if (item != null) {
      await _db.updateScreenshot(item.copyWith(isReviewed: true));
      try {
        await _apiClient.markReviewed(id, true);
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteScreenshot(String id) {
    return _db.deleteScreenshot(id);
  }

  @override
  Future<Result<ScreenshotModel>> runOcrAndClassification(String id) async {
    final item = await _db.getScreenshotById(id);
    if (item == null) {
      return Result.failure('Screenshot not found');
    }

    // 1. Run OCR extraction
    final ocrResult = await _ocrService.extractText(
      screenshotId: item.id,
      filePath: item.filePath,
    );

    if (ocrResult.isFailure) {
      return Result.failure('OCR failed: ${ocrResult.errorOrNull}');
    }

    final ocrData = ocrResult.dataOrNull!;
    String detectedCategory = item.categoryId;
    String detectedCategoryName = item.categoryName;
    String subcategory = item.subcategory;
    double confidence = item.confidence;
    List<TagModel> tags = List.from(item.tags);

    // 2. Request AI classification from ASP.NET Core backend (or queue offline)
    final aiResult = await _apiClient.classifyScreenshot(
      screenshotId: item.id,
      fileName: item.fileName,
      ocrText: ocrData.rawText,
    );

    if (aiResult.isSuccess) {
      final cl = aiResult.dataOrNull!;
      detectedCategory = cl.categoryId;
      detectedCategoryName = cl.categoryName;
      subcategory = cl.subcategory;
      confidence = cl.confidence;

      for (final tagStr in cl.suggestedTags) {
        final t = TagModel(
          id: 'tag_${tagStr.toLowerCase().replaceAll(' ', '_')}',
          name: tagStr,
          colorHex: '6366F1',
        );
        if (!tags.any((existing) => existing.name.toLowerCase() == tagStr.toLowerCase())) {
          tags.add(t);
          await _db.addTag(t);
        }
      }
    } else {
      // Queue offline classification
      await _db.addToSyncQueue(
        SyncQueueItemModel(
          id: _uuid.v4(),
          endpoint: '/screenshots/classify',
          payload: {
            'screenshot_id': item.id,
            'file_name': item.fileName,
            'ocr_text': ocrData.rawText,
          },
          createdAt: DateTime.now(),
        ),
      );
    }

    final updated = item.copyWith(
      ocrText: ocrData.rawText,
      ocrStatus: 'completed',
      categoryId: detectedCategory,
      categoryName: detectedCategoryName,
      subcategory: subcategory,
      confidence: confidence > 0 ? confidence : 0.88,
      tags: tags,
      isReviewed: confidence >= 0.85,
    );

    await _db.updateScreenshot(updated);
    return Result.success(updated);
  }

  @override
  Future<Map<String, int>> getStats() {
    return _db.getStats();
  }
}
