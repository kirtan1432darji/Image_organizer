import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../../models/screenshot_model.dart';
import '../utils/result.dart';

abstract class ScreenshotScannerService {
  Future<bool> requestPermission();
  Future<Result<List<ScreenshotModel>>> scanScreenshots({
    bool onlyScreenshots = true,
    DateTime? since,
    Function(int current, int total)? onProgress,
  });
}

class PhotoManagerScannerService implements ScreenshotScannerService {
  final _uuid = const Uuid();

  @override
  Future<bool> requestPermission() async {
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        return true;
      }
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      return ps.isAuth || ps.hasAccess;
    } catch (e) {
      debugPrint('Error requesting photo permission: $e');
      return false;
    }
  }

  @override
  Future<Result<List<ScreenshotModel>>> scanScreenshots({
    bool onlyScreenshots = true,
    DateTime? since,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      final hasPerm = await requestPermission();
      if (!hasPerm) {
        return Result.failure('Gallery permission not granted');
      }

      // Fetch albums
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

      // Filter target albums (either screenshot specific or general gallery)
      final List<AssetPathEntity> targetAlbums = [];
      if (onlyScreenshots) {
        for (final album in albums) {
          final name = album.name.toLowerCase();
          if (name.contains('screenshot') ||
              name.contains('screen_shot') ||
              name.contains('capture') ||
              name.contains('screencap')) {
            targetAlbums.add(album);
          }
        }
      }

      // If no screenshot specific album found, use the default/recent albums
      if (targetAlbums.isEmpty && albums.isNotEmpty) {
        targetAlbums.addAll(albums);
      }

      if (targetAlbums.isEmpty) {
        return Result.success([]);
      }

      final Map<String, ScreenshotModel> scannedMap = {};
      const int pageSize = 80;
      int totalProcessed = 0;

      for (final album in targetAlbums) {
        final int totalAssets = await album.assetCountAsync;
        int page = 0;

        while (page * pageSize < totalAssets) {
          final List<AssetEntity> assets = await album.getAssetListPaged(
            page: page,
            size: pageSize,
          );

          if (assets.isEmpty) break;

          for (final asset in assets) {
            // Filter by date if requested
            if (since != null && asset.createDateTime.isBefore(since)) {
              continue;
            }

            // Deduplicate by deviceAssetId
            if (scannedMap.containsKey(asset.id)) {
              continue;
            }

            // Try to obtain file path if available, but do not skip if null
            String localPath = '';
            int fileSize = 0;
            try {
              final file = await asset.file;
              if (file != null) {
                localPath = file.path;
                fileSize = await file.length();
              }
            } catch (_) {}

            final model = ScreenshotModel(
              id: _uuid.v4(),
              deviceAssetId: asset.id,
              filePath: localPath,
              fileName: asset.title ??
                  'Screenshot_${asset.createDateTime.millisecondsSinceEpoch}.png',
              createdAt: asset.createDateTime,
              width: asset.width,
              height: asset.height,
              fileSize: fileSize,
              categoryId: 'unsorted',
              categoryName: 'Unsorted',
              subcategory: '',
              confidence: 0.0,
              sourceApp: _inferSourceApp(asset.title ?? localPath),
              isFavorite: asset.isFavorite,
              isReviewed: false,
              isSynced: false,
              ocrStatus: 'pending',
              lastScannedAt: DateTime.now(),
              isMock: false,
            );

            scannedMap[asset.id] = model;
            totalProcessed++;
            onProgress?.call(totalProcessed, totalAssets);
          }

          page++;
        }
      }

      return Result.success(scannedMap.values.toList());
    } catch (e) {
      debugPrint('Error scanning gallery screenshots: $e');
      return Result.failure('Failed to scan screenshots: $e');
    }
  }

  String? _inferSourceApp(String pathOrTitle) {
    final lower = pathOrTitle.toLowerCase();
    if (lower.contains('whatsapp')) return 'WhatsApp';
    if (lower.contains('slack')) return 'Slack';
    if (lower.contains('twitter') || lower.contains('x_')) return 'X / Twitter';
    if (lower.contains('instagram')) return 'Instagram';
    if (lower.contains('amazon')) return 'Amazon';
    if (lower.contains('chrome') || lower.contains('safari')) return 'Browser';
    return null;
  }
}
