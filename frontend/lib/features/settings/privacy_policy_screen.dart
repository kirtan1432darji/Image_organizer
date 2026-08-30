import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorConstants.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ColorConstants.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: ColorConstants.success, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zero-Image-Upload Architecture',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.success,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your original images never leave your mobile device.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Non-Destructive Operation',
              'AI Screenshot Organizer operates purely as a read-only metadata layer over your system gallery. It does not move, rename, delete, copy, or compress any image files on your phone storage.',
              context,
            ),
            _buildSection(
              '2. Optical Character Recognition (OCR)',
              'OCR is performed locally on your device hardware whenever possible. Extracted text blocks are stored exclusively in an encrypted local SQLite database for instant full-text search.',
              context,
            ),
            _buildSection(
              '3. AI Classification & Backend Sync',
              'When syncing with the ASP.NET Core backend, only text excerpts and basic file metadata (dimensions, timestamps) are transmitted for classification categorization. Full photos are never uploaded to remote servers.',
              context,
            ),
            _buildSection(
              '4. Data Retention & Cache Removal',
              'You have full control to purge the local OCR index, tag cache, or reset all organization categories at any time from the Settings menu.',
              context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String body, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
