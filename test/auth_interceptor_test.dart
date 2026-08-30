// Unit tests for AuthInterceptor: 401 → refresh → retry, and session expiry.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chat_app/core/network/auth_interceptor.dart';
import 'package:chat_app/core/storage/session_store.dart';

/// Adapter that serves canned responses per request path.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._handler);

  final ResponseBody Function(RequestOptions) _handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, dynamic> body, [int status = 200]) =>
    ResponseBody(
      Stream.value(Uint8List.fromList(utf8.encode(jsonEncode(body)))),
      status,
      headers: {Headers.contentTypeHeader: ['application/json']},
    );

ResponseBody _unauthorized() => _json(
      {'code': 'AUTHENTICATION_ERROR', 'message': 'expired'},
      401,
    );

Future<SessionStore> _session({String token = 'old-access', String? refresh}) async {
  SharedPreferences.setMockInitialValues({});
  final session = SessionStore(await SharedPreferences.getInstance());
  await session.saveSession(
    userId: '1',
    token: token,
    refreshToken: refresh ?? 'refresh-token',
  );
  return session;
}

void main() {
  test('injects Authorization header from the session', () async {
    final session = await _session();
    final dio = Dio(
      BaseOptions(baseUrl: 'http://x', connectTimeout: const Duration(seconds: 5)),
    );
    final adapter = _ScriptedAdapter((o) => _json({'ok': true}));
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(AuthInterceptor(session, dio: dio));

    await dio.get('/api/chat/conversations');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer old-access');
  });

  test('401 triggers refresh once and retries the original request', () async {
    final session = await _session();
    var calls = 0;
    final dio = Dio(
      BaseOptions(baseUrl: 'http://x', connectTimeout: const Duration(seconds: 5)),
    );
    dio.httpClientAdapter = _ScriptedAdapter((options) {
      if (options.path.contains('/auth/refresh')) {
        return _json({
          'access_token': 'new-access',
          'refresh_token': 'new-refresh',
          'token_type': 'bearer',
        });
      }
      calls++;
      // First call to the protected endpoint → 401; retry → 200.
      if (calls == 1) return _unauthorized();
      return _json({'id': 1, 'username': 'u', 'email': 'e'});
    });
    dio.interceptors.add(AuthInterceptor(session, dio: dio));

    final res = await dio.get<Map<String, dynamic>>('/api/auth/me');
    expect(res.data?['id'], 1);
    // Session now has the new tokens.
    expect(session.token, 'new-access');
    expect(session.refreshToken, 'new-refresh');
  });

  test('refresh failure clears session and fires the expired callback',
      () async {
    final session = await _session();
    var expiredFired = false;
    final dio = Dio(
      BaseOptions(baseUrl: 'http://x', connectTimeout: const Duration(seconds: 5)),
    );
    dio.httpClientAdapter = _ScriptedAdapter((options) {
      if (options.path.contains('/auth/refresh')) return _unauthorized();
      return _unauthorized();
    });
    dio.interceptors.add(AuthInterceptor(session, dio: dio));
    SessionExpiredNotifier.onSessionExpired = () async {
      expiredFired = true;
    };

    await expectLater(
      dio.get('/api/chat/conversations'),
      throwsA(isA<DioException>()),
    );
    expect(expiredFired, isTrue);
    expect(session.token, isNull);
    expect(session.refreshToken, isNull);

    SessionExpiredNotifier.onSessionExpired = null;
  });

  test('does not refresh on the login endpoint', () async {
    final session = await _session();
    var calls = 0;
    final dio = Dio(
      BaseOptions(baseUrl: 'http://x', connectTimeout: const Duration(seconds: 5)),
    );
    dio.httpClientAdapter = _ScriptedAdapter((options) {
      calls++;
      return _unauthorized();
    });
    dio.interceptors.add(AuthInterceptor(session, dio: dio));

    await expectLater(
      dio.get('/api/auth/login'),
      throwsA(isA<DioException>()),
    );
    // Only the original request; no refresh was attempted.
    expect(calls, 1);
  });
}
