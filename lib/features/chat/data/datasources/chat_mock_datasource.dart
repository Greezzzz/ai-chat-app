import 'dart:async';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/app_database.dart';
import '../../../../core/storage/session_store.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'chat_data_source.dart';

/// Mock chat backed by Hive with simulated streaming (PRD §25, §28).
///
/// Persists user messages and accumulates the streamed assistant response so
/// the conversation survives app restarts.
class MockChatDataSource implements ChatDataSource {
  MockChatDataSource(this._db, this._session, {this.chunkDelay = AppConstants.mockChunkDelay});

  final AppDatabase _db;
  final SessionStore _session;

  /// Delay between streamed chunks. Configurable for tests/UX tuning.
  final Duration chunkDelay;

  @override
  bool get persistsLocally => true;

  @override
  Future<List<Conversation>> getConversations() async {
    final userId = _currentUserId;
    final list = _db.conversations.values
        .map(ConversationModel.fromJson)
        .where((c) => c.userId == userId)
        .map((c) => c.toEntity())
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<Conversation?> getConversation(String id) async {
    final raw = _db.conversations.get(id);
    if (raw == null) return null;
    return ConversationModel.fromJson(raw).toEntity();
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final list = _db.messages.values
        .map(MessageModel.fromJson)
        .where((m) => m.conversationId == conversationId)
        .map((m) => m.toEntity())
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<Conversation> createConversation() async {
    final now = DateTime.now();
    final id = 'conv_${now.millisecondsSinceEpoch}';
    final conversation = Conversation(
      id: id,
      userId: _currentUserId,
      title: 'New Chat',
      createdAt: now,
      updatedAt: now,
    );
    await _db.conversations.put(id, ConversationModel.fromEntity(conversation).toJson());
    return conversation;
  }

  @override
  Future<void> updateConversation(Conversation conversation) async {
    await _db.conversations.put(
      conversation.id,
      ConversationModel.fromEntity(conversation).toJson(),
    );
  }

  @override
  Stream<String> streamChat({
    required String conversationId,
    required String message,
  }) {
    return _simulateStream(message);
  }

  Stream<String> _simulateStream(String message) async* {
    // Brief "thinking" pause before the first chunk (configurable).
    await Future<void>.delayed(AppConstants.mockThinkingDelay);

    final response = _buildResponse(message);
    // Split the response into word-sized chunks so the UI updates naturally.
    final words = response.split(' ');
    for (final word in words) {
      await Future<void>.delayed(chunkDelay);
      yield word + (words.last == word ? '' : ' ');
    }
  }

  /// Picks a canned response based on the user's message so the mock feels
  /// interactive rather than completely static.
  String _buildResponse(String message) {
    final text = message.toLowerCase();

    if (text.contains('flutter')) {
      return 'Flutter adalah framework UI open-source dari Google yang memungkinkan '
          'membangun aplikasi untuk Android, iOS, web, dan desktop dari satu '
          'codebase menggunakan bahasa Dart. Keunggulannya adalah performa '
          'tinggi, hot reload, dan widget yang konsisten di semua platform.';
    }
    if (text.contains('api') || text.contains('rest')) {
      return 'REST API adalah gaya arsitektur untuk membangun web service '
          'menggunakan HTTP. Prinsip dasarnya: resource diidentifikasi dengan '
          'URL, method HTTP (GET, POST, PUT, DELETE) menentukan operasi, dan '
          'response biasanya dalam format JSON.';
    }
    if (text.contains('hai') || text.contains('halo') || text.contains('hello')) {
      return 'Halo! Senang bertemu denganmu. Ada yang bisa saya bantu hari ini? '
          'Saya bisa membantu menjelaskan konsep, menulis kode, atau menjawab '
          'pertanyaanmu.';
    }
    if (text.contains('terima kasih') || text.contains('makasih')) {
      return 'Sama-sama! Senang bisa membantu. Jika ada pertanyaan lain, '
          'jangan ragu untuk bertanya lagi ya.';
    }
    return 'Pertanyaan yang bagus! Saya adalah AI assistant dalam mode demo. '
        'Untuk pertanyaan "$message", saya menyarankan untuk mencoba eksplorasi '
        'lebih lanjut. Fitur ini akan terhubung ke AI sungguhan pada production '
        'melalui backend API.';
  }

  String get _currentUserId {
    // Read the session user id so each registered user gets isolated
    // conversations (mock data is per-user, not shared).
    return _session.userId ?? 'user_001';
  }
}
