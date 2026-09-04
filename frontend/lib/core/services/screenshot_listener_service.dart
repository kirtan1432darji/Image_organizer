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
import 'smart_folder_service.dart';
import 'sync_service.dart';
import '../../repositories/classification_repository.dart';

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
  final SmartFolderService _smartFolderService;

  final Set<String> _processedAssetIds = <String>{};
  final Set<String> _processedHashes = <String>{};
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
    SmartFolderService? smartFolderService,
  })  : _mediaObserver = mediaObserver ?? MediaObserverService(classifier: classifier),
        _db = db ?? DatabaseService(),
        _ocrService = ocrService ?? LocalOcrService(),
        _apiClient = apiClient ?? ApiClient(),
        _classifier = classifier,
        _notificationService = notificationService ?? NotificationService(),
        _syncService = syncService ?? SyncService(),
        _smartFolderService = smartFolderService ??
            SmartFolderService(
              classificationRepository: ClassificationRepository(
                apiClient: apiClient ?? ApiClient(),
                databaseService: db ?? DatabaseService(),
                mediaClassifier: classifier,
              ),
              databaseService: db ?? DatabaseService(),
            );

  bool get isListening => _isListening;
  ApiClient get apiClient => _apiClient;

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
    final fileHash = '${filePath}_${item.fileSize}_${item.createdAt.millisecondsSinceEpoch}'.hashCode.toRadixString(16);

    // 1. Duplicate Detection: In-memory check (by asset ID, file path, and file hash)
    if (_processedAssetIds.contains(assetId) ||
        _processedAssetIds.contains(filePath) ||
        _processedHashes.contains(fileHash)) {
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
      _processedHashes.add(fileHash);
      return;
    }

    _processedAssetIds.add(assetId);
    _processedAssetIds.add(filePath);
    _processedHashes.add(fileHash);

    debugPrint('[ScreenshotListenerService] New screenshot detected: ${item.fileName} (hash: $fileHash)');

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

      // 3. OCR Trigger (Google ML Kit on device)
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

      // 4. Sprint 1.3: AI Classification Engine via SmartFolderService
      String targetCatId = CategoryModel.unsortedId;
      String targetCatName = CategoryModel.unsortedName;
      String subcategory = 'General';
      double confidence = ocrConfidence;
      final tags = <TagModel>[];
      bool remoteSuccess = false;

      final classResult = await _smartFolderService.classifyAndOrganizeScreenshot(
        filePath: filePath,
        ocrText: extractedText,
        screenshotId: screenshotId,
        fileName: item.fileName,
        sourceApp: initialModel.sourceApp,
      );

      if (classResult != null) {
        targetCatId = classResult.categoryId;
        targetCatName = classResult.categoryName;
        subcategory = classResult.subcategory;
        confidence = classResult.confidence;
        remoteSuccess = classResult.isAutoCategorized;

        for (final tagStr in classResult.suggestedTags) {
          tags.add(TagModel(
            id: 'tag_${tagStr.toLowerCase().replaceAll(' ', '_')}',
            name: tagStr,
            colorHex: '6366F1',
          ));
        }
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

      // Queue metadata for backend sync if remote was skipped / offline
      if (!remoteSuccess) {
        await _db.addToSyncQueue(
          SyncQueueItemModel(
            id: const Uuid().v4(),
            endpoint: '/screenshots/scan',
            httpMethod: 'POST',
            payload: {
              'screenshot_id': screenshotId,
              'device_asset_id': assetId,
              'image_id': assetId,
              'file_path': filePath,
              'file_name': item.fileName,
              'file_size': item.fileSize,
              'captured_date': item.createdAt.toIso8601String(),
              'width': initialModel.width,
              'height': initialModel.height,
              'ocr_text': extractedText,
              'source_app': initialModel.sourceApp ?? 'Screenshot',
              'hash': fileHash,
              'category_id': targetCatId,
              'category_name': targetCatName,
              'sub_category_name': subcategory,
            },
            createdAt: DateTime.now(),
          ),
        );
        // Attempt background queue sync
        _syncService.processPendingQueue().ignore();
      }

      debugPrint(
        '[ScreenshotListenerService] Organized screenshot into $targetCatName / $subcategory (synced: $remoteSuccess)',
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
