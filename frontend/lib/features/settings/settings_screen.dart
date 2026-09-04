import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/color_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/modern_card.dart';
import '../../providers/screenshot_listener_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sync_provider.dart';
import '../../routes/route_names.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showBackendUrlDialog(BuildContext context, WidgetRef ref, String currentUrl) {
    final controller = TextEditingController(text: currentUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ASP.NET Core Backend URL'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set your ASP.NET Core Web API address for AI classification sync:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'http://10.0.2.2:5000/api',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setBackendUrl(controller.text.trim());
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backend API URL updated!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear AI Cache?'),
        content: const Text(
          'This will purge cached OCR text from SQLite. Screenshots will re-run OCR on demand. Your original phone photos are untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorConstants.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(settingsProvider.notifier).clearAiCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI Cache cleared successfully.')),
                );
              }
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final listenerState = ref.watch(screenshotListenerProvider);
    final pendingCountAsync = ref.watch(pendingSyncCountProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ContextVault Settings'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Theme & Appearance Section
          _buildSectionHeader('Appearance & Theme', context),
          ModernCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Theme Mode'),
                  subtitle: Text(_getThemeModeName(settings.themeMode)),
                  trailing: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.settings_suggest_outlined, size: 16),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (set) {
                      ref.read(settingsProvider.notifier).setThemeMode(set.first);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Scanner Preferences
          _buildSectionHeader('Scanner Preferences', context),
          ModernCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.autorenew_rounded),
                  title: const Text('Auto-Scan on Launch'),
                  subtitle: const Text('Check for new screenshots when app opens'),
                  value: settings.autoScan,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).setAutoScan(val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.filter_hdr_outlined),
                  title: const Text('Scan Only Screenshots Folder'),
                  subtitle: const Text('Exclude camera photos and downloads'),
                  value: settings.scanOnlyScreenshots,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).setScanOnlyScreenshots(val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Automatic Background Detection Section
          _buildSectionHeader('Automatic Screenshot Detection', context),
          ModernCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.radar_rounded, color: ColorConstants.primary),
                  title: const Text('Auto Detect Screenshots'),
                  subtitle: const Text('Real-time MediaStore ContentObserver detection'),
                  value: listenerState.autoDetectEnabled,
                  onChanged: (val) {
                    ref.read(screenshotListenerProvider.notifier).toggleAutoDetect(val);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    listenerState.isMonitoring
                        ? Icons.check_circle_outline_rounded
                        : Icons.pause_circle_outline_rounded,
                    color: listenerState.isMonitoring
                        ? ColorConstants.success
                        : ColorConstants.warning,
                  ),
                  title: const Text('Background Monitoring Status'),
                  subtitle: Text(listenerState.statusMessage),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (listenerState.isMonitoring
                              ? ColorConstants.success
                              : ColorConstants.warning)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      listenerState.isMonitoring ? 'Active' : 'Paused',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: listenerState.isMonitoring
                            ? ColorConstants.success
                            : ColorConstants.warning,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Notification on Detection'),
                  subtitle: const Text('Show alert when screenshot is sorted into folder'),
                  value: listenerState.notificationsEnabled,
                  onChanged: (val) {
                    ref.read(screenshotListenerProvider.notifier).toggleNotifications(val);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history_toggle_off_rounded),
                  title: const Text('Last Screenshot Scan Time'),
                  subtitle: Text(
                    listenerState.lastScanTime != null
                        ? DateFormatter.formatFull(listenerState.lastScanTime!)
                        : 'No recent scans',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.document_scanner_outlined, color: ColorConstants.primary),
                  title: const Text('Scan Existing Screenshots'),
                  subtitle: const Text('Run scanner across device gallery now'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await ref.read(screenshotListenerProvider.notifier).triggerManualScan();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gallery scan complete.')),
                        );
                      }
                    },
                    child: const Text('Scan Now'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // AI & Cloud Backend Section
          _buildSectionHeader('AI & ASP.NET Core Backend', context),
          ModernCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined),
                  title: const Text('Backend API URL'),
                  subtitle: Text(
                    settings.backendUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showBackendUrlDialog(context, ref, settings.backendUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.schedule_send_outlined),
                  title: const Text('Offline Sync Queue'),
                  subtitle: pendingCountAsync.when(
                    data: (count) => Text('$count items pending sync'),
                    loading: () => const Text('Checking...'),
                    error: (_, __) => const Text('Offline mode'),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final count = await ref.read(syncProvider.notifier).syncNow();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Processed $count pending items.')),
                        );
                      }
                    },
                    child: const Text('Sync Now'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Data & Privacy Section
          _buildSectionHeader('Storage & Privacy', context),
          ModernCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: const Text('Clear AI & OCR Cache'),
                  subtitle: const Text('Purges local OCR text index from SQLite'),
                  onTap: () => _showClearCacheDialog(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Privacy & Security Guarantees'),
                  subtitle: const Text('Learn how zero-image-upload architecture works'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRouteNames.privacyPolicy),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Version & copyright info
          Center(
            child: Column(
              children: [
                Text(
                  '${AppConstants.appName} v${AppConstants.appVersion} (${AppConstants.buildNumber})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Clean Architecture • Riverpod • SQLite • ASP.NET Core Ready',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light Theme';
      case ThemeMode.dark:
        return 'Dark Theme';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: ColorConstants.primary,
            ),
      ),
    );
  }
}
