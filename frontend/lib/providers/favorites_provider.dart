import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/screenshot_model.dart';
import 'screenshot_provider.dart';

final favoritesProvider = Provider<List<ScreenshotModel>>((ref) {
  final asyncScreenshots = ref.watch(screenshotListProvider);
  return asyncScreenshots.maybeWhen(
    data: (list) => list.where((s) => s.isFavorite).toList(),
    orElse: () => [],
  );
});
