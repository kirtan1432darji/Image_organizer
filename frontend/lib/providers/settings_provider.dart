import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';
import '../repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});

class SettingsState {
  final ThemeMode themeMode;
  final bool autoScan;
  final bool autoDetectScreenshots;
  final bool notificationsEnabled;
  final bool scanOnlyScreenshots;
  final String backendUrl;
  final bool isFirstLaunch;
  final DateTime? lastScanTime;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.autoScan = true,
    this.autoDetectScreenshots = true,
    this.notificationsEnabled = true,
    this.scanOnlyScreenshots = true,
    this.backendUrl = ApiConstants.defaultBaseUrl,
    this.isFirstLaunch = false,
    this.lastScanTime,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? autoScan,
    bool? autoDetectScreenshots,
    bool? notificationsEnabled,
    bool? scanOnlyScreenshots,
    String? backendUrl,
    bool? isFirstLaunch,
    DateTime? lastScanTime,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      autoScan: autoScan ?? this.autoScan,
      autoDetectScreenshots: autoDetectScreenshots ?? this.autoDetectScreenshots,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      scanOnlyScreenshots: scanOnlyScreenshots ?? this.scanOnlyScreenshots,
      backendUrl: backendUrl ?? this.backendUrl,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      lastScanTime: lastScanTime ?? this.lastScanTime,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repo;

  SettingsNotifier(this._repo) : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final theme = await _repo.getThemeMode();
    final auto = await _repo.getAutoScan();
    final autoDetect = await _repo.getAutoDetectScreenshots();
    final notify = await _repo.getScreenshotNotifications();
    final lastTime = await _repo.getLastScanTime();
    final onlyScreenshots = await _repo.getScanOnlyScreenshots();
    final url = await _repo.getBackendUrl();
    final isFirst = await _repo.isFirstLaunch();

    state = SettingsState(
      themeMode: theme,
      autoScan: auto,
      autoDetectScreenshots: autoDetect,
      notificationsEnabled: notify,
      lastScanTime: lastTime,
      scanOnlyScreenshots: onlyScreenshots,
      backendUrl: url,
      isFirstLaunch: isFirst,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repo.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setAutoScan(bool enabled) async {
    await _repo.setAutoScan(enabled);
    state = state.copyWith(autoScan: enabled);
  }

  Future<void> setAutoDetectScreenshots(bool enabled) async {
    await _repo.setAutoDetectScreenshots(enabled);
    state = state.copyWith(autoDetectScreenshots: enabled);
  }

  Future<void> setScreenshotNotifications(bool enabled) async {
    await _repo.setScreenshotNotifications(enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }

  Future<void> setLastScanTime(DateTime time) async {
    await _repo.setLastScanTime(time);
    state = state.copyWith(lastScanTime: time);
  }

  Future<void> setScanOnlyScreenshots(bool only) async {
    await _repo.setScanOnlyScreenshots(only);
    state = state.copyWith(scanOnlyScreenshots: only);
  }

  Future<void> setBackendUrl(String url) async {
    await _repo.setBackendUrl(url);
    state = state.copyWith(backendUrl: url);
  }

  Future<void> completeOnboarding() async {
    await _repo.setFirstLaunchCompleted();
    state = state.copyWith(isFirstLaunch: false);
  }

  Future<void> clearAiCache() async {
    await _repo.clearAiCache();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repo);
});
