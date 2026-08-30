import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../providers/scanner_provider.dart';

class ScanHeroCard extends ConsumerWidget {
  final VoidCallback onScan;

  const ScanHeroCard({
    super.key,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(scannerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorConstants.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: ColorConstants.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Phone Screenshots',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Organize receipts, code, chats & notes',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Scan your Android screenshot album to automatically extract text, categorize images, and keep your library organized.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          if (scannerState.isScanning) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: scannerState.totalProgress > 0
                    ? scannerState.currentProgress / scannerState.totalProgress
                    : null,
                minHeight: 8,
                backgroundColor: ColorConstants.primary.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(ColorConstants.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              scannerState.statusMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: ColorConstants.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text(
                  'Scan Phone Screenshots',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
