// Unit tests for the client trace id generator + interceptor (W3C context).

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat_app/core/network/client_trace.dart';

void main() {
  test('generates a 32-hex W3C trace id', () {
    final id = ClientTraceId.generateTraceId();
    expect(id.length, 32);
    expect(id, matches(RegExp(r'^[0-9a-f]{32}$')));
  });

  test('generates a 16-hex span id', () {
    final id = ClientTraceId.generateSpanId();
    expect(id.length, 16);
    expect(id, matches(RegExp(r'^[0-9a-f]{16}$')));
  });

  test('generates unique ids', () {
    final traces = {
      for (var i = 0; i < 1000; i++) ClientTraceId.generateTraceId()
    };
    final spans = {
      for (var i = 0; i < 1000; i++) ClientTraceId.generateSpanId()
    };
    expect(traces.length, 1000);
    expect(spans.length, 1000);
  });

  test('interceptor sends traceparent + X-Trace-Id with the same trace id',
      () async {
    final capturedHeaders = <String, dynamic>{};
    final dio = Dio()..httpClientAdapter = _CaptureAdapter(capturedHeaders);
    dio.interceptors.add(ClientTraceInterceptor());

    await dio.get('http://localhost:8000/health');

    final traceparent = capturedHeaders['traceparent'] as String;
    final xTraceId = capturedHeaders['X-Trace-Id'] as String;
    expect(traceparent, startsWith('00-'));
    expect(traceparent, endsWith('-01'));
    // 00-<32hex>-<16hex>-01
    expect(traceparent.length, 2 + 1 + 32 + 1 + 16 + 1 + 2);
    expect(xTraceId, traceparent.substring(3, 35));
    expect(xTraceId.length, 32);
  });
}

/// Adapter that captures request headers without doing real I/O.
class _CaptureAdapter implements HttpClientAdapter {
  _CaptureAdapter(this.capturedHeaders);

  final Map<String, dynamic> capturedHeaders;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    capturedHeaders
      ..clear()
      ..addAll(options.headers);
    return ResponseBody(
      Stream.value(Uint8List.fromList(utf8.encode('{"status":"ok"}'))),
      200,
      headers: {Headers.contentTypeHeader: ['application/json']},
    );
  }

  @override
  void close({bool force = false}) {}
}
