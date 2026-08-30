import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/color_constants.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../providers/search_provider.dart';
import 'widgets/recent_searches_bar.dart';
import 'widgets/search_filter_dialog.dart';
import 'widgets/search_result_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final filter = ref.read(searchFilterProvider);
    _searchController.text = filter.query;
  }

  void _onQueryChanged(String query) {
    ref.read(searchFilterProvider.notifier).update(
          (state) => state.copyWith(query: query),
        );
  }

  void _submitSearch(String query) {
    if (query.trim().isNotEmpty) {
      ref.read(searchRepositoryProvider).saveRecentSearch(query);
      ref.invalidate(recentSearchesProvider);
    }
  }

  void _showFilterDialog() {
    final currentFilter = ref.read(searchFilterProvider);
    showDialog(
      context: context,
      builder: (ctx) => SearchFilterDialog(
        currentState: currentFilter,
        onApply: (newFilter) {
          ref.read(searchFilterProvider.notifier).state = newFilter;
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchFilter = ref.watch(searchFilterProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final recentSearchesAsync = ref.watch(recentSearchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Screenshots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onQueryChanged,
              onSubmitted: _submitSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search text inside images, tags, apps...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onQueryChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Active filter badges
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (searchFilter.searchOcr)
                  _buildActiveChip('OCR Text', ColorConstants.primary),
                const SizedBox(width: 6),
                if (searchFilter.searchTags)
                  _buildActiveChip('Tags', ColorConstants.secondary),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Search Results or Recent Searches
          Expanded(
            child: searchFilter.query.trim().isEmpty
                ? recentSearchesAsync.when(
                    data: (recent) => RecentSearchesBar(
                      recentSearches: recent,
                      onSelectQuery: (q) {
                        _searchController.text = q;
                        _onQueryChanged(q);
                        _submitSearch(q);
                      },
                      onClearAll: () async {
                        await ref.read(searchRepositoryProvider).clearRecentSearches();
                        ref.invalidate(recentSearchesProvider);
                      },
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  )
                : searchResultsAsync.when(
                    data: (results) {
                      if (results.isEmpty) {
                        return EmptyStateView(
                          icon: Icons.search_off_rounded,
                          title: 'No Matching Screenshots',
                          description:
                              'We couldn\'t find any screenshots matching "${searchFilter.query}". Try a different keyword or check spelling.',
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final item = results[index];
                          return SearchResultTile(
                            screenshot: item,
                            query: searchFilter.query,
                          );
                        },
                      );
                    },
                    loading: () => ListView.builder(
                      itemCount: 4,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: LoadingShimmer(width: double.infinity, height: 75),
                      ),
                    ),
                    error: (err, _) => Center(child: Text('Search error: $err')),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
