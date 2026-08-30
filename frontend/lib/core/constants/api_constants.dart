class ApiConstants {
  ApiConstants._();

  // Configurable base URL (default for emulator, override in Settings or auto-detect on physical device)
  static const String defaultBaseUrl = 'http://10.0.2.2:5000/api';
  
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
  static const String batchScan = '/screenshots/batch-scan';
  static const String classifyScreenshot = '/screenshots/classify';
  static const String batchClassify = '/screenshots/batch-classify';

  // Category & Tag Endpoints
  static const String categories = '/categories';
  static const String tags = '/tags';
  static const String folders = '/folders';
  static const String syncFolders = '/folders/sync';
  
  // Sync & Search Endpoints
  static const String sync = '/sync';
  static const String syncChanges = '/sync/changes';
  static const String semanticSearch = '/search';
  static const String healthCheck = '/health';
}
