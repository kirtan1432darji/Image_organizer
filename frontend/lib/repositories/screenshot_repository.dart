import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/services/database_service.dart';
import '../core/services/api_client.dart';
import '../core/services/ocr_service.dart';
import '../core/utils/result.dart';
import '../models/screenshot_model.dart';
import '../models/tag_model.dart';
import '../models/sync_queue_item_model.dart';

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
  }) async {
    // 1. First, return cached local SQLite items for instantaneous render
    final localItems = await _db.getAllScreenshots(
      categoryId: categoryId,
      isFavorite: isFavorite,
      needsReview: needsReview,
      limit: limit,
      offset: offset,
    );

    // 2. Fetch fresh paged data from backend API if online
    try {
      final remoteResult = await _apiClient.fetchScreenshots(
        categoryId: categoryId,
        isFavorite: isFavorite,
        needsReview: needsReview,
        pageNumber: (offset ~/ limit) + 1,
        pageSize: limit,
      );

      if (remoteResult.isSuccess) {
        final remoteList = remoteResult.dataOrNull ?? [];
        for (final itemMap in remoteList) {
          final screenshot = _mapBackendDtoToModel(itemMap);
          await _db.upsertScreenshot(screenshot);
        }
        // Return updated list
        return await _db.getAllScreenshots(
          categoryId: categoryId,
          isFavorite: isFavorite,
          needsReview: needsReview,
          limit: limit,
          offset: offset,
        );
      }
    } catch (e) {
      debugPrint('[ScreenshotRepository] Background API fetch skipped: $e');
    }

    return localItems;
  }

  @override
  Future<ScreenshotModel?> getScreenshotById(String id) {
    return _db.getScreenshotById(id);
  }

  @override
  Future<void> saveScannedScreenshots(List<ScreenshotModel> screenshots) async {
    // 1. Upsert into local SQLite cache (deduplicating by deviceAssetId)
    for (final s in screenshots) {
      await _db.upsertScreenshot(s);
    }

    // 2. Push metadata payload to ASP.NET Core backend in batch
    try {
      final batchPayload = screenshots.map((s) => {
        'imageId': s.deviceAssetId,
        'imagePath': s.filePath,
        'capturedDate': s.createdAt.toIso8601String(),
        'sourceApp': s.sourceApp ?? '',
        'width': s.width,
        'height': s.height,
        'ocrText': s.ocrText ?? '',
        'autoClassify': true,
      }).toList();

      final res = await _apiClient.batchScanScreenshots(batchPayload);
      if (res.isSuccess) {
        final results = res.dataOrNull ?? [];
        for (final itemMap in results) {
          final updatedModel = _mapBackendDtoToModel(itemMap);
          await _db.upsertScreenshot(updatedModel);
        }
      }
    } catch (e) {
      debugPrint('[ScreenshotRepository] Background scan sync to backend failed: $e');
    }
  }

  @override
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    await _db.toggleFavorite(id, isFavorite);
    try {
      await _apiClient.toggleFavorite(id, isFavorite);
    } catch (e) {
      debugPrint('[ScreenshotRepository] Remote toggle favorite queued: $e');
      await _db.addToSyncQueue(
        SyncQueueItemModel(
          id: _uuid.v4(),
          endpoint: '/screenshots/$id/favorite',
          httpMethod: 'PATCH',
          payload: {'isFavorite': isFavorite},
          createdAt: DateTime.now(),
        ),
      );
    }
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

      try {
        await _apiClient.updateScreenshot(id: id, categoryId: categoryId);
      } catch (e) {
        debugPrint('[ScreenshotRepository] Remote update category queued: $e');
      }
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
        try {
          await _apiClient.updateScreenshot(
            id: id,
            tags: updatedTags.map((t) => t.name).toList(),
          );
        } catch (_) {}
      }
    }
  }

  @override
  Future<void> removeTagFromScreenshot(String id, String tagId) async {
    final item = await _db.getScreenshotById(id);
    if (item != null) {
      final updatedTags = item.tags.where((t) => t.id != tagId).toList();
      await _db.updateScreenshot(item.copyWith(tags: updatedTags));
      try {
        await _apiClient.updateScreenshot(
          id: id,
          tags: updatedTags.map((t) => t.name).toList(),
        );
      } catch (_) {}
    }
  }

  @override
  Future<void> markReviewed(String id) async {
    final item = await _db.getScreenshotById(id);
    if (item != null) {
      await _db.updateScreenshot(item.copyWith(isReviewed: true));
      try {
        await _apiClient.toggleReview(id, true);
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteScreenshot(String id) async {
    await _db.deleteScreenshot(id);
    try {
      await _apiClient.deleteScreenshot(id);
    } catch (_) {}
  }

  @override
  Future<Result<ScreenshotModel>> runOcrAndClassification(String id) async {
    final item = await _db.getScreenshotById(id);
    if (item == null) {
      return Result.failure('Screenshot not found');
    }

    // 1. Run local OCR extraction
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

    // 2. Request AI classification from ASP.NET Core backend
    final aiResult = await _apiClient.classifyScreenshot(
      screenshotId: item.id,
      fileName: item.fileName,
      ocrText: ocrData.rawText,
      sourceApp: item.sourceApp ?? '',
    );

    if (aiResult.isSuccess) {
      final cl = aiResult.dataOrNull!;
      detectedCategory = cl.categoryId.isNotEmpty ? cl.categoryId : cl.categoryName.toLowerCase();
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

  ScreenshotModel _mapBackendDtoToModel(Map<String, dynamic> dto) {
    final catMap = dto['category'] as Map<String, dynamic>?;
    final tagsList = dto['tags'] as List<dynamic>? ?? [];

    final tags = tagsList.map((t) {
      if (t is Map) {
        return TagModel(
          id: t['id']?.toString() ?? '',
          name: t['name']?.toString() ?? '',
          colorHex: '6366F1',
        );
      }
      return TagModel(
        id: 'tag_${t.toString().toLowerCase().replaceAll(' ', '_')}',
        name: t.toString(),
        colorHex: '6366F1',
      );
    }).toList();

    return ScreenshotModel(
      id: dto['id']?.toString() ?? _uuid.v4(),
      deviceAssetId: dto['imageId']?.toString() ?? dto['deviceAssetId']?.toString() ?? '',
      filePath: dto['imagePath']?.toString() ?? dto['filePath']?.toString() ?? '',
      fileName: dto['fileName']?.toString() ?? 'Screenshot.png',
      createdAt: dto['capturedDate'] != null
          ? DateTime.tryParse(dto['capturedDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      width: dto['width'] as int? ?? 1080,
      height: dto['height'] as int? ?? 2400,
      fileSize: dto['fileSize'] as int? ?? 0,
      categoryId: catMap?['id']?.toString() ?? dto['categoryId']?.toString() ?? 'unsorted',
      categoryName: catMap?['name']?.toString() ?? dto['categoryName']?.toString() ?? 'Unsorted',
      subcategory: dto['subCategory']?['name']?.toString() ?? dto['subcategory']?.toString() ?? '',
      confidence: (dto['confidence'] as num?)?.toDouble() ?? 0.0,
      sourceApp: dto['sourceApp']?.toString(),
      isFavorite: dto['isFavorite'] as bool? ?? false,
      isReviewed: dto['isReviewed'] as bool? ?? false,
      isSynced: true,
      ocrStatus: dto['ocrStatus']?.toString() ?? (dto['ocrText'] != null ? 'completed' : 'none'),
      ocrText: dto['ocrText']?.toString(),
      tags: tags,
      lastScannedAt: DateTime.now(),
      isMock: false,
    );
  }
}
