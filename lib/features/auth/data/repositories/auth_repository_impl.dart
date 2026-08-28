import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/environment.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_data_source.dart';
import '../datasources/auth_mock_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Auth repository that delegates to the data source selected by
/// [AppEnvironment].
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource);

  final AuthDataSource _dataSource;

  @override
  Future<User> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      return await _dataSource.register(
        username: username,
        email: email,
        password: password,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Gagal mendaftar. Silakan coba lagi.', code: 'register');
    }
  }

  @override
  Future<User> login({
    required String username,
    required String password,
  }) async {
    try {
      return await _dataSource.login(username: username, password: password);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Gagal masuk. Silakan coba lagi.', code: 'login');
    }
  }

  @override
  Future<void> logout() => _dataSource.logout();

  @override
  Future<User?> getCurrentUser() => _dataSource.getCurrentUser();
}

/// Selects the concrete data source based on the runtime environment.
final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  if (AppEnvironment.isMock) {
    return ref.watch(authMockDataSourceProvider);
  }
  final session = ref.watch(sessionStoreProvider) ??
      (throw StateError('SessionStore not initialized'));
  return AuthRemoteDataSource(session, dio: Dio());
});

/// The auth repository used across the app.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authDataSourceProvider)),
);
