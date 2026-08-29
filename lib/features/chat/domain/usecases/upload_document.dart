import '../repositories/chat_repository.dart';

/// Uploads a RAG context document. Returns the new document id.
class UploadDocument {
  const UploadDocument(this._repository);

  final ChatRepository _repository;

  Future<String> call({required String title, required String content}) {
    return _repository.uploadDocument(title: title, content: content);
  }
}
