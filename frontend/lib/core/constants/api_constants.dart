class ApiConstants {
  ApiConstants._();

  // Configurable base URL: 127.0.0.1:5000 works on physical Android via `adb reverse tcp:5000 tcp:5000`
  // and local desktop. Users can customize in Settings Screen for remote/LAN IPs.
  static const String defaultBaseUrl = 'http://127.0.0.1:5000/api';
  
  // Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 25);
  static const Duration sendTimeout = Duration(seconds: 20);

  // Authentication Endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';

  // Screenshot Endpoints
  static const String screenshots = '/screenshots';
  static const String scanScreenshot = '/screenshots/scan';
  static const String batchScan = '/screenshots/batch';
  static const String classifyScreenshot = '/screenshots/classify';
  static const String batchClassify = '/screenshots/batch-classify';

  // Sprint 1.3 AI Classification Engine Endpoints
  static const String classificationClassify = '/classification/classify';
  static const String classificationReclassify = '/classification/reclassify';
  static const String classificationHistory = '/classification/history';

  // Category & Tag Endpoints
  static const String categories = '/categories';
  static const String tags = '/tags';
  static const String folders = '/folders';
  static const String syncFolders = '/folders/sync';
  
  // Sprint 1.4 Folder Context Endpoints
  static const String context = '/context';
  static String folderContext(String categoryId) => '/context/$categoryId';
  static String generateFolderContext(String categoryId) => '/context/generate/$categoryId';

  // Sync & Search Endpoints
  static const String sync = '/sync';
  static const String syncChanges = '/sync/changes';
  static const String semanticSearch = '/search';
  static const String healthCheck = '/health';
}

