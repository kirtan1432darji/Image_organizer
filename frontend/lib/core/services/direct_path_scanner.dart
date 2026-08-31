import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/screenshot_model.dart';
import '../constants/media_scanner_constants.dart';
import 'media_classifier.dart';

/// Representation of a file discovered directly via filesystem
class DiscoveredMediaItem {
  final String filePath;
  final String fileName;
  final int fileSize;
  final DateTime modifiedAt;
  final DeviceMediaType mediaType;
  final bool isVideo;

  const DiscoveredMediaItem({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.modifiedAt,
    required this.mediaType,
    required this.isVideo,
  });

  ScreenshotModel toScreenshotModel({
    String? categoryId,
    String? categoryName,
    String? sourceApp,
    String? deviceAssetId,
  }) {
    return ScreenshotModel(
      id: const Uuid().v4(),
      deviceAssetId: deviceAssetId ?? '',
      filePath: filePath,
      fileName: fileName,
      createdAt: modifiedAt,
      width: 1080,
      height: 2400,
      fileSize: fileSize,
      categoryId: categoryId ?? 'unsorted',
      categoryName: categoryName ?? 'Unsorted',
      subcategory: '',
      confidence: 0.0,
      sourceApp: sourceApp ?? mediaType.displayName,
      isFavorite: false,
      isReviewed: false,
      isSynced: false,
      ocrStatus: 'none',
      lastScannedAt: DateTime.now(),
      isMock: false,
    );
  }
}

/// Scanner for direct Android filesystem paths across OEMs
class DirectPathScanner {
  final MediaClassifier _classifier;

  const DirectPathScanner({
    MediaClassifier classifier = const MediaClassifier(),
  }) : _classifier = classifier;

  /// Scans direct Android filesystem directories in priority order.
  /// Strictly no-op on iOS, macOS, Windows, Linux, and Web.
  List<DiscoveredMediaItem> scanDirectories({
    bool onlyScreenshots = false,
    List<String>? customPaths,
    bool includeHiddenStatuses = false,
  }) {
    // 1. Strict platform guard: Android only
    if (kIsWeb || (!Platform.isAndroid)) {
      return const [];
    }

    final List<String> pathsToScan = customPaths ??
        (onlyScreenshots
            ? MediaScannerConstants.screenshotPaths
            : [
                ...MediaScannerConstants.screenshotPaths,
                ...MediaScannerConstants.screenRecordingPaths,
                ...MediaScannerConstants.cameraPaths,
                ...MediaScannerConstants.downloadPaths,
                ...MediaScannerConstants.whatsappImagePaths,
                if (includeHiddenStatuses)
                  ...MediaScannerConstants.whatsappStatusPaths,
                ...MediaScannerConstants.telegramImagePaths,
              ]);

    final Map<String, DiscoveredMediaItem> discovered = {};

    for (final folderPath in pathsToScan) {
      try {
        final dir = Directory(folderPath);
        if (!dir.existsSync()) continue;

        final isStatusFolder = folderPath.toLowerCase().contains('.statuses');
        final entities = dir.listSync(recursive: false, followLinks: false);

        for (final entity in entities) {
          if (entity is! File) continue;

          final fullPath = entity.path;
          final normalizedKey = fullPath.toLowerCase();

          // Deduplicate
          if (discovered.containsKey(normalizedKey)) continue;

          final fileName = fullPath.split(Platform.pathSeparator).last;

          // Skip hidden files unless specifically in .Statuses
          if (fileName.startsWith('.') && !isStatusFolder) {
            continue;
          }

          final ext = fileName.contains('.') ? fileName.split('.').last : '';
          if (!MediaScannerConstants.isSupportedExtension(ext)) {
            continue;
          }

          final isVideo = MediaScannerConstants.isVideoExtension(ext);
          int fileSize = 0;
          DateTime modifiedAt = DateTime.now();

          try {
            final stat = entity.statSync();
            fileSize = stat.size;
            modifiedAt = stat.modified;
          } catch (_) {}

          final mediaType = _classifier.classifyAndroidMedia(
            filePath: fullPath,
            fileName: fileName,
            isVideo: isVideo,
          );

          if (onlyScreenshots && mediaType != DeviceMediaType.screenshot) {
            continue;
          }

          discovered[normalizedKey] = DiscoveredMediaItem(
            filePath: fullPath,
            fileName: fileName,
            fileSize: fileSize,
            modifiedAt: modifiedAt,
            mediaType: mediaType,
            isVideo: isVideo,
          );
        }
      } catch (e) {
        // Gracefully ignore inaccessible or scoped storage restricted folders
        debugPrint('[DirectPathScanner] Skipping path $folderPath: $e');
      }
    }

    return discovered.values.toList();
  }
}
