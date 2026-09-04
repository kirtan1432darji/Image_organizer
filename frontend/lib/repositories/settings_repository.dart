import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../core/services/database_service.dart';

abstract class SettingsRepository {
  Future<ThemeMode> getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
  Future<bool> getAutoScan();
  Future<void> setAutoScan(bool enabled);
  Future<bool> getAutoDetectScreenshots();
  Future<void> setAutoDetectScreenshots(bool enabled);
  Future<bool> getScreenshotNotifications();
  Future<void> setScreenshotNotifications(bool enabled);
  Future<DateTime?> getLastScanTime();
  Future<void> setLastScanTime(DateTime time);
  Future<bool> getScanOnlyScreenshots();
  Future<void> setScanOnlyScreenshots(bool only);
  Future<String> getBackendUrl();
  Future<void> setBackendUrl(String url);
  Future<bool> isFirstLaunch();
  Future<void> setFirstLaunchCompleted();
  Future<void> clearAiCache();
}

class SettingsRepositoryImpl implements SettingsRepository {
  final DatabaseService _db;

  SettingsRepositoryImpl({DatabaseService? db}) : _db = db ?? DatabaseService();

  @override
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(AppConstants.keyThemeMode) ?? ThemeMode.system.index;
    return ThemeMode.values[index];
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyThemeMode, mode.index);
  }

  @override
  Future<bool> getAutoScan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyAutoScanOnLaunch) ?? true;
  }

  @override
  Future<void> setAutoScan(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyAutoScanOnLaunch, enabled);
  }

  @override
  Future<bool> getAutoDetectScreenshots() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyAutoDetectScreenshots) ?? true;
  }

  @override
  Future<void> setAutoDetectScreenshots(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyAutoDetectScreenshots, enabled);
  }

  @override
  Future<bool> getScreenshotNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyScreenshotNotifications) ?? true;
  }

  @override
  Future<void> setScreenshotNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyScreenshotNotifications, enabled);
  }

  @override
  Future<DateTime?> getLastScanTime() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(AppConstants.keyLastScanTimestamp);
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  @override
  Future<void> setLastScanTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLastScanTimestamp, time.toIso8601String());
  }

  @override
  Future<bool> getScanOnlyScreenshots() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyScanOnlyScreenshots) ?? true;
  }

  @override
  Future<void> setScanOnlyScreenshots(bool only) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyScanOnlyScreenshots, only);
  }

  @override
  Future<String> getBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyBackendUrl) ?? ApiConstants.defaultBaseUrl;
  }

  @override
  Future<void> setBackendUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyBackendUrl, url);
  }

  @override
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyIsFirstLaunch) ?? true;
  }

  @override
  Future<void> setFirstLaunchCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsFirstLaunch, false);
  }

  @override
  Future<void> clearAiCache() {
    return _db.clearAiCache();
  }
}
