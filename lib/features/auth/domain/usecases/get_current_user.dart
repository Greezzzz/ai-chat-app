import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Returns the signed-in user or null when there is no session.
class GetCurrentUser {
  const GetCurrentUser(this._repository);

  final AuthRepository _repository;

  Future<User?> call() => _repository.getCurrentUser();
}
