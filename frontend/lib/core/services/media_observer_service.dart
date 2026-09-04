import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import '../constants/media_scanner_constants.dart';
import 'media_classifier.dart';

/// Representation of a newly detected screenshot from the MediaStore
class DiscoveredScreenshot {
  final String deviceAssetId;
  final String filePath;
  final String fileName;
  final int fileSize;
  final int width;
  final int height;
  final DateTime createdAt;
  final AssetEntity? assetEntity;

  const DiscoveredScreenshot({
    required this.deviceAssetId,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.width,
    required this.height,
    required this.createdAt,
    this.assetEntity,
  });
}

/// Service that observes Android MediaStore for newly added images/screenshots
/// via ContentObserver events and PhotoManager callbacks (Event-driven, no 1-second polling).
class MediaObserverService {
  static const EventChannel _eventChannel = EventChannel('contextvault/media_observer');

  final MediaClassifier _classifier;
  StreamSubscription? _platformSubscription;
  final StreamController<DiscoveredScreenshot> _screenshotController =
      StreamController<DiscoveredScreenshot>.broadcast();

  bool _isObserving = false;
  DateTime? _lastObservedTime;
  Timer? _debounceTimer;

  MediaObserverService({
    MediaClassifier classifier = const MediaClassifier(),
  }) : _classifier = classifier;

  bool get isObserving => _isObserving;
  DateTime? get lastObservedTime => _lastObservedTime;
  Stream<DiscoveredScreenshot> get onScreenshotDetected => _screenshotController.stream;

  /// Starts listening to MediaStore ContentObserver events
  Future<void> startObserving() async {
    if (_isObserving) return;
    _isObserving = true;
    _lastObservedTime = DateTime.now();

    // 1. Listen to native Android ContentObserver EventChannel
    if (!kIsWeb && Platform.isAndroid) {
      try {
        _platformSubscription = _eventChannel.receiveBroadcastStream().listen(
          (dynamic event) {
            _handleMediaChangeEvent('NativeContentObserver');
          },
          onError: (dynamic error) {
            debugPrint('[MediaObserverService] Native EventChannel error: $error');
          },
        );
      } catch (e) {
        debugPrint('[MediaObserverService] Could not bind native EventChannel: $e');
      }
    }

    // 2. Also register PhotoManager change callback
    try {
      PhotoManager.addChangeCallback(_onPhotoManagerChange);
      PhotoManager.startChangeNotify();
    } catch (e) {
      debugPrint('[MediaObserverService] PhotoManager changeNotify error: $e');
    }

    debugPrint('[MediaObserverService] Started MediaStore ContentObserver listener.');
  }

  /// Stops listening
  Future<void> stopObserving() async {
    if (!_isObserving) return;
    _isObserving = false;

    _debounceTimer?.cancel();
    await _platformSubscription?.cancel();
    _platformSubscription = null;

    try {
      PhotoManager.removeChangeCallback(_onPhotoManagerChange);
      PhotoManager.stopChangeNotify();
    } catch (_) {}

    debugPrint('[MediaObserverService] Stopped MediaStore ContentObserver listener.');
  }

  void _onPhotoManagerChange(MethodCall call) {
    _handleMediaChangeEvent('PhotoManagerChangeCallback');
  }

  /// Debounces rapid MediaStore burst events and checks for the newest screenshot
  void _handleMediaChangeEvent(String source) {
    if (!_isObserving) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      await _inspectLatestAssets();
    });
  }

  /// Queries the most recent assets in the gallery to see if a new screenshot was added
  Future<void> _inspectLatestAssets() async {
    try {
      // Query top recent images (within the last few minutes)
      final filterOption = FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        orders: [
          const OrderOption(
            type: OrderOptionType.createDate,
            asc: false,
          ),
        ],
      );

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
        filterOption: filterOption,
      );

      if (albums.isEmpty) return;

      // Check the latest 5 assets
      final recentAssets = await albums.first.getAssetListRange(start: 0, end: 5);

      for (final asset in recentAssets) {
        final file = await asset.file;
        if (file == null) continue;

        final filePath = file.path;
        final fileName = asset.title ?? file.uri.pathSegments.last;

        // Verify if this asset is a screenshot
        final isScreenshot = _isScreenshotMedia(
          filePath: filePath,
          fileName: fileName,
          asset: asset,
        );

        if (isScreenshot) {
          _lastObservedTime = DateTime.now();
          final discovered = DiscoveredScreenshot(
            deviceAssetId: asset.id,
            filePath: filePath,
            fileName: fileName,
            fileSize: await file.length(),
            width: asset.width,
            height: asset.height,
            createdAt: asset.createDateTime,
            assetEntity: asset,
          );

          _screenshotController.add(discovered);
        }
      }
    } catch (e) {
      debugPrint('[MediaObserverService] Error checking latest assets: $e');
    }
  }

  /// Determines if an asset is a screenshot across Android OEM paths and filenames
  bool _isScreenshotMedia({
    required String filePath,
    required String fileName,
    required AssetEntity asset,
  }) {
    final lowerPath = filePath.toLowerCase();
    final lowerName = fileName.toLowerCase();

    // 1. Direct path check against known OEM screenshot directories
    for (final path in MediaScannerConstants.screenshotPaths) {
      if (filePath.startsWith(path)) {
        return true;
      }
    }

    // 2. Relative path / folder check
    if (lowerPath.contains('/screenshots') ||
        lowerPath.contains('/screenshots/') ||
        lowerPath.contains('/pictures/screenshots') ||
        lowerPath.contains('/dcim/screenshots')) {
      return true;
    }

    // 3. File name pattern checks
    if (lowerName.startsWith('screenshot') ||
        lowerName.startsWith('screen_shot') ||
        lowerName.startsWith('screenshot_') ||
        lowerName.contains('screenshot')) {
      return true;
    }

    // 4. MediaClassifier check
    final classification = _classifier.classifyAndroidMedia(
      filePath: filePath,
      fileName: fileName,
      relativePath: asset.relativePath,
    );

    return classification == DeviceMediaType.screenshot;
  }

  void dispose() {
    stopObserving();
    _screenshotController.close();
  }
}
