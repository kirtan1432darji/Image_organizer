import 'package:flutter/foundation.dart';
import '../core/services/api_client.dart';
import '../core/services/database_service.dart';
import '../core/services/media_classifier.dart';
import '../core/utils/result.dart';
import '../models/classification_result_model.dart';

class ClassificationRepository {
  final ApiClient _apiClient;
  final DatabaseService _db;
  final MediaClassifier _localClassifier;

  ClassificationRepository({
    ApiClient? apiClient,
    DatabaseService? databaseService,
    MediaClassifier? mediaClassifier,
  })  : _apiClient = apiClient ?? ApiClient(),
        _db = databaseService ?? DatabaseService(),
        _localClassifier = mediaClassifier ?? const MediaClassifier();

  /// Classifies a screenshot via backend AI service with graceful on-device fallback
  Future<Result<ClassificationResultModel>> classifyScreenshot({
    required String filePath,
    required String ocrText,
    String? fileName,
    String? sourceApp,
    String? screenshotId,
    String? visionDescription,
  }) async {
    final effectiveFileName = fileName ?? filePath.split('/').last.split('\\').last;

    // 1. Try remote ASP.NET Core classification engine
    try {
      final remoteResult = await _apiClient.classifyScreenshotMetadata(
        screenshotId: screenshotId,
        fileName: effectiveFileName,
        filePath: filePath,
        ocrText: ocrText,
        sourceApp: sourceApp,
        visionDescription: visionDescription,
      );

      if (remoteResult.isSuccess && remoteResult.dataOrNull != null) {
        final data = remoteResult.dataOrNull!;
        debugPrint('[ClassificationRepo] Remote classification success: ${data.folderPath.join(" -> ")}');

        // Ensure category hierarchy also exists in local SQLite
        if (data.folderPath.isNotEmpty) {
          await _db.getOrCreateFolderHierarchy(data.folderPath);
        }

        // Save classification history locally
        if (screenshotId != null && screenshotId.isNotEmpty) {
          await _db.saveClassificationHistory(
            screenshotId: screenshotId,
            category: data.categoryName,
            subCategory: data.subcategory,
            tags: data.suggestedTags,
            confidence: data.confidence,
            modelName: 'contextvault-backend-ai-v1.3',
          );
        }

        return Result.success(data);
      }
    } catch (e) {
      debugPrint('[ClassificationRepo] Remote classification exception (falling back to on-device): $e');
    }

    // 2. Fallback: On-Device Dynamic Smart Folder Classifier
    debugPrint('[ClassificationRepo] Performing local on-device smart classification...');
    final localClass = _localClassifier.classifyMediaItem(
      fileName: effectiveFileName,
      filePath: filePath,
      ocrText: ocrText,
      sourceApp: sourceApp,
      visionDescription: visionDescription,
    );

    // Resolve / create local smart folder hierarchy
    final leafCategory = await _db.getOrCreateFolderHierarchy(localClass.folderPath);

    // Record local classification history
    if (screenshotId != null && screenshotId.isNotEmpty) {
      await _db.saveClassificationHistory(
        screenshotId: screenshotId,
        category: localClass.rootFolder,
        subCategory: localClass.leafFolder != localClass.rootFolder ? localClass.leafFolder : null,
        tags: localClass.tags,
        confidence: localClass.confidence,
        modelName: 'contextvault-local-engine-v1.3',
      );
    }

    final localModel = ClassificationResultModel(
      screenshotId: screenshotId ?? '',
      categoryId: leafCategory.id,
      categoryName: localClass.rootFolder,
      subCategoryId: leafCategory.id != localClass.rootFolder ? leafCategory.id : null,
      subcategory: localClass.leafFolder != localClass.rootFolder ? localClass.leafFolder : '',
      folderPath: localClass.folderPath,
      confidence: localClass.confidence,
      sourceApp: sourceApp,
      detectedApp: sourceApp ?? localClass.rootFolder,
      suggestedTags: localClass.tags,
      keywords: localClass.tags,
      summary: 'Categorized to ${localClass.folderPath.join(" > ")}',
      isAutoCategorized: true,
    );

    return Result.success(localModel);
  }

  /// Reclassifies an existing screenshot
  Future<Result<ClassificationResultModel>> reclassifyScreenshot({
    required String screenshotId,
    String? userHint,
  }) async {
    final remoteResult = await _apiClient.reclassifyScreenshot(
      screenshotId: screenshotId,
      forceReclassify: true,
      userHint: userHint,
    );

    if (remoteResult.isSuccess && remoteResult.dataOrNull != null) {
      final data = remoteResult.dataOrNull!;
      if (data.folderPath.isNotEmpty) {
        await _db.getOrCreateFolderHierarchy(data.folderPath);
      }
      return Result.success(data);
    }

    // Fallback: fetch screenshot locally and reclassify
    final ss = await _db.getScreenshotById(screenshotId);
    if (ss != null) {
      return await classifyScreenshot(
        filePath: ss.filePath,
        ocrText: userHint != null ? '$userHint\n${ss.ocrText ?? ""}' : (ss.ocrText ?? ''),
        fileName: ss.fileName,
        sourceApp: ss.sourceApp,
        screenshotId: ss.id,
      );
    }

    return Result.failure('Screenshot not found for reclassification.');
  }

  /// Fetches history audit trail
  Future<List<Map<String, dynamic>>> getHistory(String screenshotId) async {
    // Try remote history first
    final remoteHist = await _apiClient.fetchClassificationHistory(screenshotId);
    if (remoteHist.isSuccess && remoteHist.dataOrNull != null && remoteHist.dataOrNull!.isNotEmpty) {
      return remoteHist.dataOrNull!;
    }

    // Fallback to local SQLite history
    return await _db.getClassificationHistory(screenshotId);
  }
}
