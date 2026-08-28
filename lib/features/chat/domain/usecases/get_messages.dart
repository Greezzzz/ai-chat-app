import '../entities/message.dart';
import '../repositories/chat_repository.dart';

/// Loads the messages of a conversation.
class GetMessages {
  const GetMessages(this._repository);

  final ChatRepository _repository;

  Future<List<Message>> call(String conversationId) {
    return _repository.getMessages(conversationId);
  }
}
