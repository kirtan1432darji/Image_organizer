import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../../models/screenshot_model.dart';
import '../utils/result.dart';

abstract class ScreenshotScannerService {
  Future<PermissionState> requestPermission();
  Future<PermissionState> getPermissionState();
  Future<void> presentLimitedPhotoPicker();
  Future<Result<List<ScreenshotModel>>> scanScreenshots({
    bool onlyScreenshots = true,
    DateTime? since,
    Function(int current, int total)? onProgress,
  });
}

class PhotoManagerScannerService implements ScreenshotScannerService {
  final _uuid = const Uuid();

  @override
  Future<PermissionState> getPermissionState() async {
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        return PermissionState.authorized;
      }
      return await PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(),
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
        requestOption: const PermissionRequestOption(),
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
      if (Platform.isAndroid || Platform.isIOS) {
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
  }) async {
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        // Return empty on desktop / web unless real assets exist
        return Result.success([]);
      }

      final perm = await requestPermission();
      if (!perm.isAuth && !perm.hasAccess) {
        debugPrint('[ScannerService] Permission denied (State: $perm)');
        return Result.failure('Gallery permission denied. Please grant photo access in Settings.');
      }

      debugPrint('[ScannerService] Scanning albums... (Permission: $perm)');

      // 1. Fetch albums from MediaStore / PhotoManager
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: false,
      );

      if (albums.isEmpty) {
        albums = await PhotoManager.getAssetPathList(
          type: RequestType.image,
          onlyAll: true,
        );
      }

      debugPrint('[ScannerService] Found ${albums.length} total albums on device: ${albums.map((a) => a.name).toList()}');

      // 2. Identify screenshot-specific albums across all Android OEMs
      final List<AssetPathEntity> targetAlbums = [];
      if (onlyScreenshots) {
        for (final album in albums) {
          final name = album.name.toLowerCase();
          if (_isScreenshotAlbumName(name)) {
            targetAlbums.add(album);
          }
        }
      }

      // If no dedicated screenshot album is found, scan all images and filter
      bool shouldFilterAssetsByName = false;
      if (targetAlbums.isEmpty && albums.isNotEmpty) {
        targetAlbums.add(albums.first);
        if (onlyScreenshots) {
          shouldFilterAssetsByName = true;
        }
      }

      if (targetAlbums.isEmpty) {
        debugPrint('[ScannerService] No albums available on device.');
        return Result.success([]);
      }

      final Map<String, ScreenshotModel> scannedMap = {};
      int totalScannedCount = 0;

      // 3. Scan each target album with full pagination (no arbitrary first-100 cut-off)
      for (final album in targetAlbums) {
        final int totalAssets = await album.assetCountAsync;
        debugPrint('[ScannerService] Album "${album.name}" has $totalAssets assets. Fetching with pagination...');

        const int pageSize = 80;
        int currentPage = 0;

        while (currentPage * pageSize < totalAssets) {
          final int start = currentPage * pageSize;
          final int end = (start + pageSize).clamp(0, totalAssets);

          final List<AssetEntity> pageAssets = await album.getAssetListRange(
            start: start,
            end: end,
          );

          if (pageAssets.isEmpty) break;

          for (final asset in pageAssets) {
            // Check deduplication
            if (scannedMap.containsKey(asset.id)) continue;

            final fileName = asset.title ?? 'Screenshot_${asset.createDateTime.millisecondsSinceEpoch}.png';

            // Filter if we are scanning from general album
            if (shouldFilterAssetsByName && !_isScreenshotFileName(fileName)) {
              continue;
            }

            // Optional incremental filter
            if (since != null && asset.createDateTime.isBefore(since)) {
              continue;
            }

            // Inferred source application name
            final sourceApp = _inferSourceApp(fileName);

            // Attempt to resolve file path for fallback (do not skip if null!)
            String resolvedPath = '';
            try {
              final f = await asset.file;
              if (f != null) {
                resolvedPath = f.path;
              }
            } catch (_) {
              // Scoped storage might not yield raw file path, asset.id is primary
            }

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

      final results = scannedMap.values.toList();
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      debugPrint('[ScannerService] Scan complete. Found ${results.length} valid device screenshots.');

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

  bool _isScreenshotFileName(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.contains('screenshot') ||
        lower.contains('screen_shot') ||
        lower.contains('screenshot_') ||
        lower.contains('scrn') ||
        lower.contains('capture') ||
        lower.contains('screencap');
  }

  String? _inferSourceApp(String pathOrTitle) {
    final lower = pathOrTitle.toLowerCase();
    if (lower.contains('whatsapp')) return 'WhatsApp';
    if (lower.contains('slack')) return 'Slack';
    if (lower.contains('twitter') || lower.contains('x_') || lower.contains('x.com')) return 'X / Twitter';
    if (lower.contains('instagram')) return 'Instagram';
    if (lower.contains('amazon')) return 'Amazon';
    if (lower.contains('chrome')) return 'Google Chrome';
    if (lower.contains('safari')) return 'Safari';
    if (lower.contains('youtube')) return 'YouTube';
    if (lower.contains('telegram')) return 'Telegram';
    if (lower.contains('reddit')) return 'Reddit';
    if (lower.contains('linkedin')) return 'LinkedIn';
    return null;
  }
}
