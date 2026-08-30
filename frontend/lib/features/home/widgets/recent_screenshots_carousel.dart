import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/screenshot_image_thumbnail.dart';
import '../../../models/screenshot_model.dart';

class RecentScreenshotsCarousel extends StatelessWidget {
  final List<ScreenshotModel> screenshots;

  const RecentScreenshotsCarousel({
    super.key,
    required this.screenshots,
  });

  @override
  Widget build(BuildContext context) {
    if (screenshots.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Screenshots',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${screenshots.length} latest',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: screenshots.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = screenshots[index];
              return _buildThumbnailCard(context, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnailCard(BuildContext context, ScreenshotModel item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        context.push('/screenshots/${item.id}');
      },
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Real Screenshot Preview Thumbnail
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ScreenshotImageThumbnail(
                    screenshot: item,
                    fit: BoxFit.cover,
                  ),
                  if (item.isFavorite)
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 16,
                        color: ColorConstants.tertiary,
                      ),
                    ),
                ],
              ),
            ),
            // Metadata label
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.formatRelative(item.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
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
