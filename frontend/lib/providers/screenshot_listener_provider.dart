import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/screenshot_listener_service.dart';
import '../models/screenshot_model.dart';
import 'category_provider.dart';
import 'folder_provider.dart';
import 'scanner_provider.dart';
import 'screenshot_provider.dart';
import 'settings_provider.dart';

final screenshotListenerServiceProvider = Provider<ScreenshotListenerService>((ref) {
  final service = ScreenshotListenerService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

class ScreenshotListenerState {
  final bool isMonitoring;
  final bool autoDetectEnabled;
  final bool notificationsEnabled;
  final ScreenshotModel? lastDetectedScreenshot;
  final DateTime? lastScanTime;
  final int detectedCount;
  final String statusMessage;

  const ScreenshotListenerState({
    this.isMonitoring = false,
    this.autoDetectEnabled = true,
    this.notificationsEnabled = true,
    this.lastDetectedScreenshot,
    this.lastScanTime,
    this.detectedCount = 0,
    this.statusMessage = 'Initializing...',
  });

  ScreenshotListenerState copyWith({
    bool? isMonitoring,
    bool? autoDetectEnabled,
    bool? notificationsEnabled,
    ScreenshotModel? lastDetectedScreenshot,
    DateTime? lastScanTime,
    int? detectedCount,
    String? statusMessage,
  }) {
    return ScreenshotListenerState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      autoDetectEnabled: autoDetectEnabled ?? this.autoDetectEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lastDetectedScreenshot: lastDetectedScreenshot ?? this.lastDetectedScreenshot,
      lastScanTime: lastScanTime ?? this.lastScanTime,
      detectedCount: detectedCount ?? this.detectedCount,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class ScreenshotListenerNotifier extends StateNotifier<ScreenshotListenerState> {
  final Ref _ref;
  final ScreenshotListenerService _service;

  ScreenshotListenerNotifier(this._ref, this._service)
      : super(const ScreenshotListenerState()) {
    _init();
  }

  void _init() {
    // 1. Hook pipeline callback to refresh dependent UI providers
    _service.onScreenshotOrganized = _onScreenshotOrganized;

    // 2. Read initial settings
    final settings = _ref.read(settingsProvider);
    _service.notificationsEnabled = settings.notificationsEnabled;

    state = state.copyWith(
      autoDetectEnabled: settings.autoDetectScreenshots,
      notificationsEnabled: settings.notificationsEnabled,
      lastScanTime: settings.lastScanTime,
      statusMessage: settings.autoDetectScreenshots
          ? 'Active (ContentObserver)'
          : 'Monitoring Paused (Disabled in Settings)',
    );

    if (settings.autoDetectScreenshots) {
      startMonitoring();
    }

    // 3. Reactively update when settings change
    _ref.listen<SettingsState>(settingsProvider, (previous, next) {
      if (previous?.autoDetectScreenshots != next.autoDetectScreenshots) {
        if (next.autoDetectScreenshots) {
          startMonitoring();
        } else {
          stopMonitoring();
        }
      }
      if (previous?.notificationsEnabled != next.notificationsEnabled) {
        _service.notificationsEnabled = next.notificationsEnabled;
        state = state.copyWith(notificationsEnabled: next.notificationsEnabled);
      }
    });
  }

  Future<void> startMonitoring() async {
    try {
      await _service.start();
      state = state.copyWith(
        isMonitoring: true,
        autoDetectEnabled: true,
        statusMessage: 'Active (ContentObserver)',
      );
    } catch (e) {
      debugPrint('[ScreenshotListenerNotifier] Error starting monitoring: $e');
      state = state.copyWith(
        isMonitoring: false,
        statusMessage: 'Error starting listener: $e',
      );
    }
  }

  Future<void> stopMonitoring() async {
    try {
      await _service.stop();
      state = state.copyWith(
        isMonitoring: false,
        statusMessage: 'Monitoring Paused',
      );
    } catch (e) {
      debugPrint('[ScreenshotListenerNotifier] Error stopping monitoring: $e');
    }
  }

  Future<void> toggleAutoDetect(bool enabled) async {
    await _ref.read(settingsProvider.notifier).setAutoDetectScreenshots(enabled);
    state = state.copyWith(
      autoDetectEnabled: enabled,
      statusMessage: enabled ? 'Active (ContentObserver)' : 'Monitoring Paused',
    );
  }

  Future<void> toggleNotifications(bool enabled) async {
    await _ref.read(settingsProvider.notifier).setScreenshotNotifications(enabled);
    _service.notificationsEnabled = enabled;
    state = state.copyWith(notificationsEnabled: enabled);
  }

  Future<void> triggerManualScan() async {
    final now = DateTime.now();
    await _ref.read(scannerProvider.notifier).startScan();
    await _ref.read(settingsProvider.notifier).setLastScanTime(now);
    state = state.copyWith(lastScanTime: now);
  }

  void _onScreenshotOrganized(ScreenshotModel screenshot) {
    final now = DateTime.now();
    _ref.read(settingsProvider.notifier).setLastScanTime(now);

    state = state.copyWith(
      lastDetectedScreenshot: screenshot,
      lastScanTime: now,
      detectedCount: state.detectedCount + 1,
      statusMessage: 'Processed ${screenshot.fileName} → ${screenshot.categoryName}',
    );

    // Refresh UI providers across Home, Folders, and Dashboard stats
    _ref.read(screenshotListProvider.notifier).refresh();
    _ref.read(categoryListProvider.notifier).syncRemote();
    _ref.invalidate(folderListProvider);
    _ref.invalidate(statsProvider);
    _ref.invalidate(recentScreenshotsProvider);
  }
}

final screenshotListenerProvider =
    StateNotifierProvider<ScreenshotListenerNotifier, ScreenshotListenerState>((ref) {
  final service = ref.watch(screenshotListenerServiceProvider);
  return ScreenshotListenerNotifier(ref, service);
});
