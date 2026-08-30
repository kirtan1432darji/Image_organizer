import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/confidence_badge.dart';
import '../../../core/widgets/screenshot_image_thumbnail.dart';
import '../../../models/screenshot_model.dart';

class SearchResultTile extends StatelessWidget {
  final ScreenshotModel screenshot;
  final String query;

  const SearchResultTile({
    super.key,
    required this.screenshot,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Find snippet matching OCR text
    String? matchingSnippet;
    if (screenshot.ocrText != null && query.isNotEmpty) {
      final text = screenshot.ocrText!;
      final idx = text.toLowerCase().indexOf(query.toLowerCase());
      if (idx != -1) {
        final start = (idx - 20).clamp(0, text.length);
        final end = (idx + query.length + 40).clamp(0, text.length);
        matchingSnippet = '...${text.substring(start, end).replaceAll('\n', ' ')}...';
      }
    }

    return GestureDetector(
      onTap: () {
        context.push('/screenshots/${screenshot.id}');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail preview
            SizedBox(
              width: 60,
              height: 70,
              child: ScreenshotImageThumbnail(
                screenshot: screenshot,
                borderRadius: BorderRadius.circular(10),
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          screenshot.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ConfidenceBadge(confidence: screenshot.confidence, size: 9),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ColorConstants.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          screenshot.categoryName,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormatter.formatShort(screenshot.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                  if (matchingSnippet != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      matchingSnippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
