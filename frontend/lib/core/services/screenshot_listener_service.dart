import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/category_model.dart';
import '../../models/screenshot_model.dart';
import '../../models/sync_queue_item_model.dart';
import '../../models/tag_model.dart';
import 'api_client.dart';
import 'database_service.dart';
import 'media_classifier.dart';
import 'media_observer_service.dart';
import 'notification_service.dart';
import 'ocr_service.dart';
import 'sync_service.dart';

/// Service that coordinates automatic background screenshot detection,
/// duplicate prevention, OCR extraction, AI classification, smart folder sorting,
/// and local notifications.
class ScreenshotListenerService {
  final MediaObserverService _mediaObserver;
  final DatabaseService _db;
  final OcrService _ocrService;
  final ApiClient _apiClient;
  final MediaClassifier _classifier;
  final NotificationService _notificationService;
  final SyncService _syncService;

  final Set<String> _processedAssetIds = <String>{};
  StreamSubscription<DiscoveredScreenshot>? _subscription;
  bool _isListening = false;
  bool notificationsEnabled = true;

  // Callback to inform UI/Riverpod when a screenshot is fully processed and sorted
  Function(ScreenshotModel screenshot)? onScreenshotOrganized;

  ScreenshotListenerService({
    MediaObserverService? mediaObserver,
    DatabaseService? db,
    OcrService? ocrService,
    ApiClient? apiClient,
    MediaClassifier classifier = const MediaClassifier(),
    NotificationService? notificationService,
    SyncService? syncService,
  })  : _mediaObserver = mediaObserver ?? MediaObserverService(classifier: classifier),
        _db = db ?? DatabaseService(),
        _ocrService = ocrService ?? LocalOcrService(),
        _apiClient = apiClient ?? ApiClient(),
        _classifier = classifier,
        _notificationService = notificationService ?? NotificationService(),
        _syncService = syncService ?? SyncService();

  bool get isListening => _isListening;

  /// Starts the automatic background detection pipeline
  Future<void> start() async {
    if (_isListening) return;
    _isListening = true;

    // Listen to new screenshot events from MediaStore ContentObserver
    _subscription = _mediaObserver.onScreenshotDetected.listen(_processNewScreenshot);
    await _mediaObserver.startObserving();

    debugPrint('[ScreenshotListenerService] Monitoring started.');
  }

  /// Stops monitoring
  Future<void> stop() async {
    if (!_isListening) return;
    _isListening = false;

    await _subscription?.cancel();
    _subscription = null;
    await _mediaObserver.stopObserving();

    debugPrint('[ScreenshotListenerService] Monitoring stopped.');
  }

  /// Pipeline executed when a new screenshot is detected
  Future<void> _processNewScreenshot(DiscoveredScreenshot item) async {
    final assetId = item.deviceAssetId;
    final filePath = item.filePath;

    // 1. Duplicate Detection: In-memory check
    if (_processedAssetIds.contains(assetId) || _processedAssetIds.contains(filePath)) {
      return;
    }

    // 1b. Duplicate Detection: SQLite check
    final alreadyExists = await _db.hasScreenshot(
      deviceAssetId: assetId,
      filePath: filePath,
    );
    if (alreadyExists) {
      _processedAssetIds.add(assetId);
      _processedAssetIds.add(filePath);
      return;
    }

    _processedAssetIds.add(assetId);
    _processedAssetIds.add(filePath);

    debugPrint('[ScreenshotListenerService] New screenshot detected: ${item.fileName}');

    try {
      final screenshotId = const Uuid().v4();

      // 2. Initial Ingestion
      final initialModel = ScreenshotModel(
        id: screenshotId,
        deviceAssetId: assetId,
        filePath: filePath,
        fileName: item.fileName,
        createdAt: item.createdAt,
        width: item.width > 0 ? item.width : 1080,
        height: item.height > 0 ? item.height : 2400,
        fileSize: item.fileSize,
        categoryId: CategoryModel.unsortedId,
        categoryName: CategoryModel.unsortedName,
        subcategory: '',
        confidence: 0.0,
        sourceApp: _classifier.inferSourceApp(filePath) ?? 'Screenshot',
        isFavorite: false,
        isReviewed: false,
        isSynced: false,
        ocrStatus: 'processing',
        lastScannedAt: DateTime.now(),
        isMock: false,
      );

      await _db.insertScreenshot(initialModel);

      // 3. OCR Trigger
      String extractedText = '';
      double ocrConfidence = 0.85;

      try {
        final ocrResult = await _ocrService.extractText(
          screenshotId: screenshotId,
          filePath: filePath,
        );
        if (ocrResult.isSuccess) {
          extractedText = ocrResult.dataOrNull?.rawText ?? '';
          ocrConfidence = ocrResult.dataOrNull?.confidence ?? 0.85;
        }
      } catch (e) {
        debugPrint('[ScreenshotListenerService] OCR error: $e');
      }

      // 4. AI Classification Trigger
      String targetCatId = CategoryModel.unsortedId;
      String targetCatName = CategoryModel.unsortedName;
      String subcategory = 'General';
      double confidence = ocrConfidence;
      final tags = <TagModel>[];

      // Try remote API classification first
      bool remoteSuccess = false;
      try {
        final remoteRes = await _apiClient.classifyScreenshot(
          screenshotId: screenshotId,
          fileName: item.fileName,
          ocrText: extractedText,
          sourceApp: initialModel.sourceApp ?? '',
        );

        if (remoteRes.isSuccess) {
          final data = remoteRes.dataOrNull!;
          targetCatId = data.categoryId;
          targetCatName = data.categoryName;
          subcategory = data.subcategory;
          confidence = data.confidence;

          for (final tagStr in data.suggestedTags) {
            tags.add(TagModel(
              id: 'tag_${tagStr.toLowerCase().replaceAll(' ', '_')}',
              name: tagStr,
              colorHex: '6366F1',
            ));
          }
          remoteSuccess = true;
        }
      } catch (e) {
        debugPrint('[ScreenshotListenerService] Remote AI classification unavailable: $e');
      }

      // Fallback to on-device semantic classification
      if (!remoteSuccess) {
        final localClass = _classifier.classifyMediaItem(
          fileName: item.fileName,
          filePath: filePath,
          sourceApp: initialModel.sourceApp ?? '',
          ocrText: extractedText,
        );

        targetCatName = localClass.categoryName;
        subcategory = localClass.subcategory;
        confidence = localClass.confidence;

        for (final tagStr in localClass.tags) {
          tags.add(TagModel(
            id: 'tag_${tagStr.toLowerCase().replaceAll(' ', '_')}',
            name: tagStr,
            colorHex: '6366F1',
          ));
        }

        // Map category name to existing SQLite category
        final existingCats = await _db.getCategories();
        final match = existingCats.firstWhere(
          (c) => c.name.toLowerCase() == targetCatName.toLowerCase(),
          orElse: () => CategoryModel.unsortedCategory,
        );
        targetCatId = match.id;
        targetCatName = match.name;
      }

      // 5. Smart Folder & Category Update
      for (final t in tags) {
        await _db.addTag(t);
      }

      final organizedScreenshot = initialModel.copyWith(
        categoryId: targetCatId,
        categoryName: targetCatName,
        subcategory: subcategory,
        confidence: confidence,
        ocrText: extractedText,
        ocrStatus: 'completed',
        isReviewed: confidence >= 0.85,
        isSynced: remoteSuccess,
        tags: tags,
      );

      await _db.updateScreenshot(organizedScreenshot);

      // Link tags in SQLite
      for (final t in tags) {
        await _db.linkScreenshotTag(screenshotId, t.id);
      }

      // Queue metadata for backend sync if remote was skipped
      if (!remoteSuccess) {
        await _db.addToSyncQueue(
          SyncQueueItemModel(
            id: const Uuid().v4(),
            endpoint: '/screenshots/batch',
            httpMethod: 'POST',
            payload: {
              'screenshot_id': screenshotId,
              'file_name': item.fileName,
              'ocr_text': extractedText,
            },
            createdAt: DateTime.now(),
          ),
        );
        // Attempt background queue sync
        _syncService.processPendingQueue().ignore();
      }

      debugPrint(
        '[ScreenshotListenerService] Organized screenshot into $targetCatName / $subcategory',
      );

      // 6. Local Notification Trigger
      if (notificationsEnabled) {
        await _notificationService.showScreenshotOrganizedNotification(
          categoryName: targetCatName,
          subcategory: subcategory,
          fileName: item.fileName,
        );
      }

      // 7. Refresh UI Callbacks
      onScreenshotOrganized?.call(organizedScreenshot);
    } catch (e, stack) {
      debugPrint('[ScreenshotListenerService] Failed to process screenshot: $e\n$stack');
    }
  }

  void dispose() {
    stop();
  }
}
