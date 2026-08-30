import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/tag_model.dart';
import '../repositories/category_repository.dart';
import 'auth_provider.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CategoryRepositoryImpl(apiClient: apiClient);
});

class CategoryNotifier extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() async {
    final repo = ref.read(categoryRepositoryProvider);
    return repo.getCategories();
  }

  Future<List<CategoryModel>> _fetchCategories() async {
    final repo = ref.read(categoryRepositoryProvider);
    return repo.getCategories();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _fetchCategories());
  }

  Future<void> syncRemote() async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.syncRemoteCategories();
    state = await AsyncValue.guard(() => _fetchCategories());
  }
}

final categoryListProvider =
    AsyncNotifierProvider<CategoryNotifier, List<CategoryModel>>(() {
  return CategoryNotifier();
});

final allTagsProvider = FutureProvider<List<TagModel>>((ref) async {
  final repo = ref.read(categoryRepositoryProvider);
  return repo.getAllTags();
});
