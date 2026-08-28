import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

/// Creates a new empty conversation.
class CreateConversation {
  const CreateConversation(this._repository);

  final ChatRepository _repository;

  Future<Conversation> call() => _repository.createConversation();
}
