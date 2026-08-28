import 'package:dio/dio.dart';

import '../../../../config/environment.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/client_trace.dart';
import '../../../../core/storage/session_store.dart';
import '../../../../core/utils/api_base_url.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';
import 'auth_data_source.dart';

/// Remote auth backed by the production API (see ai-backend-v2 docs/api-spec.md).
///
/// Token lifecycle per spec:
/// - `access_token` valid 30 menit, `refresh_token` valid 60 menit.
/// - Single session: login/refresh baru membatalkan token lama (Redis).
/// - Endpoint login pakai `application/x-www-form-urlencoded`.
class AuthRemoteDataSource implements AuthDataSource {
  AuthRemoteDataSource(this._session, {Dio? dio, String? baseUrl})
      : _dio = dio ??
            (Dio(
              BaseOptions(
                connectTimeout: _timeout,
                receiveTimeout: _timeout,
                sendTimeout: _timeout,
              ),
            )..interceptors.add(ClientTraceInterceptor())),
        _baseUrl = baseUrl ?? _resolveBaseUrl();

  final SessionStore _session;
  final Dio _dio;
  final String _baseUrl;

  static const _timeout = Duration(seconds: 15);

  /// Picks the API base URL for the current runtime (Android emulator uses
  /// `10.0.2.2` to reach the host's loopback).
  static String _resolveBaseUrl() => resolveApiBaseUrl(AppEnvironment.apiBaseUrl);

  @override
  Future<User> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '$_baseUrl/api/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
        options: Options(contentType: Headers.jsonContentType),
      );
      // The backend register endpoint returns the user but no tokens.
      // Auto-login so the app has an active session after registration.
      return await login(username: username, password: password);
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Gagal mendaftar. Silakan coba lagi.');
    }
  }

  @override
  Future<User> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '$_baseUrl/api/auth/login',
        // Spec: login is form-urlencoded, not JSON.
        data: {'username': username, 'password': password},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      await _saveTokenPair(res.data!);
      // Fetch the user profile so the app has user info after login.
      return await _me();
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Gagal masuk. Silakan coba lagi.');
    }
  }

  @override
  Future<void> logout() async {
    final token = _session.token;
    if (token != null) {
      try {
        await _dio.post<void>(
          '$_baseUrl/api/auth/logout',
          options: Options(headers: _authHeaders(token)),
        );
      } on DioException {
        // Best-effort: clear the local session regardless.
      }
    }
    await _session.clear();
  }

  @override
  Future<User?> getCurrentUser() async {
    if (_session.token == null) return null;
    try {
      return await _me();
    } on SessionException {
      // Refresh failed / session revoked: clear and report unauthenticated.
      await _session.clear();
      return null;
    } on DioException {
      return null;
    } on AppException {
      // Network/other errors during restore shouldn't block the app; treat
      // as unauthenticated so the user can retry login.
      return null;
    }
  }

  /// Calls GET /me, auto-refreshing the access token if needed.
  Future<User> _me() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/api/auth/me',
        options: Options(headers: _authHeaders(_session.token!)),
      );
      return _userFromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && _session.refreshToken != null) {
        if (await _refresh()) {
          final res = await _dio.get<Map<String, dynamic>>(
            '$_baseUrl/api/auth/me',
            options: Options(headers: _authHeaders(_session.token!)),
          );
          return _userFromJson(res.data!);
        }
      }
      throw _mapError(e, fallback: 'Sesi berakhir. Silakan login ulang.');
    }
  }

  /// Rotates the token pair via /refresh. Returns true on success.
  Future<bool> _refresh() async {
    final refreshToken = _session.refreshToken;
    if (refreshToken == null) return false;
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '$_baseUrl/api/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(contentType: Headers.jsonContentType),
      );
      await _saveTokenPair(res.data!);
      return true;
    } on DioException {
      return false;
    }
  }

  Future<void> _saveTokenPair(Map<String, dynamic> data) async {
    final access = data['access_token'] as String;
    final refresh = data['refresh_token'] as String?;
    // We don't know the user id until /me; store tokens first.
    await _session.saveSession(
      userId: _session.userId ?? '',
      token: access,
      refreshToken: refresh,
    );
  }

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
      };

  User _userFromJson(Map<String, dynamic> json) {
    final model = UserModel.fromJson(json);
    // If we now know the real user id, persist it.
    if (model.id.isNotEmpty) {
      _session.saveSession(
        userId: model.id,
        token: _session.token ?? '',
        refreshToken: _session.refreshToken,
      );
    }
    return model.toEntity();
  }

  /// Maps backend errors (spec format `{code, message, details}`) to typed
  /// exceptions the UI understands.
  AppException _mapError(DioException e, {required String fallback}) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    String? code;
    String? message;
    if (body is Map) {
      code = body['code'] as String?;
      message = body['message'] as String?;
    }

    switch (status) {
      case 401:
        if (code == 'INVALID_CREDENTIALS') {
          return const AuthException('Username atau password salah.');
        }
        return const SessionException('Sesi berakhir. Silakan login ulang.');
      case 409:
        return const AuthException('Username atau email sudah terdaftar.');
      case 429:
        return const NetworkException(
          'Terlalu banyak permintaan. Coba lagi nanti.',
        );
      case 400:
        return AuthException(message ?? 'Data tidak valid.', code: code);
      default:
        return NetworkException(
          message ?? fallback,
          code: code,
        );
    }
  }
}
