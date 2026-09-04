import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/navigation/main_scaffold.dart';
import '../features/home/home_screen.dart';
import '../features/search/search_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/privacy_policy_screen.dart';
import '../features/folders/folder_detail_screen.dart';
import '../features/context/folder_context_screen.dart';
import '../features/screenshot_detail/screenshot_detail_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRouteNames.splash,
  routes: [
    GoRoute(
      path: AppRouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRouteNames.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: AppRouteNames.home,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: AppRouteNames.search,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SearchScreen(),
          ),
        ),
        GoRoute(
          path: AppRouteNames.favorites,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FavoritesScreen(),
          ),
        ),
        GoRoute(
          path: AppRouteNames.settings,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRouteNames.folderDetail,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId'] ?? 'unsorted';
        final categoryName = state.extra as String? ?? 'Folder';
        return FolderDetailScreen(
          categoryId: categoryId,
          categoryName: categoryName,
        );
      },
    ),
    GoRoute(
      path: AppRouteNames.folderContext,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId'] ?? 'unsorted';
        final categoryName = state.extra as String? ?? 'Folder';
        return FolderContextScreen(
          categoryId: categoryId,
          categoryName: categoryName,
        );
      },
    ),
    GoRoute(
      path: AppRouteNames.screenshotDetail,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final screenshotId = state.pathParameters['id'] ?? '';
        return ScreenshotDetailScreen(screenshotId: screenshotId);
      },
    ),
    GoRoute(
      path: AppRouteNames.privacyPolicy,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
  ],
);
