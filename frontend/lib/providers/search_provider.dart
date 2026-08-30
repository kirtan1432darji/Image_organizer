import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/screenshot_model.dart';
import '../repositories/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl();
});

class SearchFilterState {
  final String query;
  final String? categoryId;
  final String? sourceApp;
  final bool searchOcr;
  final bool searchTags;

  const SearchFilterState({
    this.query = '',
    this.categoryId,
    this.sourceApp,
    this.searchOcr = true,
    this.searchTags = true,
  });

  SearchFilterState copyWith({
    String? query,
    String? categoryId,
    String? sourceApp,
    bool? searchOcr,
    bool? searchTags,
  }) {
    return SearchFilterState(
      query: query ?? this.query,
      categoryId: categoryId ?? this.categoryId,
      sourceApp: sourceApp ?? this.sourceApp,
      searchOcr: searchOcr ?? this.searchOcr,
      searchTags: searchTags ?? this.searchTags,
    );
  }
}

final searchFilterProvider =
    StateProvider<SearchFilterState>((ref) => const SearchFilterState());

final searchResultsProvider =
    FutureProvider.autoDispose<List<ScreenshotModel>>((ref) async {
  final filter = ref.watch(searchFilterProvider);
  if (filter.query.trim().isEmpty) {
    return [];
  }

  final repo = ref.read(searchRepositoryProvider);
  return repo.search(
    query: filter.query,
    categoryId: filter.categoryId,
    sourceApp: filter.sourceApp,
    searchOcr: filter.searchOcr,
    searchTags: filter.searchTags,
  );
});

final recentSearchesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.read(searchRepositoryProvider);
  return repo.getRecentSearches();
});
