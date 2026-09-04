class AppRouteNames {
  AppRouteNames._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  
  // Shell tab routes
  static const String home = '/home';
  static const String search = '/search';
  static const String favorites = '/favorites';
  static const String settings = '/settings';
  
  // Sub routes
  static const String folderDetail = '/folders/:categoryId';
  static const String folderContext = '/folders/:categoryId/context';
  static const String screenshotDetail = '/screenshots/:id';
  static const String privacyPolicy = '/settings/privacy';
}

