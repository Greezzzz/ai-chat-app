import '../entities/conversation.dart';
import '../entities/message.dart';

/// Contract for conversation and message operations.
///
/// Implementations swap between mock (local storage) and remote (API)
/// without touching the UI.
abstract interface class ChatRepository {
  /// Lists all conversations of the current user, newest first.
  Future<List<Conversation>> getConversations();

  /// Returns a single conversation or null when not found.
  Future<Conversation?> getConversation(String id);

  /// Loads messages of a conversation, oldest first.
  Future<List<Message>> getMessages(String conversationId);

  /// Creates a conversation (empty until the first message is sent).
  Future<Conversation> createConversation();

  /// Updates a conversation (title / timestamps).
  Future<void> updateConversation(Conversation conversation);

  /// Sends a user message and streams the assistant response chunk by chunk.
  ///
  /// Creates the conversation on first message if [conversationId] is null,
  /// persisting the user message and each streamed chunk.
  Stream<String> sendMessage({
    required String? conversationId,
    required String message,
  });
}
