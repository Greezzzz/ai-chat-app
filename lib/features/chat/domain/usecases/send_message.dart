import '../repositories/chat_repository.dart';

/// Sends a message and returns the assistant response as a chunk stream.
class SendMessage {
  const SendMessage(this._repository);

  final ChatRepository _repository;

  Stream<String> call({required String? conversationId, required String message}) {
    return _repository.sendMessage(
      conversationId: conversationId,
      message: message,
    );
  }
}
