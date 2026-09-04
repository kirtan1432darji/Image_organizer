import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'database_service.dart';
import '../../models/sync_queue_item_model.dart';
import '../../models/tag_model.dart';

class SyncService {
  final DatabaseService _db;
  final ApiClient _apiClient;
  bool _isSyncing = false;

  SyncService({
    DatabaseService? db,
    ApiClient? apiClient,
  })  : _db = db ?? DatabaseService(),
        _apiClient = apiClient ?? ApiClient();

  bool get isSyncing => _isSyncing;

  Future<int> processPendingQueue() async {
    if (_isSyncing) return 0;
    _isSyncing = true;

    int processedCount = 0;
    try {
      final isBackendOnline = await _apiClient.checkHealth();
      if (!isBackendOnline) {
        debugPrint('ASP.NET Core backend is currently offline. Sync postponed.');
        _isSyncing = false;
        return 0;
      }

      final pendingItems = await _db.getPendingSyncItems();
      for (final item in pendingItems) {
        try {
          await _processItem(item);
          await _db.updateSyncItemStatus(item.id, 'completed');
          processedCount++;
        } catch (e) {
          debugPrint('Error syncing queue item ${item.id}: $e');
          await _db.updateSyncItemStatus(item.id, 'failed', e.toString());
        }
      }
    } finally {
      _isSyncing = false;
    }

    return processedCount;
  }

  Future<void> _processItem(SyncQueueItemModel item) async {
    final payload = item.payload;
    final endpoint = item.endpoint;

    // Handle batch or single scan synchronization with ASP.NET Core backend
    if (endpoint == '/screenshots/batch' || endpoint == '/screenshots/scan') {
      final screenshotsList = payload['screenshots'] as List?;
      if (screenshotsList != null && screenshotsList.isNotEmpty) {
        final items = screenshotsList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        final batchRes = await _apiClient.batchScanScreenshots(items);
        if (batchRes.isSuccess) {
          for (final itemMap in items) {
            final id = itemMap['screenshot_id'] ?? itemMap['id'] ?? itemMap['device_asset_id'];
            if (id != null) {
              final sc = await _db.getScreenshotById(id.toString());
              if (sc != null) {
                await _db.updateScreenshot(sc.copyWith(isSynced: true));
              }
            }
          }
          return;
        }
      } else {
        // Single screenshot scan payload
        final assetId = (payload['device_asset_id'] ?? payload['image_id'] ?? payload['screenshot_id']) as String?;
        final filePath = (payload['file_path'] ?? payload['image_path']) as String? ?? '';
        final fileName = payload['file_name'] as String? ?? '';
        final ocrText = payload['ocr_text'] as String? ?? '';
        final sourceApp = payload['source_app'] as String? ?? 'Screenshot';
        final width = (payload['width'] as num?)?.toInt() ?? 1080;
        final height = (payload['height'] as num?)?.toInt() ?? 2400;
        final fileSize = (payload['file_size'] as num?)?.toInt() ?? 0;
        final hash = payload['hash'] as String?;

        if (assetId != null) {
          final scanRes = await _apiClient.scanScreenshotMetadata(
            imageId: assetId,
            imagePath: filePath,
            fileName: fileName,
            fileSize: fileSize,
            capturedDate: DateTime.tryParse(payload['captured_date']?.toString() ?? '') ?? DateTime.now(),
            sourceApp: sourceApp,
            width: width,
            height: height,
            ocrText: ocrText,
            hash: hash,
            autoClassify: true,
          );

          if (scanRes.isSuccess) {
            final screenshotId = payload['screenshot_id'] as String? ?? assetId;
            final sc = await _db.getScreenshotById(screenshotId);
            if (sc != null) {
              await _db.updateScreenshot(sc.copyWith(isSynced: true));
            }
            return;
          }
        }
      }
    }

    // Default classification sync fallback
    final screenshotId = payload['screenshot_id'] as String?;
    final fileName = payload['file_name'] as String? ?? '';
    final ocrText = payload['ocr_text'] as String? ?? '';

    if (screenshotId == null) return;

    final result = await _apiClient.classifyScreenshot(
      screenshotId: screenshotId,
      fileName: fileName,
      ocrText: ocrText,
    );

    if (result.isSuccess) {
      final classification = result.dataOrNull!;
      final existingScreenshot = await _db.getScreenshotById(screenshotId);
      if (existingScreenshot != null) {
        final updatedTags = List<TagModel>.from(existingScreenshot.tags);
        for (final tagStr in classification.suggestedTags) {
          final tagModel = TagModel(
            id: 'tag_${tagStr.toLowerCase().replaceAll(' ', '_')}',
            name: tagStr,
            colorHex: '6366F1',
          );
          if (!updatedTags.any((t) => t.name.toLowerCase() == tagStr.toLowerCase())) {
            updatedTags.add(tagModel);
            await _db.addTag(tagModel);
          }
        }

        final updatedScreenshot = existingScreenshot.copyWith(
          categoryId: classification.categoryId,
          categoryName: classification.categoryName,
          subcategory: classification.subcategory,
          confidence: classification.confidence,
          sourceApp: classification.sourceApp ?? existingScreenshot.sourceApp,
          isReviewed: classification.confidence >= 0.85,
          isSynced: true,
          tags: updatedTags,
        );

        await _db.updateScreenshot(updatedScreenshot);
      }
    }
  }
}
