class ApiConstants {
  ApiConstants._();

  // Default ASP.NET Core backend base URL (Android emulator: 10.0.2.2, iOS / Web / Localhost: 127.0.0.1 or configurable)
  static const String defaultBaseUrl = 'http://10.0.2.2:5000/api';
  
  // Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 25);
  static const Duration sendTimeout = Duration(seconds: 20);

  // Endpoints
  static const String classifyScreenshot = '/screenshots/classify';
  static const String batchClassify = '/screenshots/batch-classify';
  static const String categories = '/categories';
  static const String folders = '/folders';
  static const String syncFolders = '/folders/sync';
  static const String semanticSearch = '/search/semantic';
  static const String healthCheck = '/health';
}
