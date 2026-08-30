import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/tag_model.dart';
import '../repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl();
});

class CategoryNotifier extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() async {
    return _fetchCategories();
  }

  Future<List<CategoryModel>> _fetchCategories() async {
    final repo = ref.read(categoryRepositoryProvider);
    return repo.getCategories();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCategories());
  }

  Future<void> syncRemote() async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.syncRemoteCategories();
    await refresh();
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
