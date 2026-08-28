/// Base exception for all domain errors thrown by the app.
class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Thrown when authentication fails (invalid credentials, duplicate email).
class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

/// Thrown when a network/remote request fails.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

/// Thrown when the AI provider fails to respond.
class AiException extends AppException {
  const AiException(super.message, {super.code});
}

/// Thrown when the current user session is missing or expired.
class SessionException extends AppException {
  const SessionException(super.message, {super.code});
}
