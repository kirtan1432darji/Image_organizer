import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../providers/category_provider.dart';
import '../home/widgets/ai_category_card.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Categories & Folders'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyStateView(
              icon: Icons.folder_open_rounded,
              title: 'No Folders Found',
              description: 'Categories will be generated as screenshots are scanned and classified.',
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return AiCategoryCard(category: categories[index]);
            },
          );
        },
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => const LoadingShimmer(width: 150, height: 100),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
