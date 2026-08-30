import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/screenshot_scanner_service.dart';
import '../core/services/database_service.dart';
import '../models/screenshot_model.dart';
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

  const ScannerState({
    this.isScanning = false,
    this.currentProgress = 0,
    this.totalProgress = 0,
    this.statusMessage = 'Idle',
    this.newlyFound = const [],
  });

  ScannerState copyWith({
    bool? isScanning,
    int? currentProgress,
    int? totalProgress,
    String? statusMessage,
    List<ScreenshotModel>? newlyFound,
  }) {
    return ScannerState(
      isScanning: isScanning ?? this.isScanning,
      currentProgress: currentProgress ?? this.currentProgress,
      totalProgress: totalProgress ?? this.totalProgress,
      statusMessage: statusMessage ?? this.statusMessage,
      newlyFound: newlyFound ?? this.newlyFound,
    );
  }
}

class ScannerNotifier extends StateNotifier<ScannerState> {
  final Ref _ref;
  final ScreenshotScannerService _scanner;
  final DatabaseService _db;

  ScannerNotifier(this._ref, this._scanner, this._db) : super(const ScannerState());

  Future<void> startScan({bool onlyScreenshots = true}) async {
    if (state.isScanning) return;

    state = state.copyWith(
      isScanning: true,
      currentProgress: 0,
      totalProgress: 0,
      statusMessage: 'Requesting gallery permissions...',
      newlyFound: [],
    );

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
      for (final item in items) {
        await _db.insertScreenshot(item);
      }

      state = state.copyWith(
        isScanning: false,
        statusMessage: 'Scan complete. Found ${items.length} screenshots.',
        newlyFound: items,
      );

      // Refresh screenshot and stats list
      _ref.read(screenshotListProvider.notifier).refresh();
    } else {
      state = state.copyWith(
        isScanning: false,
        statusMessage: 'Scan failed: ${result.errorOrNull}',
      );
    }
  }
}

final scannerProvider = StateNotifierProvider<ScannerNotifier, ScannerState>((ref) {
  final scanner = ref.watch(scannerServiceProvider);
  final db = DatabaseService();
  return ScannerNotifier(ref, scanner, db);
});
