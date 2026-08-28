import 'dart:math';

import 'package:dio/dio.dart';

/// Generates a client-side trace id for the `X-Trace-Id` header.
///
/// The backend's `TraceMiddleware` reads `X-Trace-id` from incoming requests
/// and uses it as the trace id in its logs (echoed back in the response).
/// Sending this header lets the backend correlate a request chain from this
/// app end-to-end.
///
/// Format: `mobile-chat-<uuid4>-<timestampNanos>`
/// - `uuid4`: random v4 UUID (no extra dependency, `Random.secure()`).
/// - `timestampNanos`: `microsecondsSinceEpoch * 1000` (Dart's finest clock
///   is microseconds; the nanos figure is an approximation).
///
/// The combination of a random UUID and a timestamp makes the id unique per
/// request while remaining sortable, so backend logs can correlate every
/// request from this app.
class ClientTraceId {
  const ClientTraceId._();

  static final Random _random = Random.secure();

  static String generate() {
    final nanos = DateTime.now().microsecondsSinceEpoch * 1000;
    return 'mobile-chat-${_uuid4()}-$nanos';
  }

  /// Random UUID v4 (16 bytes, version 4, RFC 4122 variant).
  static String _uuid4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx
    final hex =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

/// Adds an `X-Trace-Id` header to every outgoing request so the backend can
/// correlate a request chain in its logs.
class ClientTraceInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Trace-Id'] = ClientTraceId.generate();
    handler.next(options);
  }
}
