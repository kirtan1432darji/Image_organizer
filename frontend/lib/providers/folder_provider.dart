import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/folder_model.dart';
import '../repositories/folder_repository.dart';

final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  return FolderRepositoryImpl();
});

class FolderNotifier extends AsyncNotifier<List<FolderModel>> {
  @override
  Future<List<FolderModel>> build() async {
    final repo = ref.read(folderRepositoryProvider);
    return repo.getFolders();
  }

  Future<void> createFolder(String name, String icon) async {
    final repo = ref.read(folderRepositoryProvider);
    await repo.createFolder(name, icon);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.getFolders());
  }

  Future<void> deleteFolder(String id) async {
    final repo = ref.read(folderRepositoryProvider);
    await repo.deleteFolder(id);
    state = state.whenData((list) => list.where((f) => f.id != id).toList());
  }
}

final folderListProvider =
    AsyncNotifierProvider<FolderNotifier, List<FolderModel>>(() {
  return FolderNotifier();
});
