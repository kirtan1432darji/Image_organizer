import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/confidence_badge.dart';
import '../../../core/widgets/screenshot_image_thumbnail.dart';
import '../../../models/screenshot_model.dart';

class ScreenshotMasonryGrid extends StatelessWidget {
  final List<ScreenshotModel> screenshots;
  final ScrollController? scrollController;

  const ScreenshotMasonryGrid({
    super.key,
    required this.screenshots,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: screenshots.length,
      itemBuilder: (context, index) {
        final item = screenshots[index];
        return _buildGridCard(context, item);
      },
    );
  }

  Widget _buildGridCard(BuildContext context, ScreenshotModel item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Height ratio variation for authentic staggered masonry look
    final cardHeight = (item.width > 0 && item.height > 0)
        ? (item.height / item.width * 140).clamp(160.0, 240.0)
        : 180.0;

    return GestureDetector(
      onTap: () {
        context.push('/screenshots/${item.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview Container
            SizedBox(
              height: cardHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ScreenshotImageThumbnail(
                    screenshot: item,
                    fit: BoxFit.cover,
                  ),
                  // Top overlay: Confidence Badge & Favorite
                  Positioned(
                    top: 8,
                    left: 8,
                    child: ConfidenceBadge(
                      confidence: item.confidence,
                      size: 9,
                    ),
                  ),
                  if (item.isFavorite)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.favorite_rounded,
                        color: ColorConstants.tertiary,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),

            // Card Footer
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (item.sourceApp != null)
                        Text(
                          item.sourceApp!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.primary,
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Text(
                        DateFormatter.formatShort(item.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
