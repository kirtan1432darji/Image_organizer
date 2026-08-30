import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/widgets/confidence_badge.dart';
import '../../../models/screenshot_model.dart';
import '../../../providers/screenshot_provider.dart';

class NeedsReviewSection extends ConsumerWidget {
  const NeedsReviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsReviewItems = ref.watch(needsReviewScreenshotsProvider);
    if (needsReviewItems.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1917) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFDE68A),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pending_actions_rounded,
                color: ColorConstants.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Needs Review (${needsReviewItems.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'These screenshots have lower AI confidence or are currently unclassified. Tap to verify or assign a category.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? const Color(0xFFD6D3D1) : const Color(0xFF78350F),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: needsReviewItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = needsReviewItems[index];
                return _buildReviewTile(context, ref, item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTile(BuildContext context, WidgetRef ref, ScreenshotModel item) {
    return GestureDetector(
      onTap: () {
        context.push('/screenshots/${item.id}');
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            ConfidenceBadge(confidence: item.confidence, size: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Review ->',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
