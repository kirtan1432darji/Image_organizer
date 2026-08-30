import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../providers/favorites_provider.dart';
import '../folders/widgets/screenshot_masonry_grid.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Screenshots'),
      ),
      body: favorites.isEmpty
          ? const EmptyStateView(
              icon: Icons.favorite_border_rounded,
              title: 'No Favorites Yet',
              description:
                  'Tap the heart icon on any screenshot detail page to save it here for quick reference.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '${favorites.length} saved screenshots',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Expanded(
                  child: ScreenshotMasonryGrid(screenshots: favorites),
                ),
              ],
            ),
    );
  }
}
