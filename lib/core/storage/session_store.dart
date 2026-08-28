import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Persists the auth session (user id + token pair) with SharedPreferences.
class SessionStore {
  SessionStore(this._prefs);

  final SharedPreferences _prefs;

  String? get userId => _prefs.getString(AppConstants.sessionUserIdKey);

  String? get token => _prefs.getString(AppConstants.sessionTokenKey);

  String? get refreshToken =>
      _prefs.getString(AppConstants.sessionRefreshTokenKey);

  bool get isAuthenticated =>
      userId != null && _prefs.getString(AppConstants.sessionTokenKey) != null;

  Future<void> saveSession({
    required String userId,
    required String token,
    String? refreshToken,
  }) async {
    await _prefs.setString(AppConstants.sessionUserIdKey, userId);
    await _prefs.setString(AppConstants.sessionTokenKey, token);
    if (refreshToken != null) {
      await _prefs.setString(
        AppConstants.sessionRefreshTokenKey,
        refreshToken,
      );
    }
  }

  Future<void> clear() async {
    await _prefs.remove(AppConstants.sessionUserIdKey);
    await _prefs.remove(AppConstants.sessionTokenKey);
    await _prefs.remove(AppConstants.sessionRefreshTokenKey);
  }
}
