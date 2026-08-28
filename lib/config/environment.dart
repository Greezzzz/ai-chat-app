/// Runtime environment configuration.
///
/// Switches the app between mock and production data sources.
/// The value can be overridden at build time with:
/// `--dart-define=APP_ENV=production`
class AppEnvironment {
  const AppEnvironment._();

  static const String _env = String.fromEnvironment('APP_ENV',
      defaultValue: 'mock');

  /// Whether the app runs against the local mock data source.
  static const bool isMock = _env == 'mock';

  /// Whether the app runs against the remote API.
  static const bool isProduction = _env == 'production';

  /// Base URL of the production API. Empty in mock mode.
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
}
