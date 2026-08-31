import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../../models/screenshot_model.dart';
import '../constants/media_scanner_constants.dart';
import '../utils/result.dart';
import 'direct_path_scanner.dart';
import 'media_classifier.dart';

abstract class ScreenshotScannerService {
  Future<PermissionState> requestPermission();
  Future<PermissionState> getPermissionState();
  Future<void> presentLimitedPhotoPicker();

  /// Scans device screenshots (compatible with existing mobile app callers)
  Future<Result<List<ScreenshotModel>>> scanScreenshots({
    bool onlyScreenshots = true,
    DateTime? since,
    Function(int current, int total)? onProgress,
  });

  /// Scans all authorized device media across images and videos
  Future<Result<List<ScreenshotModel>>> scanAllMedia({
    List<DeviceMediaType>? targetTypes,
    DateTime? since,
    Function(int current, int total)? onProgress,
  });
}

class PhotoManagerScannerService implements ScreenshotScannerService {
  final _uuid = const Uuid();
  final MediaClassifier _classifier;
  final DirectPathScanner _directPathScanner;

  PhotoManagerScannerService({
    MediaClassifier classifier = const MediaClassifier(),
    DirectPathScanner? directPathScanner,
  })  : _classifier = classifier,
        _directPathScanner = directPathScanner ??
            DirectPathScanner(classifier: classifier);

  @override
  Future<PermissionState> getPermissionState() async {
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        return PermissionState.authorized;
      }
      return await PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.common,
            mediaLocation: false,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[ScannerService] Error checking permission: $e');
      return PermissionState.denied;
    }
  }

  @override
  Future<PermissionState> requestPermission() async {
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        return PermissionState.authorized;
      }
      final PermissionState ps = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.common,
            mediaLocation: false,
          ),
        ),
      );
      debugPrint('[ScannerService] Permission requested. Result: $ps');
      return ps;
    } catch (e) {
      debugPrint('[ScannerService] Exception requesting permission: $e');
      return PermissionState.denied;
    }
  }

  @override
  Future<void> presentLimitedPhotoPicker() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await PhotoManager.presentLimited();
      }
    } catch (e) {
      debugPrint('[ScannerService] Error opening limited picker: $e');
    }
  }

  @override
  Future<Result<List<ScreenshotModel>>> scanScreenshots({
    bool onlyScreenshots = true,
    DateTime? since,
    Function(int current, int total)? onProgress,
  }) {
    return _scanMediaInternal(
      onlyScreenshots: onlyScreenshots,
      targetTypes: onlyScreenshots ? [DeviceMediaType.screenshot] : null,
      since: since,
      onProgress: onProgress,
    );
  }

  @override
  Future<Result<List<ScreenshotModel>>> scanAllMedia({
    List<DeviceMediaType>? targetTypes,
    DateTime? since,
    Function(int current, int total)? onProgress,
  }) {
    return _scanMediaInternal(
      onlyScreenshots: false,
      targetTypes: targetTypes,
      since: since,
      onProgress: onProgress,
    );
  }

  Future<Result<List<ScreenshotModel>>> _scanMediaInternal({
    required bool onlyScreenshots,
    List<DeviceMediaType>? targetTypes,
    DateTime? since,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        return Result.success([]);
      }

      final perm = await requestPermission();
      if (!perm.isAuth && !perm.hasAccess) {
        debugPrint('[ScannerService] Permission denied (State: $perm)');
        return Result.failure(
          'Gallery permission denied. Please grant photo access in Settings.',
        );
      }

      debugPrint('[ScannerService] Starting discovery... (Permission: $perm, Platform: ${Platform.operatingSystem})');

      final Map<String, ScreenshotModel> scannedMap = {};
      final Set<String> canonicalPathSet = {};
      int totalScannedCount = 0;

      // -----------------------------------------------------------------
      // 1. PRIMARY DISCOVERY: MediaStore (Android) & PhotoKit (iOS)
      // -----------------------------------------------------------------
      final RequestType reqType = onlyScreenshots ? RequestType.image : RequestType.common;
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: reqType,
        onlyAll: false,
      );

      if (albums.isEmpty) {
        albums = await PhotoManager.getAssetPathList(
          type: reqType,
          onlyAll: true,
        );
      }

      debugPrint('[ScannerService] Found ${albums.length} albums via PhotoManager.');

      // Filter target albums if only scanning screenshots
      List<AssetPathEntity> albumsToScan = albums;
      bool filterAssetsByNameFallback = false;

      if (onlyScreenshots) {
        final screenshotAlbums = albums.where((a) {
          final name = a.name.toLowerCase();
          return _isScreenshotAlbumName(name);
        }).toList();

        if (screenshotAlbums.isNotEmpty) {
          albumsToScan = screenshotAlbums;
        } else if (albums.isNotEmpty) {
          // If no explicit screenshot album exists, scan general album and filter by file name
          albumsToScan = [albums.first];
          filterAssetsByNameFallback = true;
        }
      }

      for (final album in albumsToScan) {
        final int totalAssets = await album.assetCountAsync;
        const int pageSize = 80;
        int currentPage = 0;

        final isScreenshotSmartAlbum = album.isAll || album.name.toLowerCase() == 'screenshots';
        final isScreenRecordingSmartAlbum = album.name.toLowerCase().contains('screen recording');

        while (currentPage * pageSize < totalAssets) {
          final int start = currentPage * pageSize;
          final int end = (start + pageSize).clamp(0, totalAssets);

          final List<AssetEntity> pageAssets = await album.getAssetListRange(
            start: start,
            end: end,
          );

          if (pageAssets.isEmpty) break;

          for (final asset in pageAssets) {
            // Deduplicate by PhotoKit / MediaStore asset ID
            if (scannedMap.containsKey(asset.id)) continue;

            final fileName = asset.title ??
                'Media_${asset.createDateTime.millisecondsSinceEpoch}.${asset.type == AssetType.video ? "mp4" : "png"}';

            if (filterAssetsByNameFallback && !_classifier.isScreenshotFileName(fileName)) {
              continue;
            }

            if (since != null && asset.createDateTime.isBefore(since)) {
              continue;
            }

            // Resolve file path for fallback caching & deduplication (do not block if null)
            String resolvedPath = '';
            try {
              final f = await asset.file;
              if (f != null) {
                resolvedPath = f.path;
                canonicalPathSet.add(resolvedPath.toLowerCase());
              }
            } catch (_) {}

            // Classify according to platform PhotoKit or Android MediaStore
            final DeviceMediaType mediaType = Platform.isIOS
                ? _classifier.classifyIosMedia(
                    albumName: album.name,
                    isScreenshotSmartAlbum: isScreenshotSmartAlbum,
                    isScreenRecordingSmartAlbum: isScreenRecordingSmartAlbum,
                    fileName: fileName,
                    isVideo: asset.type == AssetType.video,
                  )
                : _classifier.classifyAndroidMedia(
                    filePath: resolvedPath,
                    albumName: album.name,
                    fileName: fileName,
                    mimeType: asset.mimeType,
                    isVideo: asset.type == AssetType.video,
                  );

            if (onlyScreenshots && mediaType != DeviceMediaType.screenshot) {
              continue;
            }

            if (targetTypes != null && !targetTypes.contains(mediaType)) {
              continue;
            }

            final sourceApp = _classifier.inferSourceApp(resolvedPath.isNotEmpty ? resolvedPath : fileName) ??
                mediaType.displayName;

            final model = ScreenshotModel(
              id: _uuid.v4(),
              deviceAssetId: asset.id,
              filePath: resolvedPath,
              fileName: fileName,
              createdAt: asset.createDateTime,
              width: asset.width > 0 ? asset.width : 1080,
              height: asset.height > 0 ? asset.height : 2400,
              fileSize: 0,
              categoryId: 'unsorted',
              categoryName: 'Unsorted',
              subcategory: '',
              confidence: 0.0,
              sourceApp: sourceApp,
              isFavorite: asset.isFavorite,
              isReviewed: false,
              isSynced: false,
              ocrStatus: 'none',
              lastScannedAt: DateTime.now(),
              isMock: false,
            );

            scannedMap[asset.id] = model;
            totalScannedCount++;
            onProgress?.call(totalScannedCount, totalAssets);
          }

          currentPage++;
        }
      }

      // -----------------------------------------------------------------
      // 2. AUXILIARY DIRECT FILESYSTEM SCANNING (Android Only)
      // -----------------------------------------------------------------
      if (Platform.isAndroid && !kIsWeb) {
        final directItems = _directPathScanner.scanDirectories(
          onlyScreenshots: onlyScreenshots,
        );

        for (final item in directItems) {
          final normalizedKey = item.filePath.toLowerCase();
          // Avoid duplicate entries if already discovered via MediaStore
          if (canonicalPathSet.contains(normalizedKey)) continue;
          canonicalPathSet.add(normalizedKey);

          if (targetTypes != null && !targetTypes.contains(item.mediaType)) {
            continue;
          }

          final sourceApp = _classifier.inferSourceApp(item.filePath) ?? item.mediaType.displayName;
          final model = item.toScreenshotModel(sourceApp: sourceApp);

          scannedMap[model.id] = model;
          totalScannedCount++;
        }
      }

      final results = scannedMap.values.toList();
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      debugPrint('[ScannerService] Scan complete. Discovered ${results.length} total media items.');

      return Result.success(results);
    } catch (e, stack) {
      debugPrint('[ScannerService] Unexpected scan exception: $e\n$stack');
      return Result.failure('Error scanning device gallery: $e');
    }
  }

  bool _isScreenshotAlbumName(String name) {
    final lower = name.toLowerCase();
    return lower.contains('screenshot') ||
        lower.contains('screen_shot') ||
        lower.contains('screen shot') ||
        lower.contains('capture') ||
        lower.contains('captures') ||
        lower.contains('screencap') ||
        lower.contains('screencaps') ||
        lower.contains('screen recording') ||
        lower.contains('dcim/screenshots') ||
        lower.contains('pictures/screenshots');
  }
}
