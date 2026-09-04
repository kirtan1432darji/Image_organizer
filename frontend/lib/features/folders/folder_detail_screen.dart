import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/color_constants.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../providers/category_provider.dart';
import '../../providers/screenshot_provider.dart';
import 'widgets/filter_chips_bar.dart';
import 'widgets/screenshot_masonry_grid.dart';

class FolderDetailScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;

  const FolderDetailScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  ConsumerState<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends ConsumerState<FolderDetailScreen> {
  String _selectedSubcategory = 'All';

  @override
  Widget build(BuildContext context) {
    final screenshotsAsync = ref.watch(screenshotListProvider);
    final subcategoriesAsync = ref.watch(subcategoriesProvider(widget.categoryId));
    final ancestorsAsync = ref.watch(categoryAncestorsProvider(widget.categoryId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter options: Sort by Date, Size, Confidence')),
              );
            },
          ),
        ],
      ),
      body: screenshotsAsync.when(
        data: (allScreenshots) {
          final subcategories = subcategoriesAsync.valueOrNull ?? [];
          final subcategoryIds = subcategories.map((c) => c.id.toLowerCase()).toSet();

          // Filter by current category or any of its subfolder IDs
          final categoryItems = allScreenshots.where((s) {
            if (widget.categoryId == 'all') return true;
            final scCatId = s.categoryId.toLowerCase();
            return scCatId == widget.categoryId.toLowerCase() ||
                subcategoryIds.contains(scCatId) ||
                (widget.categoryName.isNotEmpty && s.categoryName.toLowerCase() == widget.categoryName.toLowerCase());
          }).toList();

          // Extract subcategory filter options from screenshots
          final subcategoryFilterChips = {'All'};
          for (final item in categoryItems) {
            if (item.subcategory.isNotEmpty) {
              subcategoryFilterChips.add(item.subcategory);
            }
          }

          // Filter by selected subcategory chip
          final filteredItems = _selectedSubcategory == 'All'
              ? categoryItems
              : categoryItems.where((s) => s.subcategory == _selectedSubcategory).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Breadcrumbs Navigation
              ancestorsAsync.when(
                data: (ancestors) {
                  if (ancestors.length <= 1) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => context.go('/home'),
                            child: Row(
                              children: [
                                const Icon(Icons.home_outlined, size: 16, color: ColorConstants.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Home',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: ColorConstants.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (int i = 0; i < ancestors.length; i++) ...[
                            Icon(Icons.chevron_right_rounded, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                            InkWell(
                              onTap: i < ancestors.length - 1
                                  ? () => context.push('/folders/${ancestors[i].id}', extra: ancestors[i].name)
                                  : null,
                              child: Text(
                                ancestors[i].name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: i == ancestors.length - 1 ? FontWeight.bold : FontWeight.normal,
                                  color: i == ancestors.length - 1
                                      ? theme.colorScheme.onSurface
                                      : ColorConstants.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // 2. Subfolders Carousel / List (if this folder has child folders)
              if (subcategories.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_copy_outlined, size: 16, color: ColorConstants.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Subfolders (${subcategories.length})',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: subcategories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final sub = subcategories[index];
                      return Material(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            context.push('/folders/${sub.id}', extra: sub.name);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 140,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Icon(sub.icon, size: 18, color: sub.color),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: sub.color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${sub.screenshotCount}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: sub.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  sub.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // 3. Subcategory Filter Chips Bar
              if (subcategoryFilterChips.length > 2) ...[
                const SizedBox(height: 4),
                FilterChipsBar(
                  filters: subcategoryFilterChips.toList(),
                  selectedFilter: _selectedSubcategory,
                  onSelected: (val) {
                    setState(() => _selectedSubcategory = val);
                  },
                ),
                const SizedBox(height: 4),
              ],

              // 4. Header stats banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredItems.length} screenshots',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.folder_outlined,
                          size: 14,
                          color: ColorConstants.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Smart Folder',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: ColorConstants.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 5. Screenshots Masonry Grid or Empty State
              Expanded(
                child: filteredItems.isEmpty
                    ? EmptyStateView(
                        icon: Icons.folder_open_rounded,
                        title: 'No Screenshots in this Folder',
                        description: subcategories.isNotEmpty
                            ? 'Check the subfolders above for organized screenshots.'
                            : 'Screenshots matching this folder will appear here automatically.',
                      )
                    : ScreenshotMasonryGrid(screenshots: filteredItems),
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: LoadingShimmer(width: double.infinity, height: 400),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
