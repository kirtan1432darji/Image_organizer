import 'package:flutter/material.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../models/screenshot_model.dart';

class MetadataPanel extends StatelessWidget {
  final ScreenshotModel screenshot;

  const MetadataPanel({
    super.key,
    required this.screenshot,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File & Device Metadata',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildRow('File Name', screenshot.fileName, context),
          _buildDivider(),
          _buildRow('Captured At', DateFormatter.formatFull(screenshot.createdAt), context),
          _buildDivider(),
          _buildRow('Dimensions', FileUtils.formatResolution(screenshot.width, screenshot.height), context),
          _buildDivider(),
          _buildRow('File Size', FileUtils.formatBytes(screenshot.fileSize), context),
          if (screenshot.sourceApp != null) ...[
            _buildDivider(),
            _buildRow('Inferred Source App', screenshot.sourceApp!, context),
          ],
          _buildDivider(),
          _buildRow(
            'Sync Status',
            screenshot.isSynced ? 'Synced with AI Cloud' : 'Stored Locally (Offline)',
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 12);
  }
}
