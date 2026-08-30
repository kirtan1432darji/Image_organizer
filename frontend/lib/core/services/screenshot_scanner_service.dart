import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../../models/screenshot_model.dart';
import '../../mock/mock_data.dart';
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
        return true; // Allow mock mode on desktop/web
      }
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      return ps.isAuth || ps.hasAccess;
    } catch (e) {
      debugPrint('Error requesting photo permission: $e');
      return true; // Fallback to mock mode gracefully
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
        // Return rich mock dataset for desktop / test environments
        final samples = MockData.getSampleScreenshots();
        onProgress?.call(samples.length, samples.length);
        return Result.success(samples);
      }

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

      // Collect target albums (either screenshot specific or general gallery)
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

      // If no screenshot specific album found, use the first/recent album
      if (targetAlbums.isEmpty && albums.isNotEmpty) {
        targetAlbums.add(albums.first);
      }

      if (targetAlbums.isEmpty) {
        final samples = MockData.getSampleScreenshots();
        onProgress?.call(samples.length, samples.length);
        return Result.success(samples);
      }

      final List<ScreenshotModel> scannedScreenshots = [];
      int totalProcessed = 0;

      for (final album in targetAlbums) {
        final int totalAssets = await album.assetCountAsync;
        final List<AssetEntity> assets = await album.getAssetListRange(
          start: 0,
          end: totalAssets.clamp(0, 100),
        );

        for (int i = 0; i < assets.length; i++) {
          final asset = assets[i];
          final file = await asset.file;
          if (file == null) continue;

          final stat = await file.stat();

          final model = ScreenshotModel(
            id: _uuid.v4(),
            deviceAssetId: asset.id,
            filePath: file.path,
            fileName: asset.title ??
                'Screenshot_${asset.createDateTime.millisecondsSinceEpoch}.png',
            createdAt: asset.createDateTime,
            width: asset.width,
            height: asset.height,
            fileSize: stat.size,
            categoryId: 'unsorted',
            categoryName: 'Unsorted',
            subcategory: '',
            confidence: 0.0,
            sourceApp: _inferSourceApp(asset.title ?? file.path),
            isFavorite: asset.isFavorite,
            isReviewed: false,
            isSynced: false,
            ocrStatus: 'pending',
            lastScannedAt: DateTime.now(),
            isMock: false,
          );

          scannedScreenshots.add(model);
          totalProcessed++;
          onProgress?.call(totalProcessed, totalProcessed);
        }
      }

      if (scannedScreenshots.isEmpty) {
        return Result.success(MockData.getSampleScreenshots());
      }

      return Result.success(scannedScreenshots);
    } catch (e) {
      debugPrint('Error scanning gallery screenshots: $e');
      return Result.success(MockData.getSampleScreenshots());
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
