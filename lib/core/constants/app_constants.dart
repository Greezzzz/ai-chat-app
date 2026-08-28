/// App-wide constants shared across features.
class AppConstants {
  const AppConstants._();

  /// App name shown in the UI.
  static const String appName = 'Chatly';

  /// Minimum characters for a user password.
  static const int minPasswordLength = 8;

  /// Minimum characters for a username (API spec: 3–50).
  static const int minUsernameLength = 3;

  /// Maximum characters for a username (API spec: 3–50).
  static const int maxUsernameLength = 50;

  /// Conversation titles are derived from the first user message,
  /// truncated to this length.
  static const int conversationTitleMaxLength = 40;

  /// Delays a mock streaming response between chunks.
  static const Duration mockChunkDelay = Duration(milliseconds: 50);

  /// Number of milliseconds a mock "thinking" state is shown before
  /// streaming starts.
  static const Duration mockThinkingDelay = Duration(milliseconds: 400);

  /// Seed account available in mock mode.
  static const String seedUserUsername = 'john_doe';
  static const String seedUserEmail = 'john@example.com';
  static const String seedUserPassword = 'password123';

  /// Hive box names.
  static const String usersBox = 'users';
  static const String conversationsBox = 'conversations';
  static const String messagesBox = 'messages';

  /// SharedPreferences key for the stored auth session.
  static const String sessionTokenKey = 'auth_token';
  static const String sessionRefreshTokenKey = 'auth_refresh_token';
  static const String sessionUserIdKey = 'auth_user_id';
}
