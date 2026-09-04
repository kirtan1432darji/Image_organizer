import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/folder_context_model.dart';
import '../repositories/folder_context_repository.dart';

final folderContextRepositoryProvider = Provider<FolderContextRepository>((ref) {
  return FolderContextRepositoryImpl();
});

/// FutureProvider that fetches the AI context for a specific categoryId
final folderContextProvider = FutureProvider.family<FolderContextModel, String>((ref, categoryId) async {
  final repository = ref.watch(folderContextRepositoryProvider);
  return repository.getFolderContext(categoryId);
});

/// Action notifier for generating / refreshing folder context and interacting with context items
class FolderContextActionNotifier extends StateNotifier<AsyncValue<FolderContextModel?>> {
  final Ref _ref;
  final String _categoryId;

  FolderContextActionNotifier(this._ref, this._categoryId)
      : super(const AsyncValue.data(null));

  Future<void> generateContext({String? categoryName}) async {
    state = const AsyncValue.loading();
    try {
      final repository = _ref.read(folderContextRepositoryProvider);
      final result = await repository.generateFolderContext(_categoryId, categoryName: categoryName);
      state = AsyncValue.data(result);
      // Invalidate the future provider so watchers re-read the fresh data
      _ref.invalidate(folderContextProvider(_categoryId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void toggleTask(String taskId) {
    final currentAsync = _ref.read(folderContextProvider(_categoryId));
    currentAsync.whenData((currentModel) {
      final updatedTasks = currentModel.tasks.map((task) {
        if (task.id == taskId) {
          return task.copyWith(isCompleted: !task.isCompleted);
        }
        return task;
      }).toList();

      final updatedModel = currentModel.copyWith(tasks: updatedTasks);
      // Update action state
      state = AsyncValue.data(updatedModel);
    });
  }
}

final folderContextActionProvider = StateNotifierProvider.family<
    FolderContextActionNotifier, AsyncValue<FolderContextModel?>, String>(
  (ref, categoryId) => FolderContextActionNotifier(ref, categoryId),
);
