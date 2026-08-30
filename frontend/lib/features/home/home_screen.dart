import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/color_constants.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../providers/category_provider.dart';
import '../../providers/scanner_provider.dart';
import '../../providers/screenshot_provider.dart';
import '../../providers/sync_provider.dart';
import 'widgets/ai_category_card.dart';
import 'widgets/duplicate_suggestion_card.dart';
import 'widgets/needs_review_section.dart';
import 'widgets/recent_screenshots_carousel.dart';
import 'widgets/stats_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final recentScreenshots = ref.watch(recentScreenshotsProvider);
    final scannerState = ref.watch(scannerProvider);
    final isSyncing = ref.watch(syncProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorConstants.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: ColorConstants.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'AI Screenshot Organizer',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sync with AI backend',
            onPressed: isSyncing
                ? null
                : () async {
                    final processed =
                        await ref.read(syncProvider.notifier).syncNow();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            processed > 0
                                ? 'Successfully synced $processed items with AI backend.'
                                : 'All screenshots are up to date.',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
            icon: isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ColorConstants.primary,
                    ),
                  )
                : const Icon(Icons.sync_rounded),
          ),
          IconButton(
            tooltip: 'Scan Gallery',
            onPressed: scannerState.isScanning
                ? null
                : () => ref.read(scannerProvider.notifier).startScan(),
            icon: const Icon(Icons.photo_library_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(screenshotListProvider.notifier).refresh();
          await ref.read(categoryListProvider.notifier).refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Scanning banner if active
            if (scannerState.isScanning)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ColorConstants.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ColorConstants.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
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
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Top Stats Card
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
              sliver: SliverToBoxAdapter(
                child: StatsHeader(),
              ),
            ),

            // Needs Review Section
            const SliverToBoxAdapter(
              child: NeedsReviewSection(),
            ),

            // Recent Screenshots Carousel
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                child: RecentScreenshotsCarousel(
                  screenshots: recentScreenshots,
                ),
              ),
            ),

            // Duplicate Suggestion Card
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: DuplicateSuggestionCard(),
              ),
            ),

            // AI Categories Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI Categories',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Auto-classified',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ColorConstants.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Categories Grid
            categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return SliverToBoxAdapter(
                    child: EmptyStateView(
                      icon: Icons.folder_open_rounded,
                      title: 'No Categories Found',
                      description:
                          'Scan your gallery to organize screenshots into AI categories.',
                      actionLabel: 'Scan Gallery Now',
                      onAction: () =>
                          ref.read(scannerProvider.notifier).startScan(),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.35,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final cat = categories[index];
                        return AiCategoryCard(category: cat);
                      },
                      childCount: categories.length,
                    ),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const LoadingShimmer(width: 150, height: 100),
                    childCount: 6,
                  ),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: ErrorStateView(
                  message: err.toString(),
                  onRetry: () => ref.read(categoryListProvider.notifier).refresh(),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 30),
            ),
          ],
        ),
      ),
    );
  }
}
