import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/color_constants.dart';
import '../../../providers/scanner_provider.dart';

class ScannerStatusBanner extends ConsumerWidget {
  const ScannerStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(scannerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 1. Permission Denied State
    if (scannerState.isPermissionDenied) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Photo Access Required',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Grant photo permissions to scan and organize your screenshots.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => ref.read(scannerProvider.notifier).openSettings(),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
                foregroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Settings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Active Scanning State
    if (scannerState.isScanning) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ColorConstants.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ColorConstants.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: ColorConstants.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    scannerState.statusMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.primary,
                    ),
                  ),
                ),
              ],
            ),
            if (scannerState.totalProgress > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: scannerState.currentProgress / scannerState.totalProgress,
                  minHeight: 6,
                  backgroundColor: ColorConstants.primary.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(ColorConstants.primary),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // 3. Limited Photo Access Banner (Android 14+)
    if (scannerState.isLimitedPermission) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Limited photo access granted.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(scannerProvider.notifier).manageLimitedPhotos(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF59E0B),
              ),
              child: const Text('Manage Photos'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
