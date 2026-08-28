import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/app_database.dart';
import '../storage/session_store.dart';
import '../storage/storage_providers.dart';

/// Wipes local state (Hive boxes + persisted session) so the app returns to a
/// clean first-run state.
///
/// Debug-only recovery for a device/environment where stale persisted data
/// (a corrupt Hive user row or a lingering session) leaves the user stuck on
/// the login/register screens. Mirrors `AppDatabase.clearAll()` + a full
/// session clear; on the next launch the seed data runs again.
Future<void> resetLocalData(AppDatabase db, SessionStore store) async {
  await db.clearAll();
  await store.clear();
}

/// Reusable provider wiring the reset to the initialized storage instances.
final resetLocalDataProvider = Provider<Future<void> Function()>((ref) {
  final db = AppDatabase.instance;
  final store = ref.watch(sessionStoreProvider) ??
      (throw StateError('SessionStore not initialized'));
  return () => resetLocalData(db, store);
});