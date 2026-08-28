import 'package:hive_ce_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// Owns the Hive boxes used across features.
///
/// Boxes are opened once at startup; feature data sources read/write them.
/// Keys are simple string ids (user/conversation/message ids).
class AppDatabase {
  AppDatabase._(this._users, this._conversations, this._messages);

  final Box<Map<dynamic, dynamic>> _users;
  final Box<Map<dynamic, dynamic>> _conversations;
  final Box<Map<dynamic, dynamic>> _messages;

  /// Instance available after [init].
  static late final AppDatabase instance;

  /// Whether [init] has already run (makes [init] re-entrant).
  static bool _initialized = false;

  Box<Map<dynamic, dynamic>> get users => _users;
  Box<Map<dynamic, dynamic>> get conversations => _conversations;
  Box<Map<dynamic, dynamic>> get messages => _messages;

  /// Opens all boxes. Call once before the app builds its UI.
  ///
  /// [path] overrides the storage location (used by tests to point at a
  /// temp directory instead of path_provider).
  static Future<AppDatabase> init({String? path}) async {
    // Re-entrant: if already initialized, return the existing database.
    // (The real main() initializes once on device; tests also init/launch the
    // app, so init must be safe to call more than once.)
    if (_initialized) return instance;
    _initialized = true;

    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }

    final users = await Hive.openBox<Map<dynamic, dynamic>>(
      AppConstants.usersBox,
    );
    final conversations = await Hive.openBox<Map<dynamic, dynamic>>(
      AppConstants.conversationsBox,
    );
    final messages = await Hive.openBox<Map<dynamic, dynamic>>(
      AppConstants.messagesBox,
    );

    instance = AppDatabase._(users, conversations, messages);
    return instance;
  }

  /// Deletes all data. Used by tests and the "reset" path.
  Future<void> clearAll() async {
    await _users.clear();
    await _conversations.clear();
    await _messages.clear();
  }
}
