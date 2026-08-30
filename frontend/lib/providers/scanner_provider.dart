import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../core/services/screenshot_scanner_service.dart';
import '../models/screenshot_model.dart';
import 'category_provider.dart';
import 'screenshot_provider.dart';

final scannerServiceProvider = Provider<ScreenshotScannerService>((ref) {
  return PhotoManagerScannerService();
});

class ScannerState {
  final bool isScanning;
  final int currentProgress;
  final int totalProgress;
  final String statusMessage;
  final List<ScreenshotModel> newlyFound;
  final bool isLimitedPermission;
  final bool isPermissionDenied;
  final int indexedCount;
  final DateTime? lastScanTime;

  const ScannerState({
    this.isScanning = false,
    this.currentProgress = 0,
    this.totalProgress = 0,
    this.statusMessage = 'Idle',
    this.newlyFound = const [],
    this.isLimitedPermission = false,
    this.isPermissionDenied = false,
    this.indexedCount = 0,
    this.lastScanTime,
  });

  ScannerState copyWith({
    bool? isScanning,
    int? currentProgress,
    int? totalProgress,
    String? statusMessage,
    List<ScreenshotModel>? newlyFound,
    bool? isLimitedPermission,
    bool? isPermissionDenied,
    int? indexedCount,
    DateTime? lastScanTime,
  }) {
    return ScannerState(
      isScanning: isScanning ?? this.isScanning,
      currentProgress: currentProgress ?? this.currentProgress,
      totalProgress: totalProgress ?? this.totalProgress,
      statusMessage: statusMessage ?? this.statusMessage,
      newlyFound: newlyFound ?? this.newlyFound,
      isLimitedPermission: isLimitedPermission ?? this.isLimitedPermission,
      isPermissionDenied: isPermissionDenied ?? this.isPermissionDenied,
      indexedCount: indexedCount ?? this.indexedCount,
      lastScanTime: lastScanTime ?? this.lastScanTime,
    );
  }
}

class ScannerNotifier extends StateNotifier<ScannerState> {
  final Ref _ref;
  final ScreenshotScannerService _scanner;

  ScannerNotifier(this._ref, this._scanner) : super(const ScannerState()) {
    checkPermissionState();
  }

  Future<void> checkPermissionState() async {
    try {
      final ps = await _scanner.getPermissionState();
      state = state.copyWith(
        isLimitedPermission: ps == PermissionState.limited,
        isPermissionDenied: ps == PermissionState.denied || ps == PermissionState.restricted,
      );
    } catch (e) {
      debugPrint('[ScannerNotifier] Error checking permission: $e');
    }
  }

  Future<void> manageLimitedPhotos() async {
    await _scanner.presentLimitedPhotoPicker();
    // Re-scan after managing photos
    await startScan();
  }

  Future<void> openSettings() async {
    await PhotoManager.openSetting();
  }

  Future<void> startScan({bool onlyScreenshots = true}) async {
    if (state.isScanning) return;

    state = state.copyWith(
      isScanning: true,
      currentProgress: 0,
      totalProgress: 0,
      statusMessage: 'Scanning phone screenshots...',
      newlyFound: [],
      isPermissionDenied: false,
    );

    final ps = await _scanner.getPermissionState();
    final isLimited = ps == PermissionState.limited;

    final result = await _scanner.scanScreenshots(
      onlyScreenshots: onlyScreenshots,
      onProgress: (current, total) {
        state = state.copyWith(
          currentProgress: current,
          totalProgress: total,
          statusMessage: 'Scanning $current of $total screenshots...',
        );
      },
    );

    if (result.isSuccess) {
      final items = result.dataOrNull ?? [];
      final repo = _ref.read(screenshotRepositoryProvider);
      
      await repo.saveScannedScreenshots(items);

      final message = items.isEmpty
          ? 'Scan complete. No screenshots found in gallery.'
          : 'Indexed ${items.length} screenshots.';

      state = state.copyWith(
        isScanning: false,
        statusMessage: message,
        newlyFound: items,
        isLimitedPermission: isLimited,
        isPermissionDenied: false,
        indexedCount: items.length,
        lastScanTime: DateTime.now(),
      );

      // Refresh all dependent providers immediately
      await _ref.read(screenshotListProvider.notifier).refresh();
      await _ref.read(categoryListProvider.notifier).syncRemote();
      _ref.invalidate(statsProvider);
      _ref.invalidate(recentScreenshotsProvider);
    } else {
      final errorMsg = result.errorOrNull ?? 'Scan failed';
      final isDenied = errorMsg.toLowerCase().contains('denied') ||
          errorMsg.toLowerCase().contains('permission');

      state = state.copyWith(
        isScanning: false,
        statusMessage: errorMsg,
        isLimitedPermission: isLimited,
        isPermissionDenied: isDenied,
      );
    }
  }
}

final scannerProvider = StateNotifierProvider<ScannerNotifier, ScannerState>((ref) {
  final scanner = ref.watch(scannerServiceProvider);
  return ScannerNotifier(ref, scanner);
});
