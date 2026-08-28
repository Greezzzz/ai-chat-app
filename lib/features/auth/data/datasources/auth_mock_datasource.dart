import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/app_database.dart';
import '../../../../core/storage/session_store.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/utils/hash_util.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';
import 'auth_data_source.dart';

/// Mock auth backed by Hive + SharedPreferences (PRD §25).
///
/// Simulates a backend: duplicate-email rejection, credential validation,
/// password hashing and a persisted session.
class AuthMockDataSource implements AuthDataSource {
  AuthMockDataSource(this._db, this._session, this._hash);

  final AppDatabase _db;
  final SessionStore _session;
  final HashUtil _hash;

  @override
  Future<User> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();

    final exists = _db.users.values.any(
      (u) =>
          (u['username'] as String?)?.toLowerCase() == normalizedUsername ||
          (u['email'] as String?)?.toLowerCase() == email.trim().toLowerCase(),
    );
    if (exists) {
      throw const AuthException('Username atau email sudah terdaftar.');
    }

    final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final salt = id;
    final model = UserModel(
      id: id,
      username: normalizedUsername,
      email: email.trim().toLowerCase(),
      passwordHash: _hash.hash(password, salt: salt),
      salt: salt,
    );
    await _db.users.put(id, model.toJson());

    await _saveSession(model);
    return model.toEntity();
  }

  @override
  Future<User> login({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();

    UserModel? found;
    for (final raw in _db.users.values) {
      final model = UserModel.fromJson(raw);
      if (model.username.toLowerCase() == normalizedUsername) {
        found = model;
        break;
      }
    }

    if (found == null || !_hash.verify(password, found.passwordHash ?? '', salt: found.salt ?? '')) {
      throw const AuthException('Username atau password salah.');
    }

    await _saveSession(found);
    return found.toEntity();
  }

  @override
  Future<void> logout() => _session.clear();

  @override
  Future<User?> getCurrentUser() async {
    final id = _session.userId;
    if (id == null) return null;
    final raw = _db.users.get(id);
    if (raw == null) {
      await _session.clear();
      return null;
    }
    return UserModel.fromJson(raw).toEntity();
  }

  Future<void> _saveSession(UserModel user) async {
    await _session.saveSession(userId: user.id, token: 'mock_token_${user.id}');
  }
}

/// Mock data source used in mock mode.
final authMockDataSourceProvider = Provider<AuthDataSource>((ref) {
  final db = AppDatabase.instance;
  final session = ref.watch(sessionStoreProvider) ??
      (throw StateError('SessionStore not initialized'));
  return AuthMockDataSource(db, session, ref.watch(hashUtilProvider));
});
