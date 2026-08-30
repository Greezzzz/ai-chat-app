import 'package:dio/dio.dart';

import '../storage/session_store.dart';

/// Global hook fired when the session can't be refreshed (expired/revoked).
///
/// The app wires this to `AuthController.logout()` so the router bounces the
/// user to the login screen. Kept as a static callback so Dio interceptors
/// (which have no access to Riverpod) can trigger it.
typedef SessionExpiredCallback = Future<void> Function();

class SessionExpiredNotifier {
  SessionExpiredNotifier._();

  static SessionExpiredCallback? onSessionExpired;
}

/// Dio interceptor that:
/// - attaches `Authorization: Bearer <access_token>` to every request
/// - on 401, refreshes the token pair once (via POST /api/auth/refresh) and
///   retries the original request
/// - if the refresh fails, clears the session and fires [SessionExpiredNotifier]
///
/// A simple lock prevents concurrent refreshes while one is in flight.
class AuthInterceptor extends Interceptor {
  // ignore: prefer_initializing_formals — param name (dio) vs private field.
  AuthInterceptor(this._session, {required Dio dio}) : _dio = dio;

  final SessionStore _session;
  final Dio _dio;

  static const _excludedPaths = ['/api/auth/login', '/api/auth/refresh'];

  bool _refreshing = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _session.token;
    if (token != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final isAuthEndpoint =
        _excludedPaths.any((p) => request.path.contains(p));
    final is401 = err.response?.statusCode == 401;

    // Only handle 401s on protected endpoints.
    if (!is401 || isAuthEndpoint) {
      handler.next(err);
      return;
    }

    try {
      final newToken = await _refreshToken();
      if (newToken == null) {
        await _sessionExpired();
        handler.next(err);
        return;
      }
      // Retry the original request with the fresh token.
      request.headers['Authorization'] = 'Bearer $newToken';
      final response = await _retry(request);
      handler.resolve(response);
    } catch (e) {
      handler.next(err);
    }
  }

  Future<String?> _refreshToken() async {
    // Serialize concurrent 401s: wait for the in-flight refresh.
    if (_refreshing) {
      while (_refreshing) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      return _session.token;
    }

    final refreshToken = _session.refreshToken;
    if (refreshToken == null) return null;

    _refreshing = true;
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(contentType: Headers.jsonContentType),
      );
      final access = res.data?['access_token'] as String?;
      final refresh = res.data?['refresh_token'] as String?;
      if (access == null) return null;
      await _session.saveSession(
        userId: _session.userId ?? '',
        token: access,
        refreshToken: refresh,
      );
      return access;
    } on DioException {
      return null;
    } finally {
      _refreshing = false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions request) {
    // Reuse the same dio (adapter + interceptors). The excluded-path guard
    // prevents this from recursing into refresh again.
    return _dio.fetch(request);
  }

  Future<void> _sessionExpired() async {
    await _session.clear();
    await SessionExpiredNotifier.onSessionExpired?.call();
  }
}
