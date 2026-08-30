import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../config/environment.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../../../core/network/client_trace.dart';
import '../../../../core/storage/session_store.dart';
import '../../../../core/utils/api_base_url.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../models/conversation_model.dart';
import 'chat_data_source.dart';

/// Remote chat backed by the ai-backend-v2 API (docs/api-spec.md).
///
/// Design notes matching the backend contract:
/// - `POST /api/chat/stream` is SSE: `data: {"conversation_id": N}` first,
///   then `data: {"delta": "..."}`, `data: {"error": "..."}`, `data: [DONE]`.
/// - When `conversation_id` is null the backend creates the conversation and
///   reports its id in the first SSE event.
/// - Backend conversation/user ids are integers; the app model uses strings.
class ChatRemoteDataSource implements ChatDataSource {
  ChatRemoteDataSource(
    this._session, {
    Dio? dio,
    String? baseUrl,
    Duration? idleTimeout,
  })  : _idleTimeout = idleTimeout ?? _streamIdleTimeout,
        _dio = dio ??
            (Dio(
              BaseOptions(
                connectTimeout: _timeout,
                receiveTimeout: _timeout,
                sendTimeout: _timeout,
              ),
            )..interceptors.add(ClientTraceInterceptor())),
        _baseUrl = baseUrl ?? _resolveBaseUrl() {
    // The auth interceptor needs the same dio instance to retry requests.
    _dio.interceptors.add(AuthInterceptor(_session, dio: _dio));
  }

  final SessionStore _session;
  final Dio _dio;
  final String _baseUrl;
  final Duration _idleTimeout;

  /// Conversation id received from the first SSE event of the last stream
  /// (`data: {"conversation_id": N}`). Set when the backend created a new
  /// conversation for a first message; null otherwise.
  String? _lastConversationId;

  @override
  String? get lastConversationId => _lastConversationId;

  static const _timeout = Duration(seconds: 20);
  static const _streamTimeout = Duration(seconds: 60);

  /// Max silence between SSE events. If the server/LLM stalls longer than
  /// this (e.g. the provider takes too long to respond), the stream is
  /// aborted so the UI doesn't hang on a cursor forever.
  static const _streamIdleTimeout = Duration(seconds: 30);

  @override
  bool get persistsLocally => false;

  /// Picks the API base URL for the current runtime (Android emulator uses
  /// `10.0.2.2` to reach the host's loopback).
  static String _resolveBaseUrl() => resolveApiBaseUrl(AppEnvironment.apiBaseUrl);

  @override
  Future<List<Conversation>> getConversations() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/api/chat/conversations',
        options: Options(headers: _authHeaders()),
      );
      final list = res.data?['conversations'] as List<dynamic>? ?? const [];
      final conversations = list.map((e) {
        final json = Map<String, dynamic>.from(e as Map);
        return ConversationModel.fromJson(json).toEntity();
      }).toList();
      return conversations;
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Gagal memuat percakapan.');
    }
  }

  @override
  Future<Conversation?> getConversation(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/api/chat/conversations/$id',
        options: Options(headers: _authHeaders()),
      );
      return ConversationModel.fromJson(res.data!).toEntity();
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Gagal memuat percakapan.');
    }
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/api/chat/conversations/$conversationId',
        options: Options(headers: _authHeaders()),
      );
      final list = res.data?['messages'] as List<dynamic>? ?? const [];
      final messages = list.map((e) {
        final json = Map<String, dynamic>.from(e as Map);
        return Message(
          id: json['id'].toString(),
          conversationId: json['conversation_id'].toString(),
          role: json['role'] == 'assistant'
              ? MessageRole.assistant
              : MessageRole.user,
          content: json['content'] as String? ?? '',
          createdAt: DateTime.parse(json['created_at'] as String),
        );
      }).toList();
      return messages;
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Gagal memuat pesan.');
    }
  }

  @override
  Future<Conversation> createConversation() async {
    // The backend creates conversations implicitly on the first message sent
    // to /api/chat/stream (or /api/chat/conversations). We don't pre-create.
    throw const NetworkException(
      'Conversation dibuat otomatis saat pesan pertama dikirim.',
    );
  }

  @override
  Future<void> updateConversation(Conversation conversation) async {
    // The backend derives titles from the first message; nothing to update.
  }

  @override
  Future<String> uploadDocument({
    required String title,
    required String content,
  }) async {
    final token = _session.token;
    if (token == null) {
      throw const SessionException('Sesi berakhir. Silakan login ulang.');
    }
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '$_baseUrl/api/rag/documents',
        data: {'title': title, 'content': content},
        options: Options(
          headers: _authHeaders(token),
          contentType: Headers.jsonContentType,
        ),
      );
      return (res.data?['document_id'] ?? res.data?['id']).toString();
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Gagal mengunggah dokumen.');
    }
  }

  @override
  Stream<String> streamChat({
    required String conversationId,
    required String message,
    String? documentId,
  }) async* {
    final token = _session.token;
    if (token == null) {
      throw const SessionException('Sesi berakhir. Silakan login ulang.');
    }

    // Reset any id from a previous stream.
    _lastConversationId = null;

    try {
      final res = await _dio.post<ResponseBody>(
        '$_baseUrl/api/chat/stream',
        data: {
          'message': message,
          'conversation_id': int.tryParse(conversationId),
          // document_id only binds on a brand-new conversation (first
          // message); backend ignores it for existing ones.
          if (documentId != null) 'document_id': int.tryParse(documentId),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
          receiveTimeout: _streamTimeout,
        ),
      );
      final stream = res.data!.stream;
      final lines = utf8.decoder
          .bind(stream)
          .transform(const LineSplitter());

      // Abort the stream if the server stays silent longer than the idle
      // timeout (provider thinking, stalled connection, etc.). Without this,
      // a stalled SSE stream never completes and the UI hangs on the cursor.
      await for (final line in lines.timeout(_idleTimeout)) {
        if (!line.startsWith('data:')) continue;
        final payload = line.substring(5).trim();
        if (payload.isEmpty) continue;
        if (payload == '[DONE]') break;

        final decoded = jsonDecode(payload);
        if (decoded is Map) {
          // First event: the backend tells us the (new) conversation id.
          final convId = decoded['conversation_id'];
          if (convId != null) {
            _lastConversationId = convId.toString();
          }
          final delta = decoded['delta'];
          if (delta is String) {
            yield delta;
            continue;
          }
          final error = decoded['error'];
          if (error is String) {
            throw NetworkException(error, code: 'STREAM_ERROR');
          }
        }
      }
    } on TimeoutException {
      throw const NetworkException(
        'Respons AI terlalu lama. Silakan coba lagi.',
      );
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Gagal terhubung ke server.');
    }
  }

  Map<String, String> _authHeaders([String? token]) => {
        'Authorization': 'Bearer ${token ?? _session.token ?? ''}',
      };

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
        return const SessionException('Sesi berakhir. Silakan login ulang.');
      case 404:
        return NetworkException(
          message ?? 'Percakapan tidak ditemukan.',
          code: code,
        );
      case 429:
        return const NetworkException(
          'Terlalu banyak permintaan. Coba lagi nanti.',
        );
      case 400:
        return NetworkException(message ?? 'Data tidak valid.', code: code);
      default:
        return NetworkException(
          message ?? fallback,
          code: code,
        );
    }
  }
}
