// Unit tests for ChatRemoteDataSource: SSE parsing and API mapping.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chat_app/core/errors/app_exception.dart';
import 'package:chat_app/core/storage/session_store.dart';
import 'package:chat_app/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:chat_app/features/chat/domain/entities/message.dart';

/// Fake dio adapter that serves a canned SSE body for POST /api/chat/stream
/// and canned JSON for the other endpoints.
class _FakeSseAdapter implements HttpClientAdapter {
  _FakeSseAdapter(this.sseBody);

  final String sseBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/api/chat/stream')) {
      return _chunked(utf8.encode(sseBody), 'text/event-stream');
    }
    if (options.method == 'GET' &&
        options.path.endsWith('/api/chat/conversations/12')) {
      final body = jsonEncode({
        'id': 12,
        'user_id': 1,
        'title': 'Halo, apa itu RAG?',
        'created_at': '2026-08-27T10:00:00Z',
        'messages': [
          {
            'id': 100,
            'conversation_id': 12,
            'role': 'user',
            'content': 'Halo, apa itu RAG?',
            'created_at': '2026-08-27T10:00:01Z',
          },
          {
            'id': 101,
            'conversation_id': 12,
            'role': 'assistant',
            'content': 'RAG adalah Retrieval-Augmented Generation...',
            'created_at': '2026-08-27T10:00:02Z',
          },
        ],
      });
      return _chunked(utf8.encode(body), 'application/json');
    }
    if (options.path.endsWith('/api/chat/conversations') &&
        options.method == 'GET') {
      final body = jsonEncode({
        'conversations': [
          {
            'id': 12,
            'title': 'Halo, apa itu RAG?',
            'created_at': '2026-08-27T10:00:00Z',
            'last_message': 'RAG adalah...',
          },
          {
            'id': 11,
            'title': 'Pesan pertama',
            'created_at': '2026-08-26T09:00:00Z',
            'last_message': null,
          },
        ],
      });
      return _chunked(utf8.encode(body), 'application/json');
    }
    return _chunked(utf8.encode('{"status":"ok"}'), 'application/json');
  }

  /// Streams the body in small chunks (as a real network would) so the
  /// client-side LineSplitter/decoder path is exercised.
  ResponseBody _chunked(List<int> bytes, String contentType) {
    final controller = StreamController<Uint8List>();
    var i = 0;
    Timer.periodic(const Duration(milliseconds: 1), (t) {
      if (i < bytes.length) {
        final end = (i + 8 > bytes.length) ? bytes.length : i + 8;
        controller.add(Uint8List.fromList(bytes.sublist(i, end)));
        i = end;
      } else {
        t.cancel();
        controller.close();
      }
    });
    return ResponseBody(controller.stream, 200, headers: {
      Headers.contentTypeHeader: [contentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Future<SessionStore> _session() async {
  SharedPreferences.setMockInitialValues({});
  final session = SessionStore(await SharedPreferences.getInstance());
  await session.saveSession(userId: '1', token: 'jwt-token');
  return session;
}

void main() {
  test('streams SSE deltas and stops at [DONE]', () async {
    final session = await _session();
    final dio = Dio()..httpClientAdapter = _FakeSseAdapter(
      'data: {"delta": "Halo, "}\n\n'
      'data: {"delta": "dunia"}\n\n'
      'data: {"delta": "!"}\n\n'
      'data: [DONE]\n\n',
    );

    final ds = ChatRemoteDataSource(session, dio: dio);
    final chunks = <String>[];
    await for (final c in ds.streamChat(conversationId: '12', message: 'halo')) {
      chunks.add(c);
    }
    expect(chunks.join(), 'Halo, dunia!');
  });

  test('surfaces a mid-stream error event as NetworkException', () async {
    final session = await _session();
    final dio = Dio()..httpClientAdapter = _FakeSseAdapter(
      'data: {"delta": "sebagian"}\n\n'
      'data: {"error": "provider down"}\n\n',
    );

    final ds = ChatRemoteDataSource(session, dio: dio);
    await expectLater(
      ds.streamChat(conversationId: '12', message: 'halo').toList(),
      throwsA(isA<NetworkException>()),
    );
  });

  test('requires a session token before streaming', () async {
    SharedPreferences.setMockInitialValues({});
    final session = SessionStore(await SharedPreferences.getInstance());
    final dio = Dio()..httpClientAdapter = _FakeSseAdapter('data: [DONE]\n\n');

    final ds = ChatRemoteDataSource(session, dio: dio);
    await expectLater(
      ds.streamChat(conversationId: '12', message: 'halo').toList(),
      throwsA(isA<SessionException>()),
    );
  });

  test('maps the conversation list response (int ids → string)', () async {
    final session = await _session();
    final dio = Dio()..httpClientAdapter = _FakeSseAdapter('data: [DONE]\n\n');

    final ds = ChatRemoteDataSource(session, dio: dio);
    final convs = await ds.getConversations();
    expect(convs.length, 2);
    expect(convs.first.id, '12');
    expect(convs.first.title, 'Halo, apa itu RAG?');
    expect(convs.first.createdAt.isUtc, isTrue);
  });

  test('maps message history from conversation detail', () async {
    final session = await _session();
    final dio = Dio()..httpClientAdapter = _FakeSseAdapter('data: [DONE]\n\n');

    final ds = ChatRemoteDataSource(session, dio: dio);
    final messages = await ds.getMessages('12');
    expect(messages.length, 2);
    expect(messages.first.role, MessageRole.user);
    expect(messages.first.content, 'Halo, apa itu RAG?');
    expect(messages.last.role, MessageRole.assistant);
    expect(messages.last.content, 'RAG adalah Retrieval-Augmented Generation...');
    expect(messages.first.conversationId, '12');
  });

  test('does not persist locally', () async {
    final session = await _session();
    final dio = Dio()..httpClientAdapter = _FakeSseAdapter('data: [DONE]\n\n');
    final ds = ChatRemoteDataSource(session, dio: dio);
    expect(ds.persistsLocally, isFalse);
  });

  test('uploads a document and returns its id', () async {
    final session = await _session();
    final dio = Dio()..httpClientAdapter = _CaptureAdapter(
      (options) => ResponseBody(
        Stream.value(Uint8List.fromList(
          utf8.encode('{"document_id": 7}'),
        )),
        200,
        headers: {Headers.contentTypeHeader: ['application/json']},
      ),
      onRequest: (options) {},
    );

    final ds = ChatRemoteDataSource(session, dio: dio);
    final id = await ds.uploadDocument(title: 'tentang-ceo', content: 'Grezz...');
    expect(id, '7');
  });

  test('sends document_id in the stream body for a new chat', () async {
    final session = await _session();
    Map<String, dynamic>? lastBody;
    final dio = Dio()..httpClientAdapter = _CaptureAdapter(
      (options) => ResponseBody(
        Stream.value(Uint8List.fromList(
          utf8.encode('data: {"delta": "hai"}\n\ndata: [DONE]\n\n'),
        )),
        200,
        headers: {Headers.contentTypeHeader: ['text/event-stream']},
      ),
      onRequest: (options) {
        if (options.path.endsWith('/api/chat/stream')) {
          lastBody = options.data as Map<String, dynamic>;
        }
      },
    );

    final ds = ChatRemoteDataSource(session, dio: dio);
    await ds.streamChat(
      conversationId: '',
      message: 'halo',
      documentId: '7',
    ).toList();

    expect(lastBody, isNotNull);
    expect(lastBody!['conversation_id'], isNull);
    expect(lastBody!['document_id'], 7);
  });
}

/// Adapter with a per-request handler so tests can inspect request options
/// and return a custom response.
class _CaptureAdapter implements HttpClientAdapter {
  _CaptureAdapter(this._respond, {required this.onRequest});

  final ResponseBody Function(RequestOptions) _respond;
  final void Function(RequestOptions) onRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onRequest(options);
    return _respond(options);
  }

  @override
  void close({bool force = false}) {}
}
