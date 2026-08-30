import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/services/database_service.dart';
import '../models/screenshot_model.dart';

abstract class SearchRepository {
  Future<List<ScreenshotModel>> search({
    required String query,
    String? categoryId,
    String? sourceApp,
    bool searchOcr = true,
    bool searchTags = true,
  });

  Future<List<String>> getRecentSearches();
  Future<void> saveRecentSearch(String query);
  Future<void> clearRecentSearches();
}

class SearchRepositoryImpl implements SearchRepository {
  final DatabaseService _db;

  SearchRepositoryImpl({DatabaseService? db}) : _db = db ?? DatabaseService();

  @override
  Future<List<ScreenshotModel>> search({
    required String query,
    String? categoryId,
    String? sourceApp,
    bool searchOcr = true,
    bool searchTags = true,
  }) {
    return _db.searchScreenshots(
      query: query,
      categoryId: categoryId,
      sourceApp: sourceApp,
      searchOcr: searchOcr,
      searchTags: searchTags,
    );
  }

  @override
  Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(AppConstants.keyRecentSearches) ??
        ['Apple receipt', 'Riverpod state', 'Flight DL1492', 'Slack deployment', 'Sony headphones'];
  }

  @override
  Future<void> saveRecentSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(AppConstants.keyRecentSearches) ?? [];
    list.removeWhere((item) => item.toLowerCase() == clean.toLowerCase());
    list.insert(0, clean);
    if (list.length > AppConstants.maxRecentSearches) {
      list = list.sublist(0, AppConstants.maxRecentSearches);
    }
    await prefs.setStringList(AppConstants.keyRecentSearches, list);
  }

  @override
  Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyRecentSearches);
  }
}
