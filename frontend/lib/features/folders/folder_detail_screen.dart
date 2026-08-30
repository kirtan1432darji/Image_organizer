import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/color_constants.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/loading_shimmer.dart';
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
    final theme = Theme.of(context);

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
          // Filter by current category
          final categoryItems = allScreenshots.where((s) {
            if (widget.categoryId == 'all') return true;
            return s.categoryId.toLowerCase() == widget.categoryId.toLowerCase() ||
                   (widget.categoryName.isNotEmpty && s.categoryName.toLowerCase() == widget.categoryName.toLowerCase());
          }).toList();

          if (categoryItems.isEmpty) {
            return EmptyStateView(
              icon: Icons.folder_open_rounded,
              title: 'No Screenshots Here',
              description: 'There are currently no screenshots categorized under "${widget.categoryName}".',
            );
          }

          // Extract subcategory filter options
          final subcategories = {'All'};
          for (final item in categoryItems) {
            if (item.subcategory.isNotEmpty) {
              subcategories.add(item.subcategory);
            }
          }

          // Filter by selected subcategory
          final filteredItems = _selectedSubcategory == 'All'
              ? categoryItems
              : categoryItems.where((s) => s.subcategory == _selectedSubcategory).toList();

          return Column(
            children: [
              // Subcategory chips bar
              if (subcategories.length > 1) ...[
                const SizedBox(height: 8),
                FilterChipsBar(
                  filters: subcategories.toList(),
                  selectedFilter: _selectedSubcategory,
                  onSelected: (val) {
                    setState(() => _selectedSubcategory = val);
                  },
                ),
                const SizedBox(height: 4),
              ],

              // Header stats banner
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
                          Icons.verified_outlined,
                          size: 14,
                          color: ColorConstants.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI Categorized',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: ColorConstants.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Masonry Grid
              Expanded(
                child: ScreenshotMasonryGrid(screenshots: filteredItems),
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
