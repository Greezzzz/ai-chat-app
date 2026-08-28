import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

/// Lists the current user's conversations.
class GetConversations {
  const GetConversations(this._repository);

  final ChatRepository _repository;

  Future<List<Conversation>> call() => _repository.getConversations();
}
