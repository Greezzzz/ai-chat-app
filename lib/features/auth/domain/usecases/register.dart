import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Registers a new user (auto-login on success for MVP).
class Register {
  const Register(this._repository);

  final AuthRepository _repository;

  Future<User> call({
    required String username,
    required String email,
    required String password,
  }) {
    return _repository.register(
      username: username,
      email: email,
      password: password,
    );
  }
}
