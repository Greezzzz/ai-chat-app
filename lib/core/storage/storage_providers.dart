import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/hash_util.dart';
import 'app_database.dart';
import 'session_store.dart';

/// Initializes local storage (Hive + SharedPreferences) once.
///
/// Await this in `main()` before runApp, then pass the ready instances into
/// the app via [storageProvidersOverride] so the widget tree sees them
/// synchronously.
final storageInitProvider = FutureProvider<AppDatabase>((ref) async {
  final sessionStore = SessionStore(await SharedPreferences.getInstance());
  final db = await AppDatabase.init();
  ref.read(sessionStoreProvider.notifier).attach(sessionStore);
  return db;
});

/// Holds the app's local database (Hive boxes).
///
/// Defaults to [AppDatabase.instance] which is set by [AppDatabase.init].
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => AppDatabase.instance,
);

/// Holds the persisted auth session.
final sessionStoreProvider =
    NotifierProvider<SessionStoreNotifier, SessionStore?>(SessionStoreNotifier.new);

class SessionStoreNotifier extends Notifier<SessionStore?> {
  @override
  SessionStore? build() => null;

  void attach(SessionStore store) => state = store;
}

/// Utility for hashing passwords in mock mode.
final hashUtilProvider = Provider<HashUtil>((ref) => const HashUtil());
