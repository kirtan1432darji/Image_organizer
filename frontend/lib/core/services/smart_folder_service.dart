import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'database_service.dart';
import '../../models/classification_result_model.dart';
import '../../models/sync_queue_item_model.dart';
import '../../repositories/classification_repository.dart';

class SmartFolderService {
  final ClassificationRepository _classificationRepo;
  final DatabaseService _db;

  SmartFolderService({
    ClassificationRepository? classificationRepository,
    DatabaseService? databaseService,
  })  : _classificationRepo = classificationRepository ?? ClassificationRepository(),
        _db = databaseService ?? DatabaseService();

  /// Classifies, updates local SQLite database, links tags, and prepares smart folder assignment
  Future<ClassificationResultModel?> classifyAndOrganizeScreenshot({
    required String filePath,
    required String ocrText,
    String? screenshotId,
    String? fileName,
    String? sourceApp,
    String? visionDescription,
  }) async {
    final effectiveName = fileName ?? filePath.split('/').last.split('\\').last;

    // 1. Classify via repository (calls .NET backend with automatic local fallback)
    final result = await _classificationRepo.classifyScreenshot(
      filePath: filePath,
      ocrText: ocrText,
      fileName: effectiveName,
      sourceApp: sourceApp,
      screenshotId: screenshotId,
      visionDescription: visionDescription,
    );

    if (!result.isSuccess || result.dataOrNull == null) {
      debugPrint('[SmartFolderService] Failed to classify screenshot: ${result.errorOrNull}');
      return null;
    }

    final classification = result.dataOrNull!;
    debugPrint('[SmartFolderService] Classified into folder: ${classification.folderPath.join(" -> ")}');

    // 2. Ensure folder hierarchy exists in SQLite
    final leafCategory = await _db.getOrCreateFolderHierarchy(classification.folderPath);

    // 3. If screenshot exists in SQLite, update its category and classification metadata
    if (screenshotId != null && screenshotId.isNotEmpty) {
      final existing = await _db.getScreenshotById(screenshotId);
      if (existing != null) {
        final dbInstance = await _db.database;
        await dbInstance.update(
          'screenshots',
          {
            'category_id': leafCategory.id,
            'category_name': classification.categoryName,
            'subcategory': classification.subcategory,
            'confidence': classification.confidence,
            'detected_app': classification.detectedApp ?? sourceApp,
            'keywords_json': jsonEncode(classification.keywords),
            'is_auto_categorized': 1,
          },
          where: 'id = ?',
          whereArgs: [screenshotId],
        );

        // Link suggested tags
        for (final tag in classification.suggestedTags) {
          try {
            await _db.linkScreenshotTag(screenshotId, tag);
          } catch (_) {}
        }

        // Queue sync item
        await _db.addToSyncQueue(SyncQueueItemModel(
          id: 'sync_${screenshotId}_classify',
          endpoint: '/classification/classify',
          httpMethod: 'POST',
          payload: classification.toJson(),
          createdAt: DateTime.now(),
        ));
      }
    }

    return classification;
  }
}
