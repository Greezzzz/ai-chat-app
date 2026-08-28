import '../../../../core/errors/app_exception.dart';
import '../entities/user.dart';

/// Contract for authentication operations.
///
/// Implementations swap between mock (local storage) and remote (API)
/// without touching the UI.
abstract interface class AuthRepository {
  /// Registers a new account. Throws [AuthException] when the username/email
  /// is already registered. Returns the created user with an active session.
  Future<User> register({
    required String username,
    required String email,
    required String password,
  });

  /// Authenticates an existing account. Throws [AuthException] on invalid
  /// credentials. Returns the user with an active session.
  Future<User> login({required String username, required String password});

  /// Ends the current session.
  Future<void> logout();

  /// Returns the signed-in user, or null when no session exists.
  Future<User?> getCurrentUser();
}
