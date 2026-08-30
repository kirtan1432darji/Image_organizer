import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/sync_service.dart';
import '../core/services/database_service.dart';
import 'screenshot_provider.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final db = DatabaseService();
  final items = await db.getPendingSyncItems();
  return items.length;
});

class SyncNotifier extends StateNotifier<bool> {
  final Ref _ref;
  final SyncService _syncService;

  SyncNotifier(this._ref, this._syncService) : super(false);

  Future<int> syncNow() async {
    state = true;
    try {
      final processed = await _syncService.processPendingQueue();
      if (processed > 0) {
        _ref.read(screenshotListProvider.notifier).refresh();
        _ref.invalidate(pendingSyncCountProvider);
      }
      return processed;
    } finally {
      state = false;
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, bool>((ref) {
  final service = ref.watch(syncServiceProvider);
  return SyncNotifier(ref, service);
});
