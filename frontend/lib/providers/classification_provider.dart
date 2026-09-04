import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/smart_folder_service.dart';
import '../models/classification_result_model.dart';
import '../repositories/classification_repository.dart';
import 'category_provider.dart';
import 'folder_provider.dart';
import 'screenshot_provider.dart';

final classificationRepositoryProvider = Provider<ClassificationRepository>((ref) {
  return ClassificationRepository();
});

final smartFolderServiceProvider = Provider<SmartFolderService>((ref) {
  final repo = ref.watch(classificationRepositoryProvider);
  return SmartFolderService(classificationRepository: repo);
});

class ClassificationState {
  final bool isLoading;
  final ClassificationResultModel? latestResult;
  final String? errorMessage;

  const ClassificationState({
    this.isLoading = false,
    this.latestResult,
    this.errorMessage,
  });

  ClassificationState copyWith({
    bool? isLoading,
    ClassificationResultModel? latestResult,
    String? errorMessage,
  }) {
    return ClassificationState(
      isLoading: isLoading ?? this.isLoading,
      latestResult: latestResult ?? this.latestResult,
      errorMessage: errorMessage,
    );
  }
}

class ClassificationNotifier extends StateNotifier<ClassificationState> {
  final Ref _ref;

  ClassificationNotifier(this._ref) : super(const ClassificationState());

  Future<ClassificationResultModel?> classifyScreenshot({
    required String filePath,
    required String ocrText,
    String? screenshotId,
    String? fileName,
    String? sourceApp,
    String? visionDescription,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final smartFolderService = _ref.read(smartFolderServiceProvider);
      final result = await smartFolderService.classifyAndOrganizeScreenshot(
        filePath: filePath,
        ocrText: ocrText,
        screenshotId: screenshotId,
        fileName: fileName,
        sourceApp: sourceApp,
        visionDescription: visionDescription,
      );

      state = state.copyWith(isLoading: false, latestResult: result);

      // Invalidate UI providers to refresh folder tree and screenshots automatically
      _invalidateUiProviders();

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<ClassificationResultModel?> reclassifyScreenshot(String screenshotId, {String? userHint}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final repo = _ref.read(classificationRepositoryProvider);
      final res = await repo.reclassifyScreenshot(screenshotId: screenshotId, userHint: userHint);

      if (res.isSuccess && res.dataOrNull != null) {
        state = state.copyWith(isLoading: false, latestResult: res.dataOrNull);
        _invalidateUiProviders();
        return res.dataOrNull;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: res.errorOrNull);
        return null;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  void _invalidateUiProviders() {
    _ref.invalidate(rootCategoriesProvider);
    _ref.invalidate(categoryListProvider);
    _ref.invalidate(folderListProvider);
    _ref.invalidate(screenshotListProvider);
    _ref.invalidate(statsProvider);
    _ref.invalidate(recentScreenshotsProvider);
  }
}

final classificationNotifierProvider = StateNotifierProvider<ClassificationNotifier, ClassificationState>((ref) {
  return ClassificationNotifier(ref);
});

final classificationHistoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, screenshotId) async {
  final repo = ref.watch(classificationRepositoryProvider);
  return await repo.getHistory(screenshotId);
});
