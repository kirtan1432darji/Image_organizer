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
  final bool scanOnlyScreenshots;
  final String backendUrl;
  final bool isFirstLaunch;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.autoScan = true,
    this.scanOnlyScreenshots = true,
    this.backendUrl = ApiConstants.defaultBaseUrl,
    this.isFirstLaunch = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? autoScan,
    bool? scanOnlyScreenshots,
    String? backendUrl,
    bool? isFirstLaunch,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      autoScan: autoScan ?? this.autoScan,
      scanOnlyScreenshots: scanOnlyScreenshots ?? this.scanOnlyScreenshots,
      backendUrl: backendUrl ?? this.backendUrl,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
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
    final onlyScreenshots = await _repo.getScanOnlyScreenshots();
    final url = await _repo.getBackendUrl();
    final isFirst = await _repo.isFirstLaunch();

    state = SettingsState(
      themeMode: theme,
      autoScan: auto,
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
