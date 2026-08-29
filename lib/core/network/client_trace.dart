import 'dart:math';

import 'package:dio/dio.dart';

/// Client-side W3C trace context for end-to-end correlation with the backend.
///
/// The backend (ai-backend-v2) uses OpenTelemetry. Per its api-spec:
/// - Response carries `X-Trace-Id` (server/OTel trace id, searchable in
///   Jaeger) and `X-Client-Trace-Id` (echo of the client's `X-Trace-Id`).
/// - Sending a W3C `traceparent` header makes the server adopt our trace id,
///   so the id we generate is the one to look up in Jaeger.
///
/// We send both:
/// - `traceparent: 00-<traceId>-<spanId>-01` (W3C, sampled)
/// - `X-Trace-Id: <traceId>` (same id, recorded as `client.trace_id`)
class ClientTraceId {
  const ClientTraceId._();

  static final Random _random = Random.secure();

  /// Generates a 32-hex-char W3C trace id (16 random bytes).
  static String generateTraceId() => _randomHex(16);

  /// Generates an 8-byte (16 hex) span id for the client-side span.
  static String generateSpanId() => _randomHex(8);

  static String _randomHex(int bytes) {
    final buffer = StringBuffer();
    for (var i = 0; i < bytes; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}

/// Adds W3C `traceparent` + `X-Trace-Id` headers to every outgoing request.
class ClientTraceInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final traceId = ClientTraceId.generateTraceId();
    final spanId = ClientTraceId.generateSpanId();
    options.headers['traceparent'] = '00-$traceId-$spanId-01';
    options.headers['X-Trace-Id'] = traceId;
    handler.next(options);
  }
}
