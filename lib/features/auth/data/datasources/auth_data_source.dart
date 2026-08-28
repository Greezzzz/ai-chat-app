import '../../domain/entities/user.dart';

/// Data source contract for authentication.
abstract interface class AuthDataSource {
  Future<User> register({
    required String username,
    required String email,
    required String password,
  });

  Future<User> login({required String username, required String password});

  Future<void> logout();

  Future<User?> getCurrentUser();
}
