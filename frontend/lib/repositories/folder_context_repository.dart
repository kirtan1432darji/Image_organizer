import 'package:flutter/foundation.dart';
import '../core/services/api_client.dart';
import '../models/folder_context_model.dart';
import '../repositories/screenshot_repository.dart';

abstract class FolderContextRepository {
  Future<FolderContextModel> getFolderContext(String categoryId, {String? categoryName});
  Future<FolderContextModel> generateFolderContext(String categoryId, {String? categoryName});
}

class FolderContextRepositoryImpl implements FolderContextRepository {
  final ApiClient _apiClient;
  final ScreenshotRepository _screenshotRepository;

  // In-memory cache for loaded contexts
  final Map<String, FolderContextModel> _cache = {};

  FolderContextRepositoryImpl({
    ApiClient? apiClient,
    ScreenshotRepository? screenshotRepository,
  })  : _apiClient = apiClient ?? ApiClient(),
        _screenshotRepository = screenshotRepository ?? ScreenshotRepositoryImpl();

  @override
  Future<FolderContextModel> getFolderContext(String categoryId, {String? categoryName}) async {
    try {
      final result = await _apiClient.fetchFolderContext(categoryId);
      if (result.isSuccess && result.dataOrNull != null) {
        final ctx = result.dataOrNull!;
        _cache[categoryId] = ctx;
        return ctx;
      }
    } catch (e) {
      debugPrint('[FolderContextRepository] API fetch failed: $e');
    }

    // Check memory cache
    if (_cache.containsKey(categoryId)) {
      return _cache[categoryId]!;
    }

    // Fallback: build a baseline model with local screenshots timeline if available
    try {
      final screenshots = await _screenshotRepository.getScreenshots(categoryId: categoryId);
      final timeline = screenshots.map((s) {
        final ocr = s.ocrText ?? '';
        return ContextTimelineItemModel(
          screenshotId: s.id,
          title: s.fileName,
          description: ocr.isNotEmpty
              ? (ocr.length > 80 ? '${ocr.substring(0, 80)}...' : ocr)
              : 'Captured ${s.createdAt.toLocal()}',
          capturedAt: s.createdAt,
          imagePath: s.filePath,
        );
      }).toList();

      return FolderContextModel.empty(
        categoryId: categoryId,
        categoryName: categoryName ?? 'Folder Context',
        screenshotCount: screenshots.length,
      ).copyWith(
        timeline: timeline,
      );
    } catch (_) {
      return FolderContextModel.empty(
        categoryId: categoryId,
        categoryName: categoryName ?? 'Folder Context',
      );
    }
  }

  @override
  Future<FolderContextModel> generateFolderContext(String categoryId, {String? categoryName}) async {
    final result = await _apiClient.generateFolderContext(categoryId);
    if (result.isSuccess && result.dataOrNull != null) {
      final updated = result.dataOrNull!;
      _cache[categoryId] = updated;
      return updated;
    }

    // If backend generation fails (e.g. offline), re-fetch fallback or throw readable error
    if (result.errorOrNull != null) {
      throw Exception(result.errorOrNull);
    }
    return getFolderContext(categoryId, categoryName: categoryName);
  }
}
