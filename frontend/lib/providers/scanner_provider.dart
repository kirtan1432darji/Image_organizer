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

  const ScannerState({
    this.isScanning = false,
    this.currentProgress = 0,
    this.totalProgress = 0,
    this.statusMessage = 'Idle',
    this.newlyFound = const [],
    this.isLimitedPermission = false,
  });

  ScannerState copyWith({
    bool? isScanning,
    int? currentProgress,
    int? totalProgress,
    String? statusMessage,
    List<ScreenshotModel>? newlyFound,
    bool? isLimitedPermission,
  }) {
    return ScannerState(
      isScanning: isScanning ?? this.isScanning,
      currentProgress: currentProgress ?? this.currentProgress,
      totalProgress: totalProgress ?? this.totalProgress,
      statusMessage: statusMessage ?? this.statusMessage,
      newlyFound: newlyFound ?? this.newlyFound,
      isLimitedPermission: isLimitedPermission ?? this.isLimitedPermission,
    );
  }
}

class ScannerNotifier extends StateNotifier<ScannerState> {
  final Ref _ref;
  final ScreenshotScannerService _scanner;

  ScannerNotifier(this._ref, this._scanner) : super(const ScannerState()) {
    _checkPermissionState();
  }

  Future<void> _checkPermissionState() async {
    final ps = await _scanner.getPermissionState();
    if (ps == PermissionState.limited) {
      state = state.copyWith(isLimitedPermission: true);
    }
  }

  Future<void> manageLimitedPhotos() async {
    await _scanner.presentLimitedPhotoPicker();
    // Re-scan after managing photos
    await startScan();
  }

  Future<void> startScan({bool onlyScreenshots = true}) async {
    if (state.isScanning) return;

    state = state.copyWith(
      isScanning: true,
      currentProgress: 0,
      totalProgress: 0,
      statusMessage: 'Scanning phone screenshots...',
      newlyFound: [],
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

      state = state.copyWith(
        isScanning: false,
        statusMessage: items.isEmpty
            ? 'No screenshots found on device.'
            : 'Scan complete. Indexed ${items.length} screenshots.',
        newlyFound: items,
        isLimitedPermission: isLimited,
      );

      // Refresh screenshot list and category counters
      await _ref.read(screenshotListProvider.notifier).refresh();
      await _ref.read(categoryListProvider.notifier).syncRemote();
    } else {
      state = state.copyWith(
        isScanning: false,
        statusMessage: result.errorOrNull ?? 'Scan failed',
        isLimitedPermission: isLimited,
      );
    }
  }
}

final scannerProvider = StateNotifierProvider<ScannerNotifier, ScannerState>((ref) {
  final scanner = ref.watch(scannerServiceProvider);
  return ScannerNotifier(ref, scanner);
});
