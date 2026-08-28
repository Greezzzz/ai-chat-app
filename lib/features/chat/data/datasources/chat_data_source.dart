import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

/// Data source contract for chat.
abstract interface class ChatDataSource {
  /// Whether this data source persists conversations/messages locally (Hive).
  ///
  /// Mock mode stores everything in Hive; the remote API owns persistence
  /// server-side, so the repository skips local writes.
  bool get persistsLocally;

  Future<List<Conversation>> getConversations();

  Future<Conversation?> getConversation(String id);

  Future<List<Message>> getMessages(String conversationId);

  Future<Conversation> createConversation();

  Future<void> updateConversation(Conversation conversation);

  /// Streams the assistant response for [message]. The implementation decides
  /// whether chunks come from local mock, SSE, WebSocket, etc.
  Stream<String> streamChat({
    required String conversationId,
    required String message,
  });
}
