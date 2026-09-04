import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/auth_service.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/screenshot_listener_provider.dart';
import 'providers/settings_provider.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Auth & secure token store
  await AuthService().init();

  // Set preferred orientations & status bar overlay
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: ContextVaultApp(),
    ),
  );
}

class ContextVaultApp extends ConsumerWidget {
  const ContextVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    // Initialize automatic screenshot background detection listener
    ref.watch(screenshotListenerProvider);

    return MaterialApp.router(
      title: AppInfo.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      routerConfig: appRouter,
    );
  }
}

/// Backward compatibility alias for tests and existing references
typedef AiScreenshotOrganizerApp = ContextVaultApp;
