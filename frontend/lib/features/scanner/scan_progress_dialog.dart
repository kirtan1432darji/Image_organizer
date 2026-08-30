import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/color_constants.dart';
import '../../providers/scanner_provider.dart';

class ScanProgressDialog extends ConsumerWidget {
  const ScanProgressDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(scannerProvider);
    final theme = Theme.of(context);

    final percent = scannerState.totalProgress > 0
        ? (scannerState.currentProgress / scannerState.totalProgress).clamp(0.0, 1.0)
        : 0.0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorConstants.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: ColorConstants.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scanning Screenshots',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              scannerState.statusMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: scannerState.totalProgress > 0 ? percent : null,
              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
              color: ColorConstants.primary,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 12),
            if (scannerState.totalProgress > 0)
              Text(
                '${(percent * 100).toInt()}% completed',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
      actions: [
        if (!scannerState.isScanning)
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
      ],
    );
  }
}
