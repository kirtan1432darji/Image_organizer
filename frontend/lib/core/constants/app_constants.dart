class AppInfo {
  AppInfo._();

  static const String appName = 'ContextVault';
  static const String tagline = 'Turn Screenshots into Searchable Knowledge';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
}

class AppConstants {
  AppConstants._();

  static const String appName = AppInfo.appName;
  static const String tagline = AppInfo.tagline;
  static const String appVersion = AppInfo.appVersion;
  static const String buildNumber = AppInfo.buildNumber;

  // Shared Preferences Keys
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyThemeMode = 'app_theme_mode';
  static const String keyAutoScanOnLaunch = 'auto_scan_on_launch';
  static const String keyAutoDetectScreenshots = 'auto_detect_screenshots';
  static const String keyScreenshotNotifications = 'screenshot_notifications';
  static const String keyScanOnlyScreenshots = 'scan_only_screenshots';
  static const String keyBackendUrl = 'backend_api_url';
  static const String keyUseMockAi = 'use_mock_ai';
  static const String keyLastScanTimestamp = 'last_scan_timestamp';
  static const String keyRecentSearches = 'recent_search_queries';

  // Database (preserves internal database name for compatibility)
  static const String databaseName = 'ai_screenshot_organizer.db';
  static const int databaseVersion = 1;

  // Pagination & limits
  static const int defaultPageSize = 30;
  static const int recentScreenshotsLimit = 12;
  static const int maxRecentSearches = 10;
  
  // AI Confidence thresholds
  static const double highConfidenceThreshold = 0.85;
  static const double mediumConfidenceThreshold = 0.65;
}
