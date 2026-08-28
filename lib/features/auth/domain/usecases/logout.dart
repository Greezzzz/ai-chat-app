import '../repositories/auth_repository.dart';

/// Logs the current user out.
class Logout {
  const Logout(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}
