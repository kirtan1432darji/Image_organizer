import '../core/services/database_service.dart';
import '../core/services/api_client.dart';
import '../models/category_model.dart';
import '../models/tag_model.dart';

abstract class CategoryRepository {
  Future<List<CategoryModel>> getCategories();
  Future<List<TagModel>> getAllTags();
  Future<void> syncRemoteCategories();
}

class CategoryRepositoryImpl implements CategoryRepository {
  final DatabaseService _db;
  final ApiClient _apiClient;

  CategoryRepositoryImpl({
    DatabaseService? db,
    ApiClient? apiClient,
  })  : _db = db ?? DatabaseService(),
        _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<CategoryModel>> getCategories() {
    return _db.getCategories();
  }

  @override
  Future<List<TagModel>> getAllTags() {
    return _db.getAllTags();
  }

  @override
  Future<void> syncRemoteCategories() async {
    final result = await _apiClient.fetchCategories();
    if (result.isSuccess) {
      final remoteList = result.dataOrNull!;
      final dbInstance = await _db.database;
      final batch = dbInstance.batch();
      for (final cat in remoteList) {
        batch.insert('categories', cat.toMap());
      }
      await batch.commit(noResult: true);
    }
  }
}
