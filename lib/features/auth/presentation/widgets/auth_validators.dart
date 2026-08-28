import '../../../../core/constants/app_constants.dart';

/// Form validators shared by auth screens.
///
/// Kept as plain functions so they are trivially unit-testable.
class AuthValidators {
  const AuthValidators._();

  static final RegExp _emailPattern = RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$');

  /// Username rules follow the API spec: 3–50 characters.
  static String? username(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Username is required';
    if (v.length < AppConstants.minUsernameLength) {
      return 'Username must be at least 3 characters';
    }
    if (v.length > AppConstants.maxUsernameLength) {
      return 'Username must be at most 50 characters';
    }
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  /// Validates that [confirm] matches [password].
  static String? confirmPassword(String? confirm, String password) {
    if (confirm == null || confirm.isEmpty) {
      return 'Confirm your password';
    }
    if (confirm != password) return 'Passwords do not match';
    return null;
  }
}
